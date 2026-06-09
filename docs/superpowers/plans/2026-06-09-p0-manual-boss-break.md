# P0 手动 Boss 战「破招」Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 stage_02_05 跑通「看青衫剑客蓄力 → 决定破不破招 → 可见回报」的最小手动战斗闭环,托管也能独立通关。

**Architecture:** 蓄力/破招/踉跄状态机全部落在 `DefaultGroundStrategy._resolveAction` + `BattleCharacter` 新增 4 字段(domain 层,strategy 写,表现层只读)。手动破招走现有 `pendingUltimates`(放宽 `requestUltimate` 接受关键技);托管经 `aiUsePolicy=saveForInterrupt` 保守破招。内力改为「每场预算」(进场=maxIf,战内不回)。

**Tech Stack:** Flutter / Dart / Riverpod / YAML(skills/stages/numbers)/ flutter_test。所有数值进 numbers.yaml + schema 校验;新机制带红线测试。

**红线(GDD/CLAUDE.md):** §5.4 数值红线不动;Dart 不硬编码中文(战斗日志走 `EnumL10n`,UI 文案走 `UiStrings`);不引 Flame;低境界不可用高阶技;不动 `data/narratives,lore,events`。

**spec:** `docs/spec/P0_手动Boss战破招_落地方案_2026-06-09.md`(v2,已吸收外部 review)。

---

## File Structure

修改:
- `lib/core/domain/enums.dart` — 新增 `enum AiUsePolicy { normal, saveForInterrupt, manualOnly }`(SkillType 旁)
- `lib/data/defs/skill_def.dart` — SkillDef +`canInterrupt` +`aiUsePolicy` + fromYaml
- `data/skills.yaml` — 标 1 个玩家破招技 `canInterrupt: true` + `aiUsePolicy: saveForInterrupt`
- `data/numbers.yaml` + `lib/data/numbers_config.dart` — `combat.boss_charge` 段 + `BossChargeConfig`
- `lib/features/battle/domain/battle_state.dart` — BattleCharacter +4 字段(chargeSkillId/chargingSkill/chargeTicksRemaining/staggerTicksRemaining)+ 构造/copyWith;`fromCharacter` 进场内力改 maxIf
- `lib/features/battle/domain/enum_localizations.dart` — +蓄力/破招/踉跄日志文案
- `lib/features/battle/domain/strategy/default_ground_strategy.dart` — `requestUltimate` 放宽 + `_resolveAction` 蓄力/破招/踉跄 + `_calculateInBattle` 踉跄减防
- `lib/features/battle/domain/battle_ai.dart` — aiUsePolicy 跳过 + 蓄力时破招 + 破招技 targeting
- `lib/features/battle/application/stage_battle_setup.dart` — 青衫剑客设 chargeSkillId;进场内力随 maxIf 改动复查
- `lib/data/game_repository.dart` — `_enforceBossChargeRedLines`
- `lib/features/battle/presentation/battle_screen.dart` + `hp_bar.dart`(或 Boss 状态区)— 蓄力条 + 破招标记 + 关键技按钮 + 失败提示 key
- `lib/shared/strings.dart` — 失败提示 + 破招按钮文案 key

新增测试:`test/features/battle/p0_charge_break_test.dart` / `test/features/battle/battle_ai_interrupt_test.dart` / `test/data/p0_boss_charge_redline_test.dart`

---

## Task 1: SkillDef 加 canInterrupt + aiUsePolicy

**Files:**
- Modify: `lib/core/domain/enums.dart:116`(SkillType 旁加 AiUsePolicy)
- Modify: `lib/data/defs/skill_def.dart:12-66`
- Test: `test/data/skill_def_p0_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

void main() {
  test('canInterrupt/aiUsePolicy 缺省值', () {
    final y = {
      'id': 's', 'name': 'n', 'description': 'd', 'type': 'powerSkill',
      'powerMultiplier': 1000, 'internalForceCost': 100, 'cooldownTurns': 3,
      'requiresManualTrigger': false, 'visualEffect': 'x',
    };
    final s = SkillDef.fromYaml(y);
    expect(s.canInterrupt, false);
    expect(s.aiUsePolicy, AiUsePolicy.normal);
  });

  test('canInterrupt/aiUsePolicy 显式解析', () {
    final y = {
      'id': 's', 'name': 'n', 'description': 'd', 'type': 'powerSkill',
      'powerMultiplier': 1000, 'internalForceCost': 100, 'cooldownTurns': 3,
      'requiresManualTrigger': false, 'visualEffect': 'x',
      'canInterrupt': true, 'aiUsePolicy': 'saveForInterrupt',
    };
    final s = SkillDef.fromYaml(y);
    expect(s.canInterrupt, true);
    expect(s.aiUsePolicy, AiUsePolicy.saveForInterrupt);
  });
}
```

- [ ] **Step 2: 跑确认失败**

Run: `flutter test test/data/skill_def_p0_test.dart`
Expected: FAIL（canInterrupt/aiUsePolicy 未定义）。

- [ ] **Step 3: 加 AiUsePolicy enum**

