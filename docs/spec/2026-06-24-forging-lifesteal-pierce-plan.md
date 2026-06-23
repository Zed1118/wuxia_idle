# 开锋吸血/破甲接通战斗 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让开锋槽的吸血(lifesteal)/破甲(pierce)词条在战斗中真正生效（破甲穿透防御率、吸血命中回血），补全 GDD §6.5 开锋 build 深度。

**Architecture:** 词条在 `BattleCharacter.fromCharacter` 烘焙成派生标量字段（BattleCharacter 不持有装备列表）→ 破甲经 `calculateResolved` 新参数减防御率 + 算吸血量进 `AttackResult.lifestealHeal` → `default_ground_strategy` 攻击 loop 累积回血、写回攻方 currentHp → 战报标记走 `appliedEffects`(破甲) + `lifestealHeal`(吸血+N)。数值沿用 numbers.yaml 现配不改，新参数默认 0 保零回归。

**Tech Stack:** Dart / Flutter / Riverpod / Isar；测试 `flutter test`（`DEVELOPER_DIR=/Library/Developer/CommandLineTools`）。

**Spec:** `docs/spec/2026-06-24-forging-lifesteal-pierce-design.md`（接入点据测绘细化：lifesteal 接 `default_ground_strategy._resolveAction` 非 spec 写的 battle_resolution；词条烘焙进 BattleCharacter 字段非每攻击重算）。

---

## 文件结构

| 文件 | 职责 | 改动 |
|---|---|---|
| `lib/features/battle/domain/derived_stats.dart` | 跨全装备开锋词条聚合 | +1 静态函数 |
| `lib/features/battle/domain/battle_state.dart` | BattleCharacter 烘焙 pierce/lifesteal 派生字段 | +2 字段/构造/copyWith/fromCharacter |
| `lib/features/battle/domain/damage_calculator.dart` | 破甲减防 + 吸血量 + 破甲标记 | +2 参数/AttackResult +1 字段 |
| `lib/features/battle/domain/strategy/default_ground_strategy.dart` | 破甲传参 + 吸血累积回血 | 调用块 + loop + actorAfter |
| `lib/features/battle/domain/battle_log.dart` | 吸血 +N 战报 | formatAction +1 分支 |
| `lib/features/battle/domain/enum_localizations.dart` | 破甲标记显示名 | switch +1 case |
| `test/balance/full_build_damage_redline_test.dart` | 满破甲 build 不进百万 | +1 探针 |

---

### Task 1: derived_stats 跨装备开锋词条聚合函数

**Files:**
- Modify: `lib/features/battle/domain/derived_stats.dart`（`_forgingBonusPct` 后，约 :228）
- Test: `test/features/battle/domain/derived_stats_forging_aggregate_test.dart`（新建）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/battle/domain/derived_stats_forging_aggregate_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';

ForgingSlot _slot(ForgingSlotType type, int bonus, {bool unlocked = true, int idx = 1}) =>
    ForgingSlot()
      ..slotIndex = idx
      ..type = type
      ..unlocked = unlocked
      ..bonusValue = bonus;

Equipment _eq(List<ForgingSlot> slots) => Equipment.create(
      defId: 'weapon_test',
      tier: EquipmentTier.zhongQi,
      slot: EquipmentSlot.weapon,
      obtainedAt: DateTime(2026, 1, 1),
      obtainedFrom: 'test',
      forgingSlots: slots,
    );