`lib/core/domain/enums.dart` `enum SkillType {` 之前加:
```dart
/// 招式的自动战斗使用策略(P0 破招)。
/// - normal: AI 正常选用(按倍率)
/// - saveForInterrupt: AI 平时不放,仅敌人蓄力时用于破招
/// - manualOnly: P0 留位,仅玩家手动放(暂不实装独立行为)
enum AiUsePolicy { normal, saveForInterrupt, manualOnly }
```

- [ ] **Step 4: SkillDef 加字段 + fromYaml**

`skill_def.dart`:字段区(`imagePath` 之后)加:
```dart
  /// P0 破招:此技命中正在蓄力的目标可打断其招牌技。
  final bool canInterrupt;

  /// P0 破招:AI 自动战斗对此技的使用策略。
  final AiUsePolicy aiUsePolicy;
```
构造器(`this.imagePath,` 之后)加:
```dart
    this.canInterrupt = false,
    this.aiUsePolicy = AiUsePolicy.normal,
```
顶部确保 import `import '../../core/domain/enums.dart';`(若未 import)。
`fromYaml` 在 `imagePath: ...,` 之后加:
```dart
      canInterrupt: y['canInterrupt'] as bool? ?? false,
      aiUsePolicy: y['aiUsePolicy'] != null
          ? AiUsePolicy.values.byName(y['aiUsePolicy'] as String)
          : AiUsePolicy.normal,
```

- [ ] **Step 5: 跑确认通过**

Run: `flutter test test/data/skill_def_p0_test.dart`
Expected: PASS（2 测）。

- [ ] **Step 6: Commit**

```bash
git add lib/core/domain/enums.dart lib/data/defs/skill_def.dart test/data/skill_def_p0_test.dart
git commit -m "feat(p0): SkillDef +canInterrupt +aiUsePolicy(破招标记)"
```

---

## Task 2: numbers.yaml combat.boss_charge + BossChargeConfig

**Files:**
- Modify: `data/numbers.yaml`(combat 段)
- Modify: `lib/data/numbers_config.dart`
- Test: `test/data/boss_charge_config_test.dart`

> **实装前必做**:`grep -n "class.*Config\|combat" lib/data/numbers_config.dart` 看现有 sub-config(如 `SchoolCounterConfig`/`ResonanceConfig`)怎么从 `combat` map 解析,**照同一体例**加 `BossChargeConfig`。

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'dart:io';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });
  test('boss_charge 默认值解析', () {
    final bc = GameRepository.instance.numbers.combat.bossCharge;
    expect(bc.defaultChargeTicks, 3);
    expect(bc.defaultStaggerTicks, 2);
    expect(bc.staggerDefenseDown, closeTo(0.3, 1e-9));
  });
}
```

- [ ] **Step 2: 跑确认失败**

Run: `flutter test test/data/boss_charge_config_test.dart`
Expected: FAIL（bossCharge 未定义）。

- [ ] **Step 3: numbers.yaml 加段**

`data/numbers.yaml` 的 `combat:` 段下加:
```yaml
  # P0 破招:Boss 蓄力/踉跄
  boss_charge:
    default_charge_ticks: 3       # 招牌技蓄力 tick 数
    default_stagger_ticks: 2      # 被破招后跳过行动 tick 数
    stagger_defense_down: 0.3     # 踉跄期间防御率乘 (1 - 此值)
```

- [ ] **Step 4: numbers_config.dart 加 BossChargeConfig**

照现有 sub-config 体例,新增类 + 在 `CombatConfig`(或 combat 解析处)加 `bossCharge` 字段:
```dart
class BossChargeConfig {
  final int defaultChargeTicks;
  final int defaultStaggerTicks;
  final double staggerDefenseDown;
  const BossChargeConfig({
    required this.defaultChargeTicks,
    required this.defaultStaggerTicks,
    required this.staggerDefenseDown,
  });
  factory BossChargeConfig.fromYaml(Map y) => BossChargeConfig(
        defaultChargeTicks: (y['default_charge_ticks'] as num).toInt(),
        defaultStaggerTicks: (y['default_stagger_ticks'] as num).toInt(),
        staggerDefenseDown: (y['stagger_defense_down'] as num).toDouble(),
      );
}
```
在 combat 解析处加 `bossCharge: BossChargeConfig.fromYaml(combatMap['boss_charge'] as Map)`(字段名/Map 取法按文件实际)。

- [ ] **Step 5: 跑确认通过**

Run: `flutter test test/data/boss_charge_config_test.dart`
Expected: PASS。

- [ ] **Step 6: Commit**

```bash
git add data/numbers.yaml lib/data/numbers_config.dart test/data/boss_charge_config_test.dart
git commit -m "feat(p0): numbers combat.boss_charge + BossChargeConfig"
```

---

## Task 3: BattleCharacter 加 4 个蓄力/踉跄字段

**Files:**
- Modify: `lib/features/battle/domain/battle_state.dart`(BattleCharacter 56-153 构造 + 290+ copyWith)
- Test: `test/features/battle/battle_character_charge_test.dart`

> copyWith 里 `chargingSkill`(SkillDef?)与 `chargeSkillId`(String?)是可空字段,需用本文件已有的 `_unset` sentinel 模式(参考 `internalInjury` 的 `Object? internalInjury = _unset`),才能在 copyWith 里把它们置回 null(破招时清蓄力)。两个 int 字段(chargeTicksRemaining/staggerTicksRemaining)用普通 `int?` 即可。

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

BattleCharacter _c() => BattleCharacter(
      characterId: 1, name: 'a', realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.yuanShu, school: TechniqueSchool.gangMeng,
      maxHp: 1000, currentHp: 1000, maxInternalForce: 500,
      currentInternalForce: 500, speed: 100, criticalRate: 0.0,
      evasionRate: 0.0, defenseRate: 0.1, totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const [], skillCooldowns: const {},
      activeBuffs: const [], actionPoint: 0, isAlive: true,
      teamSide: 1, slotIndex: 0,
    );

void main() {
  test('蓄力/踉跄字段缺省', () {
    final c = _c();
    expect(c.chargeSkillId, isNull);
    expect(c.chargingSkill, isNull);
    expect(c.chargeTicksRemaining, 0);
    expect(c.staggerTicksRemaining, 0);
  });

  test('copyWith 可设可清', () {
    final c = _c().copyWith(chargeTicksRemaining: 3, staggerTicksRemaining: 2);
    expect(c.chargeTicksRemaining, 3);
    expect(c.staggerTicksRemaining, 2);
    final cleared = c.copyWith(staggerTicksRemaining: 0);
    expect(cleared.staggerTicksRemaining, 0);
  });
}
```

- [ ] **Step 2: 跑确认失败**

Run: `flutter test test/features/battle/battle_character_charge_test.dart`
Expected: FAIL。

- [ ] **Step 3: 加字段 + 构造 + copyWith**

`battle_state.dart` BattleCharacter 字段区(`isBoss` 之后)加:
```dart
  /// P0 破招:此单位的招牌技 id(仅 Boss 配置;null=不蓄力)。
  final String? chargeSkillId;
  /// P0 破招:运行时——当前正在蓄力的招(null=未蓄力)。
  final SkillDef? chargingSkill;
  /// P0 破招:蓄力剩余 tick(0=未蓄力)。
  final int chargeTicksRemaining;
  /// P0 破招:踉跄剩余 tick(0=未踉跄)。
  final int staggerTicksRemaining;
```
构造器(`this.isBoss = false,` 之后)加:
```dart
    this.chargeSkillId,
    this.chargingSkill,
    this.chargeTicksRemaining = 0,
    this.staggerTicksRemaining = 0,
```
顶部确保 import SkillDef(`import '../../../data/defs/skill_def.dart';` 应已有)。
copyWith 签名加(`bool? isBoss,` 之后):
```dart
    Object? chargeSkillId = _unset,
    Object? chargingSkill = _unset,
    int? chargeTicksRemaining,
    int? staggerTicksRemaining,
```
copyWith 返回体里(参照 internalInjury 的 _unset 解包写法)加:
```dart
      chargeSkillId: chargeSkillId == _unset
          ? this.chargeSkillId : chargeSkillId as String?,
      chargingSkill: chargingSkill == _unset
          ? this.chargingSkill : chargingSkill as SkillDef?,
      chargeTicksRemaining: chargeTicksRemaining ?? this.chargeTicksRemaining,
      staggerTicksRemaining: staggerTicksRemaining ?? this.staggerTicksRemaining,
```

- [ ] **Step 4: 跑确认通过 + 全量战斗测不回归**

Run: `flutter test test/features/battle/battle_character_charge_test.dart`
Run: `flutter test test/features/battle/`
Expected: 新测 PASS;现有战斗测全过(新字段有缺省,不影响)。

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/domain/battle_state.dart test/features/battle/battle_character_charge_test.dart
git commit -m "feat(p0): BattleCharacter +蓄力/踉跄 4 字段"
```

---

## Task 4: 进场内力改 maxIf(唯一碰平衡的改动,隔离 + 过 simulator)

**Files:**
- Modify: `lib/features/battle/domain/battle_state.dart:271`(fromCharacter 玩家进场内力)
- Test: `test/features/battle/enter_full_internal_force_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// 构造一个 character + 装备 + technique,断言 fromCharacter 后
// currentInternalForce == maxInternalForce。
// 实装前 grep 现成的 BattleCharacter.fromCharacter 测(test/features/battle/ 下)
// 复用其 seed/fixture,只加一条断言:
//   expect(bc.currentInternalForce, bc.maxInternalForce);
```
> **实装前必做**:`grep -rln "fromCharacter" test/features/battle/` 找现成 fixture,照它构造 BattleCharacter.fromCharacter,加断言 `currentInternalForce == maxInternalForce`。

- [ ] **Step 2: 跑确认失败**

Run: `flutter test test/features/battle/enter_full_internal_force_test.dart`
Expected: FAIL（现状 current=character.internalForce ≠ maxIf）。

- [ ] **Step 3: 改进场内力**

`battle_state.dart:271`,`fromCharacter` 的 return 里:
```dart
      currentInternalForce: character.internalForce,
```
改为:
```dart
      currentInternalForce: maxIf,   // P0:战斗内力进场满(每场预算,§2.1)