void main() {
  group('forgingAggregatePct 跨全身装备求和', () {
    test('空装备列表 → 0', () {
      expect(CharacterDerivedStats.forgingAggregatePct([], ForgingSlotType.pierce), 0.0);
    });
    test('单件 pierce 15 → 0.15', () {
      final eqs = [_eq([_slot(ForgingSlotType.pierce, 15)])];
      expect(CharacterDerivedStats.forgingAggregatePct(eqs, ForgingSlotType.pierce), 0.15);
    });
    test('两件 pierce 15+20 → 0.35', () {
      final eqs = [
        _eq([_slot(ForgingSlotType.pierce, 15)]),
        _eq([_slot(ForgingSlotType.pierce, 20, idx: 2)]),
      ];
      expect(CharacterDerivedStats.forgingAggregatePct(eqs, ForgingSlotType.pierce), 0.35);
    });
    test('未解锁槽不计入', () {
      final eqs = [_eq([_slot(ForgingSlotType.pierce, 20, unlocked: false)])];
      expect(CharacterDerivedStats.forgingAggregatePct(eqs, ForgingSlotType.pierce), 0.0);
    });
    test('类型过滤:查 lifesteal 不计 pierce 槽', () {
      final eqs = [_eq([_slot(ForgingSlotType.pierce, 20), _slot(ForgingSlotType.lifesteal, 10, idx: 2)])];
      expect(CharacterDerivedStats.forgingAggregatePct(eqs, ForgingSlotType.lifesteal), 0.10);
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/battle/domain/derived_stats_forging_aggregate_test.dart`
Expected: FAIL（`forgingAggregatePct` 未定义）

- [ ] **Step 3: 实现**（`derived_stats.dart`，`_forgingBonusPct` 函数后追加）

```dart
  /// 跨**全身装备**累加指定 [type] 的开锋槽位 bonusValue（百分比小数，15→0.15）。
  /// 区别于单件 [_forgingBonusPct]：pierce/lifesteal 是攻方整体战斗属性
  /// （穿透/回血），非单件攻速加成，故全装备求和。仅 `unlocked` 槽计入。
  static double forgingAggregatePct(
      List<Equipment> equipped, ForgingSlotType type) {
    var sum = 0;
    for (final eq in equipped) {
      for (final s in eq.forgingSlots) {
        if (s.unlocked && s.type == type) sum += s.bonusValue;
      }
    }
    return sum / 100.0;
  }
```

- [ ] **Step 4: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/battle/domain/derived_stats_forging_aggregate_test.dart`
Expected: PASS（5 tests）

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/domain/derived_stats.dart test/features/battle/domain/derived_stats_forging_aggregate_test.dart
git commit -m "feat: 开锋词条跨装备聚合 forgingAggregatePct(A1 task1)"
```

---

### Task 2: BattleCharacter 烘焙 forgingPiercePct/forgingLifestealPct

**Files:**
- Modify: `lib/features/battle/domain/battle_state.dart`（class 字段 :127 区 / 构造器 :222 区 / copyWith :418 区 / fromCharacter :325-328 区 + 构造调用 :391 区）
- Test: `test/features/battle/domain/battle_character_forging_bake_test.dart`（新建）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/battle/domain/battle_character_forging_bake_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/forging_slot.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  Character mkChar() => Character.create(
        name: '测试',
        strength: 5, agility: 5, constitution: 5, fortune: 5,
        realmTier: RealmTier.jueDing, realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
      );

  Equipment mkWeapon(List<ForgingSlot> slots) => Equipment.create(
        defId: 'weapon_zhongqi_test', tier: EquipmentTier.zhongQi,
        slot: EquipmentSlot.weapon, obtainedAt: DateTime(2026, 1, 1),
        obtainedFrom: 'test', baseAttack: 500, forgingSlots: slots,
      );

  test('fromCharacter 烘焙 pierce/lifesteal 派生字段', () {
    final weapon = mkWeapon([
      ForgingSlot()..slotIndex = 1..type = ForgingSlotType.pierce..unlocked = true..bonusValue = 20,
      ForgingSlot()..slotIndex = 2..type = ForgingSlotType.lifesteal..unlocked = true..bonusValue = 15,
    ]);
    final bc = BattleCharacter.fromCharacter(
      character: mkChar(), equipped: [weapon],
      mainTechnique: null, numbers: GameRepository.instance.numbers,
      teamSide: 0, slotIndex: 0,
    );
    expect(bc.forgingPiercePct, 0.20);
    expect(bc.forgingLifestealPct, 0.15);
  });

  test('裸装 → 0', () {
    final bc = BattleCharacter.fromCharacter(
      character: mkChar(), equipped: const [],
      mainTechnique: null, numbers: GameRepository.instance.numbers,
      teamSide: 0, slotIndex: 0,
    );
    expect(bc.forgingPiercePct, 0.0);
    expect(bc.forgingLifestealPct, 0.0);
  });
}
```

> 注：`BattleCharacter.fromCharacter` 真实参数以 `battle_state.dart:269-298` 签名为准（`mainTechnique`/`founderBuffActive` 等）。若签名不同，照实补齐——核心断言是两个新字段烘焙值。

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/battle/domain/battle_character_forging_bake_test.dart`
Expected: FAIL（`forgingPiercePct` getter 不存在）

- [ ] **Step 3a: 加字段**（`battle_state.dart`，`totalEquipmentAttack` 字段 :127 附近）

```dart
  /// 开锋破甲穿透率（全身装备 pierce 槽求和，烘焙自 fromCharacter）。0=无破甲。
  final double forgingPiercePct;

  /// 开锋吸血率（全身装备 lifesteal 槽求和，烘焙自 fromCharacter）。0=无吸血。
  final double forgingLifestealPct;
```

- [ ] **Step 3b: 构造器加默认参数**（构造器 :216-256 区，与其他 `this.xxx = 1.0` 默认项并列）

```dart
    this.forgingPiercePct = 0.0,
    this.forgingLifestealPct = 0.0,
```

- [ ] **Step 3c: copyWith 加字段**（签名 :418 区加 2 参数 + 返回体 :459 区加 2 赋值）

签名加：
```dart
    double? forgingPiercePct,
    double? forgingLifestealPct,
```
返回体加：
```dart
      forgingPiercePct: forgingPiercePct ?? this.forgingPiercePct,
      forgingLifestealPct: forgingLifestealPct ?? this.forgingLifestealPct,
```

- [ ] **Step 3d: fromCharacter 烘焙**（`:325-328` totalEqAtk fold 后追加）

```dart
    final forgingPiercePct = CharacterDerivedStats.forgingAggregatePct(
        equipped, ForgingSlotType.pierce);
    final forgingLifestealPct = CharacterDerivedStats.forgingAggregatePct(
        equipped, ForgingSlotType.lifesteal);
```
并在 fromCharacter 末尾构造 BattleCharacter 调用（`:391` 区）加：
```dart
      forgingPiercePct: forgingPiercePct,
      forgingLifestealPct: forgingLifestealPct,
```

- [ ] **Step 4: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/battle/domain/battle_character_forging_bake_test.dart`
Expected: PASS（2 tests）

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/domain/battle_state.dart test/features/battle/domain/battle_character_forging_bake_test.dart
git commit -m "feat: BattleCharacter 烘焙开锋 pierce/lifesteal 派生字段(A1 task2)"
```

---

### Task 3: calculateResolved 破甲穿透 + 吸血量 + 破甲标记

**Files:**
- Modify: `lib/features/battle/domain/damage_calculator.dart`（calculateResolved 签名 + defMult :175 区 + effects :225 区 + AttackResult 构造 :245 区 / class 字段 :307 区 / dodged 工厂 :370 区）
- Test: `test/features/battle/domain/damage_calculator_forging_test.dart`（新建）

- [ ] **Step 1: 写失败测试**（仿 `damage_calculator_output_multiplier_test.dart` primitive 全参模式）

```dart
// test/features/battle/domain/damage_calculator_forging_test.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';

void main() {
  late dynamic n;
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
    n = GameRepository.instance.numbers;
  });

  const skill = SkillDef(
    id: 's_test', nameKey: 's', school: TechniqueSchool.gangMeng,
    type: SkillType.normalAttack, powerMultiplier: 500,
    internalForceCost: 0, cooldown: 0,
  );

  AttackResult call({double pierce = 0.0, double lifesteal = 0.0, bool crit = false}) =>
      DamageCalculator.calculateResolved(
        attackerInternalForce: 5000, attackerEquipmentAttack: 1000,
        attackerCultivationLayer: CultivationLayer.xiaoCheng,
        attackerSchool: TechniqueSchool.gangMeng,
        defenderSchool: TechniqueSchool.gangMeng,
        attackerRealmTier: RealmTier.jueDing, attackerRealmLayer: RealmLayer.qiMeng,
        defenderRealmTier: RealmTier.jueDing, defenderRealmLayer: RealmLayer.qiMeng,
        defenderDefenseRate: 0.30, defenderEvasionRate: 0.0,
        attackerCriticalRate: 0.0, attackPowerMultiplier: 1.0,
        skill: skill, n: n, rng: Random(1), forceCritical: crit,
        attackerPiercePct: pierce, attackerLifestealPct: lifesteal,
      );

  test('破甲绝对减:def0.30 pierce0.20 → 有效0.10(伤害高于无破甲)', () {
    final base = call();
    final pierced = call(pierce: 0.20);
    // 无破甲 defMult=0.70；破甲后 defMult=0.90 → 伤害 ×(0.90/0.70)
    expect(pierced.mainDamage, (base.mainDamage * 0.90 / 0.70).round());
  });

  test('破甲 clamp 0 下界:pierce > def → 防御率归零不为负', () {
    final full = call(pierce: 0.50); // 0.30-0.50 → clamp 0
    final noDef = call(pierce: 0.30); // 0.30-0.30 → 0
    expect(full.mainDamage, noDef.mainDamage);
  });

  test('默认 pierce=0 零回归:不传与显式 0 同值', () {
    expect(call().mainDamage, call(pierce: 0.0).mainDamage);
  });

  test('破甲标记进 appliedEffects', () {
    expect(call(pierce: 0.20).appliedEffects, contains('armor_pierce'));
    expect(call().appliedEffects, isNot(contains('armor_pierce')));
  });

  test('吸血量 = mainDamage × lifesteal(floor)', () {
    final r = call(lifesteal: 0.15);
    expect(r.lifestealHeal, (r.mainDamage * 0.15).floor());
  });

  test('lifesteal=0 → lifestealHeal 0', () {
    expect(call().lifestealHeal, 0);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/battle/domain/damage_calculator_forging_test.dart`
Expected: FAIL（`attackerPiercePct` 命名参数不存在 / `lifestealHeal` getter 不存在）

- [ ] **Step 3a: calculateResolved 加参数**（签名 named optional 区，与 `outputMultiplier = 1.0` 并列）

```dart
    double attackerPiercePct = 0.0,
    double attackerLifestealPct = 0.0,
```

- [ ] **Step 3b: 防御率项改**（`final defMult = 1.0 - defenderDefenseRate;` 那行，约 :175）

```dart
    // 破甲:开锋 pierce 绝对减防御率(穿透),clamp 0 下界不为负。招式级 piercesDefense
    // (布尔全穿透)独立路径不动。
    final effectiveDefRate = (defenderDefenseRate - attackerPiercePct).clamp(0.0, 1.0);
    final defMult = 1.0 - effectiveDefRate;
```

- [ ] **Step 3c: effects 段加破甲标记**（`if (extraEffect != null) effects.add(extraEffect);` 后，约 :226）

```dart
    // 破甲标记:实际削了防御(pierce>0 且 defenderDefenseRate>0)才标。
    if (attackerPiercePct > 0 && defenderDefenseRate > 0) {
      effects.add('armor_pierce');
    }
    // 吸血量:实际主伤害 × 吸血率(震伤不计入)。闪避走 dodged 工厂 heal=0。
    final lifestealHeal = (mainDamage * attackerLifestealPct).floor();
```

- [ ] **Step 3d: AttackResult class 加字段 + 构造 + dodged**

class 字段（`final int finalDamage;` 区，:307）：
```dart
  /// 本次攻击触发的开锋吸血回血量（mainDamage×lifesteal%，floor）。0=无吸血。
  final int lifestealHeal;
```
构造器（`required this.finalDamage,` 区）加 `this.lifestealHeal = 0,`（默认 0）。
calculateResolved 末尾 `return AttackResult(...)` 加 `lifestealHeal: lifestealHeal,`。
`AttackResult.dodged` 工厂保持不动（lifestealHeal 默认 0，dodged 不传即 0）。

- [ ] **Step 4: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/battle/domain/damage_calculator_forging_test.dart`
Expected: PASS（6 tests）

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/domain/damage_calculator.dart test/features/battle/domain/damage_calculator_forging_test.dart
git commit -m "feat: calculateResolved 破甲穿透+吸血量+破甲标记(A1 task3)"
```

---

### Task 4: default_ground_strategy 接通（破甲传参 + 吸血累积回血）

**Files:**
- Modify: `lib/features/battle/domain/strategy/default_ground_strategy.dart`（calculateResolved 调用 :827 / target loop :444-468 / actorAfter :479-488）
- Test: `test/features/battle/domain/forging_battle_integration_test.dart`（新建，走 ProviderContainer + notifier.advance，见 memory `feedback_battle_determinism_test_via_notifier`）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/battle/domain/forging_battle_integration_test.dart
// 验证:攻方带 lifesteal 装备 → 一次攻击后 currentHp 回升;
//      带 pierce → 对高防目标 finalDamage 高于无 pierce。
// 用 _calculateInBattle 不可见,改测公开行为:构造两 BattleCharacter,跑 default
// strategy 一拍,比对攻方 hp / 目标受伤。若 strategy 内部方法私有,退化为
// 经 BattleNotifier.advance 的确定性 e2e(seed 固定)。
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
// ... 按现有 battle e2e 测试(如 test/features/battle/*) 的 ProviderContainer +
//     永久 listener + notifier.advance 体例构造;断言:
//   1. 攻方装 lifesteal 词条,advance 若干拍后 currentHp 高于不装 lifesteal 的对照
//   2. 攻方装 pierce,对 defenseRate>0 的目标累计伤害高于不装 pierce 对照
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });
  // TODO(实现者): 照搬最接近的现有 battle integration 测试骨架,套两组对照 build。
  test('占位:接通后吸血回血 + 破甲增伤(照现有 battle e2e 骨架补全)', () {
    expect(GameRepository.isLoaded, isTrue);
  });
}
```

> 实现者：先在 `test/features/battle/` 下找最接近的确定性战斗测试（ProviderContainer + 永久 listener + `notifier.advance`），照其骨架写两组对照（lifesteal on/off、pierce on/off），断言 currentHp 回升 / 伤害提升。memory `feedback_battle_determinism_test_via_notifier`：经 notifier.advance 跑、种子场景须真有 rng 分歧。**勿用 strategy.tick 直测私有方法。**

- [ ] **Step 2: 跑测试确认失败/占位通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/battle/domain/forging_battle_integration_test.dart`
Expected: 占位 PASS；补全对照断言后先 FAIL（接通前吸血不回血）

- [ ] **Step 3a: calculateResolved 调用加 2 参数**（`:827` 调用块，`outputMultiplier:` 行附近）

```dart
      attackerPiercePct: attacker.forgingPiercePct,
      attackerLifestealPct: attacker.forgingLifestealPct,
```

- [ ] **Step 3b: target loop 累积吸血**（target loop `:444` 前声明 + loop 内累积）

loop 前（与 `actorFanzhen` 声明 :443 并列）：
```dart
    var lifestealTotal = 0;
```
loop 内（拿到 `result` 后，仿 `:465-467` 累积模式）：
```dart
      lifestealTotal += result.lifestealHeal;
```

- [ ] **Step 3c: actorAfter 写回回血**（`:479` `final actorAfter = preActor.copyWith(` 块加一行）

```dart
      currentHp: (preActor.currentHp + lifestealTotal).clamp(0, preActor.maxHp),
```

> 注：`actorAfter` 在 loop 外只构造一次，`lifestealTotal` 已累积全部命中（single=1 次 / AOE=N 次），自动统一。阵亡攻击者不进 `_resolveAction`（无行动），天然不回血。

- [ ] **Step 4: 跑测试确认通过 + 全量回归**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/battle/domain/forging_battle_integration_test.dart`
Expected: PASS
Run（全量回归，确认接通不破现有战斗测）: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/battle/`
Expected: 全 PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/domain/strategy/default_ground_strategy.dart test/features/battle/domain/forging_battle_integration_test.dart
git commit -m "feat: 战斗接通开锋破甲传参+吸血累积回血(A1 task4)"
```

---

### Task 5: 战报标记（破甲 + 吸血 +N）

**Files:**
- Modify: `lib/features/battle/domain/enum_localizations.dart`（`attackEffect` switch :92）
- Modify: `lib/features/battle/domain/battle_log.dart`（`formatAction` markers 段 :67-74）
- Test: `test/features/battle/domain/battle_log_forging_test.dart`（新建）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/battle/domain/battle_log_forging_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';

void main() {
  test('EnumL10n.attackEffect armor_pierce → 破甲', () {
    expect(EnumL10n.attackEffect('armor_pierce'), '破甲');
  });
  // 吸血 +N 战报:formatAction 读 attackResult.lifestealHeal 拼串。
  // 完整 formatAction 测试需构造 BattleAction+BattleState,实现者照
  // 现有 battle_log 测试骨架补「lifestealHeal>0 → 战报含 吸血 +N」断言。
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/battle/domain/battle_log_forging_test.dart`
Expected: FAIL（armor_pierce 返回原 key 'armor_pierce' 而非 '破甲'）

- [ ] **Step 3a: EnumL10n.attackEffect 加 case**（switch :92 内）

```dart
      'armor_pierce' => '破甲',
```

- [ ] **Step 3b: battle_log formatAction 加吸血标记**（markers 拼装 :74 `markerStr` 前，`r` 即 attackResult）

```dart
    if (r.lifestealHeal > 0) markers.add('吸血 +${r.lifestealHeal}');
```

- [ ] **Step 4: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/battle/domain/battle_log_forging_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/battle/domain/enum_localizations.dart lib/features/battle/domain/battle_log.dart test/features/battle/domain/battle_log_forging_test.dart
git commit -m "feat: 开锋破甲/吸血战报标记(A1 task5)"
```

---

### Task 6: 红线验证（满破甲 build 不进百万）

**Files:**
- Modify: `test/balance/full_build_damage_redline_test.dart`（加满破甲探针，仿现有 `:114-176` 满 build 探针）

- [ ] **Step 1: 加满破甲探针测试**（在现有满 build 测试 group 内追加）

```dart
  test('满破甲 build(Σpierce 0.60)对武圣 35% 防御 暴击仍不进百万', () {
    // 仿 measureMaxBuild,calculateResolved 传 attackerPiercePct: 0.60(3件×20),
    // defenderDefenseRate: 0.35(武圣),forceCritical: true。
    final r = DamageCalculator.calculateResolved(
      // ... 照本文件现有满 build 探针参数(满内力/满装备攻击/极境修炼/满熟练),
      //     仅加: attackerPiercePct: 0.60, defenderDefenseRate: 0.35, forceCritical: true,
      attackerPiercePct: 0.60,
    );
    expect(r.finalDamage, lessThan(1000000),
        reason: 'GDD/CLAUDE §5.4 软红线:满破甲极值 build 仍不进百万');
  });
```

> 实现者：照本文件 `measureMaxBuild`/`maxBuild`（:33-146）现有满 build 参数装配，只把 `attackerPiercePct: 0.60` 加入探针调用，断言 `< 1000000`。

- [ ] **Step 2: 跑测试确认通过**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/balance/full_build_damage_redline_test.dart`
Expected: PASS（满破甲探针 < 1000000）

- [ ] **Step 3: 全量回归 + analyze**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter analyze`
Expected: No issues found
Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test`
Expected: All tests passed（基线 2855+新增，0 回归）

- [ ] **Step 4: 提交**

```bash
git add test/balance/full_build_damage_redline_test.dart
git commit -m "test: 满破甲 build 红线探针不进百万(A1 task6)"
```

---

## 完成定义
- 6 task 全绿，analyze 0，全量 test 0 回归。
- 开锋吸血/破甲在战斗中生效（破甲减防增伤、吸血命中回血）、进战报；新参数默认 0 保未开锋装备零回归。
- 数值未改 numbers.yaml；红线（满破甲探针 + balance_simulator 常驻测）不进百万。
- 收尾更新 PROGRESS + audit A1 标 resolved。specialSkill 仍单列 backlog。