```
（`maxIf` 已在同函数 202-207 行算出。）

- [ ] **Step 4: 跑测 + 全量回归 + simulator**

Run: `flutter test test/features/battle/enter_full_internal_force_test.dart`(PASS)
Run: `flutter test`（全量;若有战斗平衡测因起手内力变化失败,逐个核对是否为预期变化,调整断言而非回退机制——记录在 commit message）
Run: balance_simulator（`grep -rn "balance_simulator\|balance_sim" test/ tools/ lib/` 找入口跑一遍,确认 stage 通关分布无异常崩坏）
Expected: 新测 PASS;全量过或仅预期平衡测调整。

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/domain/battle_state.dart test/features/battle/enter_full_internal_force_test.dart
git commit -m "feat(p0): 战斗内力进场满 maxIf(每场预算模型 · 与敌方对称)"
```

---

## Task 5: requestUltimate 放宽接受关键技

**Files:**
- Modify: `lib/features/battle/domain/strategy/default_ground_strategy.dart:113-128`
- Test: `test/features/battle/request_manual_skill_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// 构造 BattleState + 一个 powerSkill(canInterrupt:true),
// 调 DefaultGroundStrategy().requestUltimate(state, charId, powerSkill)
// 断言不抛 + state.pendingUltimates[charId] == powerSkill。
// 再断言传 normalAttack 仍抛 ArgumentError。
```
> 实装前 grep `test/features/battle/` 现成 BattleState/SkillDef 构造体例复用。

- [ ] **Step 2: 跑确认失败**

Run: `flutter test test/features/battle/request_manual_skill_test.dart`
Expected: FAIL（现状 powerSkill 被 throw 拒绝）。

- [ ] **Step 3: 放宽类型守卫**

`default_ground_strategy.dart:118-124` 的守卫:
```dart
    if (ultimate.type != SkillType.ultimate) {
      throw ArgumentError.value(
        ultimate,
        'ultimate',
        'requestUltimate 只接受 type=ultimate 的招式',
      );
    }
```
改为:
```dart
    // P0:泛化为"玩家手动请求关键技"——接受 powerSkill / ultimate / jointSkill,
    // 拒绝 normalAttack(普攻不需手动)。
    if (skill.type == SkillType.normalAttack) {
      throw ArgumentError.value(
        skill, 'skill', '手动请求不接受 normalAttack',
      );
    }
```
并把方法参数名 `SkillDef ultimate` 改为 `SkillDef skill`,方法体 `newPending[characterId] = ultimate;` 改 `= skill;`。方法/接口名保持 `requestUltimate`(不重命名,避免动其他 strategy 实现)。更新 doc 注释为"手动请求关键技"。

- [ ] **Step 4: 跑测 + 战斗回归**

Run: `flutter test test/features/battle/request_manual_skill_test.dart`(PASS)
Run: `flutter test test/features/battle/`(无回归)

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/domain/strategy/default_ground_strategy.dart test/features/battle/request_manual_skill_test.dart
git commit -m "feat(p0): requestUltimate 放宽接受关键技(破招技可手动请求)"
```

---

## Task 6: battle_ai — aiUsePolicy 跳过 + 蓄力时破招 + targeting

**Files:**
- Modify: `lib/features/battle/domain/battle_ai.dart:23-101`
- Test: `test/features/battle/battle_ai_interrupt_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// 用现成 BattleState fixture(grep test/features/battle/ 复用),构造:
// - actor 持一个 powerSkill(aiUsePolicy:saveForInterrupt, canInterrupt:true, 内力够 CD0)
//   + 一个普通 powerSkill(normal)。
// 测 A:对面无人 charging → decide 选的是 normal 技,不是 saveForInterrupt 技。
// 测 B:对面某敌 chargingSkill!=null → decide 选 saveForInterrupt 技,且 targetId == 该 charging 敌人。
```

- [ ] **Step 2: 跑确认失败**

Run: `flutter test test/features/battle/battle_ai_interrupt_test.dart`
Expected: FAIL。

- [ ] **Step 3: 改 _pickSkill + decide targeting**

`battle_ai.dart` `_pickSkill`,在 pending 检查(行 41-44)之后、jointSkill 之前,加蓄力破招分支:
```dart
    // P0:对面有敌人蓄力 + 自己有可用 saveForInterrupt 破招技 → 用它(托管保守破招)
    final enemyTeam = actor.teamSide == 0 ? state.rightTeam : state.leftTeam;
    final enemyCharging =
        enemyTeam.any((e) => e.isAlive && e.chargingSkill != null);
    if (enemyCharging) {
      for (final s in actor.availableSkills) {
        if (s.aiUsePolicy != AiUsePolicy.saveForInterrupt) continue;
        if (!_canUse(actor, s)) continue;
        return s;
      }
    }
```
正常 powerSkill 循环(行 57-63)加跳过:
```dart
      if (s.type != SkillType.powerSkill) continue;
      if (s.aiUsePolicy == AiUsePolicy.saveForInterrupt) continue; // P0:平时不放破招技
      if (!_canUse(actor, s)) continue;
```
`decide`(行 23-36)改为按选中技做 targeting:
```dart
    final skill = _pickSkill(actor, state);
    final enemyTeam = actor.teamSide == 0 ? state.rightTeam : state.leftTeam;
    final charging =
        enemyTeam.where((e) => e.isAlive && e.chargingSkill != null);
    final int targetId;
    if (skill.canInterrupt && charging.isNotEmpty) {
      targetId = charging.first.characterId; // P0:破招技锁定蓄力敌人
    } else {
      targetId = _pickTargetId(actor, state);
    }
    return (skill, targetId);
```
顶部确保 import `AiUsePolicy`(enums.dart 已 import)。

- [ ] **Step 4: 跑测 + 回归**

Run: `flutter test test/features/battle/battle_ai_interrupt_test.dart`(PASS A+B)
Run: `flutter test test/features/battle/`(无回归)

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/domain/battle_ai.dart test/features/battle/battle_ai_interrupt_test.dart
git commit -m "feat(p0): battle_ai aiUsePolicy 跳过 + 蓄力时破招 + 破招技锁定蓄力敌"
```

---

## Task 7: Boss 蓄力状态机(起手/进行/触发)

**Files:**
- Modify: `lib/features/battle/domain/strategy/default_ground_strategy.dart`(_resolveAction 173-326)
- Modify: `lib/features/battle/domain/enum_localizations.dart`(+蓄力日志文案)
- Test: `test/features/battle/p0_charge_break_test.dart`(本任务先建,后续 Task 8 续)

> 蓄力日志文案走 `EnumL10n`(不硬编码中文)。先在 `enum_localizations.dart` 加:
> `static String chargeStart(String name, String skill) => '$name 凝气蓄势:$skill';`
> `static String charging(String name) => '$name 蓄力中……';`

- [ ] **Step 1: 写失败测试**

```dart
// 构造 1v1 BattleState:左=玩家(高速先手),右=Boss(chargeSkillId=其powerSkill, 内力够)。
// 直接 new BattleCharacter 时给 Boss chargeSkillId 指向其 availableSkills 里的 powerSkill。
// tick 推进若干次,断言:
//  - Boss 第一次行动 → 进入 charging(chargingSkill!=null, chargeTicksRemaining==3),本 tick 未对玩家造成伤害。
//  - 再推进 → chargeTicksRemaining 递减(3→2→1)。
//  - 蓄力满后 Boss 行动 → 招牌技命中玩家(玩家 currentHp 下降),charging 清空。
```
> 实装前 grep `test/features/battle/` 现成 1v1 BattleState 构造,复用其 BattleCharacter fixture(补 chargeSkillId)。

- [ ] **Step 2: 跑确认失败**

Run: `flutter test test/features/battle/p0_charge_break_test.dart`
Expected: FAIL（无蓄力逻辑,Boss 直接命中）。

- [ ] **Step 3: _resolveAction 插蓄力 pre-step**

`default_ground_strategy.dart` 的 `_resolveAction`,在阴柔内伤 dot 块结束(约行 230 `}` 之后)、`final (skill, targetId) = BattleAI.decide(...)`(行 232)**之前**插入:
```dart
    // === P0 蓄力 pre-step(踉跄见 Task 8)===
    // (b) 蓄力中:递减;未满写"蓄力中"跳过本次;满则本次放 chargingSkill。
    SkillDef? forcedSkill;
    if (preActor.chargingSkill != null) {
      final remaining = preActor.chargeTicksRemaining - 1;
      if (remaining > 0) {
        final after = preActor.copyWith(
          chargeTicksRemaining: remaining,
          actionPoint: preActor.actionPoint - 1000,
        );
        final lt = preState.leftTeam.toList();
        final rt = preState.rightTeam.toList();
        _replaceById(after.teamSide == 0 ? lt : rt, after);
        return preState.copyWith(
          leftTeam: List.unmodifiable(lt),
          rightTeam: List.unmodifiable(rt),
          actionLog: [
            ...preState.actionLog,
            BattleAction(
              tick: preState.tick,
              actorId: after.characterId,
              description: EnumL10n.charging(after.name),
            ),
          ],
        );
      } else {
        forcedSkill = preActor.chargingSkill;
        preActor = preActor.copyWith(
          chargingSkill: null,
          chargeTicksRemaining: 0,
        );
      }
    }
```
把行 232 `final (skill, targetId) = BattleAI.decide(preActor, preState, n);` 替换为:
```dart
    final SkillDef skill;
    final int targetId;
    if (forcedSkill != null) {
      skill = forcedSkill;
      targetId = BattleAI.decide(preActor, preState, n).$2; // 复用目标选择
    } else {
      final decided = BattleAI.decide(preActor, preState, n);
      // (c) 起手蓄力:选中自己的 chargeSkillId 且未蓄力 → 开始蓄力,本 tick 不出伤。
      if (preActor.chargeSkillId != null &&
          decided.$1.id == preActor.chargeSkillId) {
        final after = preActor.copyWith(
          chargingSkill: decided.$1,
          chargeTicksRemaining: n.combat.bossCharge.defaultChargeTicks,
          actionPoint: preActor.actionPoint - 1000,
        );
        final lt = preState.leftTeam.toList();
        final rt = preState.rightTeam.toList();
        _replaceById(after.teamSide == 0 ? lt : rt, after);
        return preState.copyWith(
          leftTeam: List.unmodifiable(lt),
          rightTeam: List.unmodifiable(rt),
          actionLog: [
            ...preState.actionLog,
            BattleAction(
              tick: preState.tick,
              actorId: after.characterId,
              description: EnumL10n.chargeStart(after.name, decided.$1.name),
            ),
          ],
        );
      }
      skill = decided.$1;
      targetId = decided.$2;
    }
```
（`n.combat.bossCharge` 按 Task 2 实际字段路径;若 combat 下直接是 bossCharge 则 `n.combat.bossCharge`。）顶部确保 import enum_localizations(已有)。

- [ ] **Step 4: 跑测 + 回归**

Run: `flutter test test/features/battle/p0_charge_break_test.dart`(蓄力起手/递减/触发 PASS)
Run: `flutter test test/features/battle/`(无回归——既有 Boss 无 chargeSkillId,走原路径)

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/domain/strategy/default_ground_strategy.dart lib/features/battle/domain/enum_localizations.dart test/features/battle/p0_charge_break_test.dart
git commit -m "feat(p0): Boss 蓄力状态机(起手/进行/触发招牌技)"
```

---

## Task 8: 破招 + 踉跄

**Files:**
- Modify: `lib/features/battle/domain/strategy/default_ground_strategy.dart`(_resolveAction 破招判定 + 踉跄 pre-step + _calculateInBattle 减防)
- Modify: `lib/features/battle/domain/enum_localizations.dart`(+破招/踉跄文案)
- Test: `test/features/battle/p0_charge_break_test.dart`(续)

> `enum_localizations.dart` 加:
> `static String interrupted(String breaker, String boss) => '$breaker 一击破招,$boss 招式溃散!';`
> `static String staggered(String name) => '$name 踉跄难稳。';`

- [ ] **Step 1: 写失败测试(续同文件)**

```dart
// 测 C(破招):Boss 处于 charging(chargingSkill!=null, chargeTicksRemaining=2),
//   玩家用 canInterrupt powerSkill 命中 Boss → 断言:Boss chargingSkill==null,
//   staggerTicksRemaining==2,招牌技进 skillCooldowns。
// 测 D(踉跄):Boss staggerTicksRemaining=2 时其行动 → 断言跳过(不对玩家造成伤害),
//   staggerTicksRemaining 递减为 1。
// 测 E(踉跄减防):Boss staggerTicksRemaining>0 时被普通攻击 → 实际伤害高于同条件非踉跄
//   (可对比 defenseRate*(1-staggerDefenseDown) 的预期)。
```

- [ ] **Step 2: 跑确认失败**

Run: `flutter test test/features/battle/p0_charge_break_test.dart`
Expected: 测 C/D/E FAIL。

- [ ] **Step 3a: 踉跄 pre-step(在 Task 7 插入的蓄力块之前)**

在 Task 7 的蓄力 pre-step(`SkillDef? forcedSkill;`)**之前**加踉跄分支:
```dart
    // (a) 踉跄中:跳过本次行动,递减 stagger。
    if (preActor.staggerTicksRemaining > 0) {
      final after = preActor.copyWith(
        staggerTicksRemaining: preActor.staggerTicksRemaining - 1,
        actionPoint: preActor.actionPoint - 1000,
      );
      final lt = preState.leftTeam.toList();
      final rt = preState.rightTeam.toList();
      _replaceById(after.teamSide == 0 ? lt : rt, after);
      return preState.copyWith(
        leftTeam: List.unmodifiable(lt),
        rightTeam: List.unmodifiable(rt),
        actionLog: [
          ...preState.actionLog,
          BattleAction(
            tick: preState.tick,
            actorId: after.characterId,
            description: EnumL10n.staggered(after.name),
          ),
        ],
      );
    }
```

- [ ] **Step 3b: 破招判定(在 targetAfter 构造处)**

`_resolveAction` 计算 `result` 后、构造 `targetAfter`(约行 268)处,改为先算破招:
```dart
    // P0 破招:canInterrupt 技命中正在蓄力的目标 → 打断 + 踉跄 + 招牌技上 CD。
    final targetCd = Map<String, int>.from(target.skillCooldowns);
    var brokeCharging = false;
    if (skill.canInterrupt && !result.isDodged && target.chargingSkill != null) {
      brokeCharging = true;
      final cs = target.chargingSkill!;
      targetCd[cs.id] = cs.cooldownTurns > 0 ? cs.cooldownTurns : 1;
    }
    final targetAfter = target.copyWith(
      currentHp: newTargetHp,
      isAlive: newTargetHp > 0,
      internalInjury: newInjury,
      skillCooldowns: Map.unmodifiable(targetCd),
      chargingSkill: brokeCharging ? null : target.chargingSkill,
      chargeTicksRemaining: brokeCharging ? 0 : target.chargeTicksRemaining,
      staggerTicksRemaining: brokeCharging
          ? n.combat.bossCharge.defaultStaggerTicks
          : target.staggerTicksRemaining,
    );
```
（原 `targetAfter` 的 currentHp/isAlive/internalInjury 三参保留并入上面。）若破招,把 action 的 description 换成破招文案:在写 BattleAction(行 293-300)处:
```dart
      description: brokeCharging
          ? EnumL10n.interrupted(actorAfter.name, targetAfter.name)
          : _formatAction(actorAfter, targetAfter, skill, result),
```

- [ ] **Step 3c: _calculateInBattle 踉跄减防**

`_calculateInBattle`(行 345-372)在 `return DamageCalculator.calculateResolved(` 之前加:
```dart
    var effDefRate = defender.defenseRate;
    if (defender.staggerTicksRemaining > 0) {
      effDefRate = defender.defenseRate * (1 - n.combat.bossCharge.staggerDefenseDown);
    }
```
把 `defenderDefenseRate: defender.defenseRate,` 改为 `defenderDefenseRate: effDefRate,`。

- [ ] **Step 4: 跑测 + 回归**

Run: `flutter test test/features/battle/p0_charge_break_test.dart`(C/D/E PASS)
Run: `flutter test test/features/battle/`(无回归)

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/domain/strategy/default_ground_strategy.dart lib/features/battle/domain/enum_localizations.dart test/features/battle/p0_charge_break_test.dart
git commit -m "feat(p0): 破招打断 + 踉跄跳过行动 + 踉跄减防增伤"
```

---

## Task 9: stage_02_05 接 Boss 蓄力 + 红线校验

**Files:**
- Modify: `lib/features/battle/application/stage_battle_setup.dart`(敌人构造设 chargeSkillId)
- Modify: `lib/data/game_repository.dart`(_enforceBossChargeRedLines)
- Test: `test/data/p0_boss_charge_redline_test.dart`

> **实装前必做**:① grep `stage_battle_setup.dart` 敌人 BattleCharacter 构造处(约 305-320),看 enemy def 怎么拿 skillIds——青衫剑客的招牌技用哪个 id(倾向其最高倍率 powerSkill `skill_lingqiao_jichu_skill`,因敌方 ult AI 不自动放,见 spec §9.1)。② 看现有 `_enforceMainlineRedLines`/`_enforceBossRecruitRedLines` 体例。

- [ ] **Step 1: 写失败测试**

```dart
// 红线测试(broken-loader transform 体例,参考现有 stage red-line 测):
// - 正常加载:stage_02_05 Boss chargeSkillId 在其 skillIds 内 → 不抛。
// - 注入非法:把某 Boss chargeSkillId 改成不在 skillIds 的 id → 抛 StateError。
// - chargeTicks 越界(numbers 改成 0 或 99)→ 抛。
```

- [ ] **Step 2: 跑确认失败**

Run: `flutter test test/data/p0_boss_charge_redline_test.dart`
Expected: FAIL（无校验）。

- [ ] **Step 3: 敌人构造设 chargeSkillId**

`stage_battle_setup.dart` 敌人 BattleCharacter 构造处,给 isBoss 的敌人设 `chargeSkillId`:从 enemy def 读(stages.yaml 内联字段)或对青衫剑客用其招牌 powerSkill id。最小实现:enemy def 加可选 `chargeSkillId` 字段透传;stages.yaml 青衫剑客加 `chargeSkillId: skill_lingqiao_jichu_skill`。构造时 `chargeSkillId: enemy.chargeSkillId`。

- [ ] **Step 4: 红线校验**

`game_repository.dart` 加 `_enforceBossChargeRedLines`(沿现有体例),在 stage 加载校验链里调:
```dart
// chargeSkillId 必须在该 Boss skillIds 内;chargeTicks∈[1,8];staggerTicks∈[0,5]
```
具体校验 stages 里配了 chargeSkillId 的敌人 + numbers.bossCharge 数值范围。

- [ ] **Step 5: 跑测 + 全量**

Run: `flutter test test/data/p0_boss_charge_redline_test.dart`(PASS)
Run: `flutter test test/data/`(无回归)

- [ ] **Step 6: Commit**

```bash
git add lib/features/battle/application/stage_battle_setup.dart lib/data/game_repository.dart data/stages.yaml test/data/p0_boss_charge_redline_test.dart
git commit -m "feat(p0): 青衫剑客接蓄力技 + _enforceBossChargeRedLines"
```

---

## Task 10: 战斗 UI(蓄力条 + 破招标记 + 关键技按钮 + 失败提示)

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`(关键技按钮 + 失败提示)
- Modify: Boss 状态区 widget(`hp_bar.dart` 或其父)— 蓄力条 + 可破招图标
- Modify: `lib/shared/strings.dart`(破招按钮 + 失败提示 key)

> 这是表现层,只读 BattleState(沿音频 SFX 只读体例),不写战斗态。**实装前**:grep `battle_screen.dart:467-476` 大招按钮 `_onUltimatePressed` + `_findUltimateOf` + `_isUltimateReady` 体例;grep Boss 状态区怎么渲染血条(`hp_bar.dart`)。

- [ ] **Step 1: UiStrings 文案 key**

`lib/shared/strings.dart` 加:
```dart
  // P0 破招
  static const String battleInterruptSkill = '破招';
  static const String battleDefeatHintInterrupt = '蓄力大招难挡——保留内力,看准蓄力时机破招。';
```

- [ ] **Step 2: 关键技按钮(沿大招按钮体例)**

`battle_screen.dart` 加 `_onKeySkillPressed(int slotIndex)`(仿 `_onUltimatePressed`):找该角色 `availableSkills` 里 `canInterrupt==true` 的技 → `requestUltimate(c.characterId, skill)`。加对应按钮 widget(沿大招按钮),`SfxId` 可复用。Boss 有敌人 `chargingSkill!=null` 时按钮**高亮**(读 state 判断)。

- [ ] **Step 3: Boss 蓄力条 + 可破招图标**

Boss 状态区(血条旁):当任一敌人 `chargingSkill!=null` 时,显蓄力进度条(`1 - chargeTicksRemaining/defaultChargeTicks`)+ "可破招"图标。纯读 state。

- [ ] **Step 4: 失败提示**

`_showResultDialog` / `VictoryOverlay` 的 onDefeat 路径:若失败,附 `UiStrings.battleDefeatHintInterrupt`(不硬编码中文)。

- [ ] **Step 5: 编译 + 战斗屏测不回归**

Run: `flutter analyze lib/features/battle/ lib/shared/`
Run: `flutter test test/features/battle/`
Expected: analyze 0;现有战斗 widget 测全过。

- [ ] **Step 6: Commit**

```bash
git add lib/features/battle/presentation/ lib/shared/strings.dart
git commit -m "feat(p0): 战斗 UI 蓄力条+破招标记+关键技按钮+失败提示key"
```

---

## Task 11: e2e + 全量终验

**Files:**
- Test: `test/features/battle/p0_stage_02_05_e2e_test.dart`

- [ ] **Step 1: 写 e2e 测试**

```dart
// 用生产 stages.yaml 加载 stage_02_05,setup 真战斗:
// 测 1(托管 parity):DefaultGroundStrategy().runToEnd(...) 固定 seed → leftWin
//   (托管能独立通关,含被青衫剑客蓄力时自动破招)。
// 测 2(手动破招路径):在 Boss charging 的 tick 前,对玩家主控 requestUltimate(破招技),
//   推进 → 断言 Boss 被 staggered + 招牌技未命中玩家。
// 测 3(targeting):3 敌人下,玩家破招技命中的 targetId == 青衫剑客(charging),非血最低小怪。
```
> 实装前 grep 现成 stage e2e 测(`test/features/battle/` 下 runToEnd / stage_battle_setup 用法)复用 setup。

- [ ] **Step 2: 跑 e2e**

Run: `flutter test test/features/battle/p0_stage_02_05_e2e_test.dart`
Expected: 3 测 PASS。

- [ ] **Step 3: 全量终验**

Run: `flutter analyze`（Expected: No issues found!）
Run: `flutter test`（Expected: 全过;记录新总测数 = 1778 + 新增）
Run: balance_simulator（手动 vs 托管同 seed:tick + 剩余HP + 剩余内力,手动优势在 10-25%;记录数据）

- [ ] **Step 4: 手动冒烟(可选,留 Codex/用户)**

`flutter run -d macos` 进 stage_02_05,确认蓄力条/破招/踉跄/失败提示表现正常。CLI 不截 native app,视觉验收派 Codex。

- [ ] **Step 5: Commit**

```bash
git add test/features/battle/p0_stage_02_05_e2e_test.dart
git commit -m "test(p0): stage_02_05 e2e(托管parity+手动破招+targeting)"
```

---

## Self-Review 结果

**Spec 覆盖:**
- 内力每场预算(进场 maxIf + 不回 + R3 降伤)✅ Task 4 + Task 3/5 现状
- Boss 蓄力 ✅ Task 7 / 破招+踉跄 ✅ Task 8 / 踉跄减防 ✅ Task 8
- 手动关键技 ✅ Task 5 / aiUsePolicy + 托管破招 + targeting(R1/R4)✅ Task 6
- SkillDef canInterrupt/aiUsePolicy ✅ Task 1 / numbers ✅ Task 2 / BattleCharacter 字段 ✅ Task 3
- stage_02_05 接线 + 红线 ✅ Task 9 / UI(R5 窗口高亮不提前布招)✅ Task 10 / e2e 多指标(小3)✅ Task 11
- 失败提示 key(小4)✅ Task 10 / 字段名对齐 bosses.yaml(小2)✅ Task 3/9 / 文案走 EnumL10n+UiStrings ✅ Task 7/8/10

**红线核对:** §5.4 不动 ✅ / 战斗日志走 EnumL10n 非硬编码 ✅(Task 7/8)/ UI 走 UiStrings ✅(Task 10)/ 蓄力态写在 domain 由 strategy 写、表现层只读 ✅ / 不引 Flame ✅。

**实装期必做 grep(已在对应 task 标注):** numbers_config combat sub-config 体例(T2)/ fromCharacter 测 fixture(T4)/ BattleState 构造体例(T5/6/7)/ stage red-line 体例(T9)/ 大招按钮 + 血条 widget(T10)/ stage e2e 体例(T11)。

**类型一致:** `AiUsePolicy`(T1 定义,T6 用)✅;`BattleCharacter.{chargeSkillId,chargingSkill,chargeTicksRemaining,staggerTicksRemaining}`(T3 定义,T7/8/9 用)✅;`n.combat.bossCharge.{defaultChargeTicks,defaultStaggerTicks,staggerDefenseDown}`(T2 定义,T7/8 用)✅;`requestUltimate` 放宽(T5)被 T10 UI 调用 ✅;`EnumL10n.{chargeStart,charging,interrupted,staggered}`(T7/8 加)✅。

**已知风险(实装注意):** ① Task 4(进场 maxIf)是唯一碰平衡处——务必跑 simulator + 逐个核对失败的平衡测是预期变化才调断言。② Task 7/8 共改 `_resolveAction`,串行实装(同文件不并行)。③ chargeSkillId 用 powerSkill(非 ult)定调见 spec §9.1——Task 9 实装第一步确认青衫剑客招牌技 id。
