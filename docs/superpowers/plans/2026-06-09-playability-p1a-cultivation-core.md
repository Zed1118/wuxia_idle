# 可玩性 P1a 养成内核 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> **执行前置(本项目硬约束)**:① 实装等 Codex 战斗 UI 收工后再开(单元 C 接 damage 路径,避免与战斗 presentation 间接撞车)。② 每个写任务走 feat 分支 + subagent implementer(bg 写守卫拦 Edit/Write)。③ 合 main 前 Claude 过闸:analyze 0 + 全量测试 + §5.4 红线 + 硬编码扫 + balance/红线测。④ **Phase 0 先行**:本 plan 写于 spec 阶段,标 `[P0-READ]` 的步骤必须先读当前代码确认结构再动(battle 内部结构本轮未全抓)。

**Goal:** 给技能加养成闭环——Boss 真解/残页解锁来源 + 熟练度阶段效果(越用越强),纯 domain/data 不碰 presentation。

**Architecture:** 三个独立单元。A 技能解锁进度(SaveData 嵌入列表 + SkillUnlockService,账号级)。B Boss 掉技能书(stages.yaml 可选字段 + victory hook wire)。C 熟练度阶段效果(numbers.yaml 配置 + SkillProficiency 纯域 + damage_calculator 乘 proficiencyDamageMult,综合 ≤130% cap)。计数复用现有 `Technique.skillUsageCount`。

**Tech Stack:** Dart / Flutter / Isar(isar_community) / YAML / flutter_test。

上游 spec:`docs/spec/2026-06-09-playability-p1a-cultivation-core-design.md`。二期 backlog:`docs/spec/playability_phase2_backlog.md`。

---

## 文件结构

**新建:**
- `lib/core/domain/skill_unlock_entry.dart` — `SkillUnlockEntry` @embedded + MapLike extension(照 `skill_usage_entry.dart` 体例)
- `lib/features/cultivation/domain/skill_unlock_service.dart` — `SkillUnlockService`(grantManual/addFragment/isUnlocked/fragmentProgress)
- `lib/features/cultivation/domain/skill_proficiency.dart` — 纯域:阶段派生 + damageMult + per-skill effects 解析
- `test/...` 对应单测

**修改:**
- `lib/core/domain/save_data.dart` — 加 `List<SkillUnlockEntry> skillUnlockProgress = []`
- `lib/data/defs/skill_def.dart` — 加可选 `SkillProficiencyEffects? proficiency`
- `lib/data/defs/stage_def.dart` — 加 `String? dropSkillManualId` / `String? dropSkillFragmentId`
- `lib/data/game_repository.dart` — 加 `_enforceSkillDropRedLines()`
- `lib/data/numbers_config.dart` — 加 `SkillUnlockConfig` + `SkillProficiencyConfig`
- `data/numbers.yaml` — 加 `skill_unlock:` 段 + `combat.skill_proficiency:` 段;`version` 0.1.0→0.2.0
- `lib/features/battle/domain/damage_calculator.dart` — `calculateResolved` 加 `proficiencyDamageMult` 参数并乘入伤害链;`calculate` 算并传
- `lib/features/mainline/presentation/stage_entry_flow.dart` — victory hook 链加 Boss 掉书 wire
- `data/skills.yaml` / `data/stages.yaml` — 最小内容(source tag / 真解 / 残页 / per-skill effects)

---

## Phase 1 · 单元 C:熟练度阶段效果

### Task C1: numbers.yaml 加 skill_proficiency 配置 + 解析

**Files:**
- Modify: `data/numbers.yaml`(combat 段下加 skill_proficiency;顶部 version 0.1.0→0.2.0)
- Modify: `lib/data/numbers_config.dart`(加 SkillProficiencyConfig + SkillProficiencyStageConfig,挂到 NumbersConfig)
- Test: `test/data/numbers_config_skill_proficiency_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'dart:io';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  test('skill_proficiency 5 阶 min_uses 单调 + 倍率封顶 1.30', () {
    final p = GameRepository.instance.numbers.skillProficiency;
    expect(p.stages.length, 5);
    expect(p.stages.map((s) => s.minUses).toList(), [0, 30, 100, 300, 800]);
    expect(p.stages.first.damageMult, 1.00);
    expect(p.stages.last.damageMult, 1.30);
    // 单调递增守
    for (var i = 1; i < p.stages.length; i++) {
      expect(p.stages[i].minUses, greaterThan(p.stages[i - 1].minUses));
      expect(p.stages[i].damageMult,
          greaterThanOrEqualTo(p.stages[i - 1].damageMult));
    }
    expect(p.maxDamageMult, 1.30); // = 末阶,作综合 cap
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/numbers_config_skill_proficiency_test.dart`
Expected: FAIL — `numbers.skillProficiency` getter 不存在。

- [ ] **Step 3: numbers.yaml 加配置**

顶部:`version: "0.1.0"` → `version: "0.2.0"`(注释补:P1a 加 skill_unlock + skill_proficiency 段)。
`combat:` 段下追加:

```yaml
  skill_proficiency:
    # 招式熟练度阶段(可玩性 P1a · spec §三/§2.5)。来源=战斗放招次数(含挂机自动战斗)。
    # damage_mult 全局阶段倍率(统一底,所有招含普攻);末阶 1.30 同时作综合加成 cap。
    stages:
      - { id: chuShi,   min_uses: 0,   damage_mult: 1.00 }
      - { id: shunShou, min_uses: 30,  damage_mult: 1.05 }
      - { id: shuLian,  min_uses: 100, damage_mult: 1.12 }
      - { id: jingTong, min_uses: 300, damage_mult: 1.20 }
      - { id: huaJing,  min_uses: 800, damage_mult: 1.30 }
```

- [ ] **Step 4: numbers_config.dart 加解析(照 SectRecruitConfig.fromYaml 体例 numbers_config.dart:2152)**

```dart
class SkillProficiencyStageConfig {
  final String id;
  final int minUses;
  final double damageMult;
  const SkillProficiencyStageConfig(
      {required this.id, required this.minUses, required this.damageMult});

  factory SkillProficiencyStageConfig.fromYaml(Map<String, dynamic> y) =>
      SkillProficiencyStageConfig(
        id: y['id'] as String,
        minUses: (y['min_uses'] as num).toInt(),
        damageMult: (y['damage_mult'] as num).toDouble(),
      );
}

class SkillProficiencyConfig {
  final List<SkillProficiencyStageConfig> stages;
  const SkillProficiencyConfig({required this.stages});

  double get maxDamageMult =>
      stages.map((s) => s.damageMult).reduce((a, b) => a > b ? a : b);

  factory SkillProficiencyConfig.fromYaml(Map<String, dynamic>? y) {
    final raw = (y?['stages'] as List?) ?? const [];
    final stages = raw
        .map((e) => SkillProficiencyStageConfig.fromYaml(
            Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    // 单调红线
    for (var i = 1; i < stages.length; i++) {
      if (stages[i].minUses <= stages[i - 1].minUses) {
        throw StateError('skill_proficiency.stages min_uses 必须严格递增');
      }
      if (stages[i].damageMult < stages[i - 1].damageMult) {
        throw StateError('skill_proficiency.stages damage_mult 不可递减');
      }
    }
    return SkillProficiencyConfig(stages: stages);
  }
}
```

挂到 `NumbersConfig`:加字段 `final SkillProficiencyConfig skillProficiency;`,在 NumbersConfig.fromYaml 里 `skillProficiency: SkillProficiencyConfig.fromYaml((y['combat'] as Map?)?.cast<String,dynamic>()['skill_proficiency'] as Map<String,dynamic>?)`(确认 combat 段已 cast,照既有 combat 子段取法)。

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/data/numbers_config_skill_proficiency_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add data/numbers.yaml lib/data/numbers_config.dart test/data/numbers_config_skill_proficiency_test.dart
git commit -m "feat(p1a): numbers.yaml 加 skill_proficiency 阶段配置 + 解析红线"
```

### Task C2: SkillProficiency 纯域(阶段派生 + damageMult)

**Files:**
- Create: `lib/features/cultivation/domain/skill_proficiency.dart`
- Test: `test/features/cultivation/skill_proficiency_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_proficiency.dart';

void main() {
  final stages = [
    const SkillProficiencyStageConfig(id: 'chuShi', minUses: 0, damageMult: 1.00),
    const SkillProficiencyStageConfig(id: 'shunShou', minUses: 30, damageMult: 1.05),
    const SkillProficiencyStageConfig(id: 'shuLian', minUses: 100, damageMult: 1.12),
    const SkillProficiencyStageConfig(id: 'jingTong', minUses: 300, damageMult: 1.20),
    const SkillProficiencyStageConfig(id: 'huaJing', minUses: 800, damageMult: 1.30),
  ];
  final cfg = SkillProficiencyConfig(stages: stages);

  test('stageFor 按 uses 落档', () {
    expect(SkillProficiency.stageFor(0, cfg).id, 'chuShi');
    expect(SkillProficiency.stageFor(29, cfg).id, 'chuShi');
    expect(SkillProficiency.stageFor(30, cfg).id, 'shunShou');
    expect(SkillProficiency.stageFor(799, cfg).id, 'jingTong');
    expect(SkillProficiency.stageFor(800, cfg).id, 'huaJing');
    expect(SkillProficiency.stageFor(99999, cfg).id, 'huaJing');
  });

  test('damageMultFor 取对应阶段倍率', () {
    expect(SkillProficiency.damageMultFor(0, cfg), 1.00);
    expect(SkillProficiency.damageMultFor(100, cfg), 1.12);
    expect(SkillProficiency.damageMultFor(800, cfg), 1.30);
  });

  test('combinedMult: 全局×(1+perSkillPct) 封顶 maxDamageMult', () {
    // huaJing 1.30 × (1+0.20) = 1.56 → clamp 到 1.30
    expect(SkillProficiency.combinedMult(800, 0.20, cfg), 1.30);
    // shuLian 1.12 × (1+0.05) = 1.176 < cap → 原值
    expect(SkillProficiency.combinedMult(100, 0.05, cfg), closeTo(1.176, 1e-9));
    // perSkillPct 0 → 等于全局
    expect(SkillProficiency.combinedMult(300, 0.0, cfg), 1.20);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/cultivation/skill_proficiency_test.dart`
Expected: FAIL — `skill_proficiency.dart` 不存在。

- [ ] **Step 3: 实现**

```dart
import 'package:wuxia_idle/data/numbers_config.dart';

/// 招式熟练度纯域(可玩性 P1a · spec §三)。
/// 从招式被使用次数派生当前阶段与伤害倍率。计数源 = Technique.skillUsageCount。
class SkillProficiency {
  const SkillProficiency._();

  static SkillProficiencyStageConfig stageFor(
      int uses, SkillProficiencyConfig cfg) {
    var stage = cfg.stages.first;
    for (final s in cfg.stages) {
      if (uses >= s.minUses) stage = s;
    }
    return stage;
  }

  static double damageMultFor(int uses, SkillProficiencyConfig cfg) =>
      stageFor(uses, cfg).damageMult;

  /// 全局阶段倍率 × (1 + per-skill damage_pct),综合封顶 maxDamageMult(§2.5 130% cap)。
  static double combinedMult(
      int uses, double perSkillDamagePct, SkillProficiencyConfig cfg) {
    final raw = damageMultFor(uses, cfg) * (1.0 + perSkillDamagePct);
    final cap = cfg.maxDamageMult;
    return raw > cap ? cap : raw;
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/cultivation/skill_proficiency_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/cultivation/domain/skill_proficiency.dart test/features/cultivation/skill_proficiency_test.dart
git commit -m "feat(p1a): SkillProficiency 纯域(阶段派生+combinedMult 130% cap)"
```

### Task C3: SkillDef 加可选 proficiency.effects schema

**Files:**
- Modify: `lib/data/defs/skill_def.dart`(加 `SkillProficiencyEffects? proficiency` 字段 + 解析,照 canInterrupt/aiUsePolicy 体例 skill_def.dart:50-51,72-75)
- Test: `test/data/skill_def_proficiency_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';

void main() {
  test('无 proficiency 字段 → null(向后兼容)', () {
    final s = SkillDef.fromYaml({
      'id': 's1', 'name': 'x', 'description': 'd', 'type': 'normalAttack',
      'powerMultiplier': 500, 'internalForceCost': 0, 'cooldownTurns': 0,
      'requiresManualTrigger': false, 'visualEffect': 'v',
    });
    expect(s.proficiency, isNull);
  });

  test('proficiency.effects 按阶段解析 damage_pct / cooldown_delta', () {
    final s = SkillDef.fromYaml({
      'id': 's2', 'name': 'x', 'description': 'd', 'type': 'powerSkill',
      'powerMultiplier': 1200, 'internalForceCost': 180, 'cooldownTurns': 6,
      'requiresManualTrigger': false, 'visualEffect': 'v',
      'proficiency': {
        'effects': {
          'shunShou': {'cooldown_delta': -1},
          'shuLian': {'damage_pct': 0.08},
          'jingTong': {'interrupt_power_pct': 0.12},
          'huaJing': {'interrupt_window_bonus_ticks': 1},
        }
      },
    });
    expect(s.proficiency, isNotNull);
    expect(s.proficiency!.damagePctAt('shuLian'), 0.08);
    expect(s.proficiency!.damagePctAt('chuShi'), 0.0); // 未配阶段 = 0
    expect(s.proficiency!.cooldownDeltaAt('shunShou'), -1);
    expect(s.proficiency!.interruptPowerPctAt('jingTong'), 0.12);
    expect(s.proficiency!.interruptWindowBonusAt('huaJing'), 1);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/skill_def_proficiency_test.dart`
Expected: FAIL — `SkillDef.proficiency` 不存在。

- [ ] **Step 3: 实现(加在 skill_def.dart)**

```dart
/// 招式 per-skill 熟练度效果(可玩性 P1a · 只配真解/招牌/破招技)。
/// key=熟练阶段 id(shunShou/shuLian/jingTong/huaJing),value=该阶段起生效的增量。
/// damage_pct 与全局阶段倍率综合后仍受 §2.5 130% cap(见 SkillProficiency.combinedMult)。
class SkillProficiencyEffects {
  final Map<String, double> _damagePct;
  final Map<String, int> _cooldownDelta;
  final Map<String, double> _interruptPowerPct;
  final Map<String, int> _interruptWindowBonus;

  const SkillProficiencyEffects(this._damagePct, this._cooldownDelta,
      this._interruptPowerPct, this._interruptWindowBonus);

  double damagePctAt(String stageId) => _damagePct[stageId] ?? 0.0;
  int cooldownDeltaAt(String stageId) => _cooldownDelta[stageId] ?? 0;
  double interruptPowerPctAt(String stageId) => _interruptPowerPct[stageId] ?? 0.0;
  int interruptWindowBonusAt(String stageId) => _interruptWindowBonus[stageId] ?? 0;

  factory SkillProficiencyEffects.fromYaml(Map<String, dynamic> y) {
    final effects = (y['effects'] as Map?)?.cast<String, dynamic>() ?? const {};
    final dmg = <String, double>{};
    final cd = <String, int>{};
    final ip = <String, double>{};
    final iw = <String, int>{};
    effects.forEach((stage, v) {
      final m = Map<String, dynamic>.from(v as Map);
      if (m['damage_pct'] != null) dmg[stage] = (m['damage_pct'] as num).toDouble();
      if (m['cooldown_delta'] != null) cd[stage] = (m['cooldown_delta'] as num).toInt();
      if (m['interrupt_power_pct'] != null) ip[stage] = (m['interrupt_power_pct'] as num).toDouble();
      if (m['interrupt_window_bonus_ticks'] != null) iw[stage] = (m['interrupt_window_bonus_ticks'] as num).toInt();
    });
    return SkillProficiencyEffects(dmg, cd, ip, iw);
  }
}
```

SkillDef 加字段 `final SkillProficiencyEffects? proficiency;`,构造函数加 `this.proficiency`,fromYaml 末加:

```dart
      proficiency: y['proficiency'] != null
          ? SkillProficiencyEffects.fromYaml(
              Map<String, dynamic>.from(y['proficiency'] as Map))
          : null,
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/data/skill_def_proficiency_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/defs/skill_def.dart test/data/skill_def_proficiency_test.dart
git commit -m "feat(p1a): SkillDef 加可选 proficiency.effects schema(向后兼容)"
```

### Task C4: damage_calculator 加 proficiencyDamageMult 参数并乘入

**Files:**
- Modify: `lib/features/battle/domain/damage_calculator.dart`(calculateResolved:89-179 加参数 + 乘项)
- Test: `test/features/battle/damage_calculator_proficiency_test.dart`

- [ ] **Step 1: 写失败测试(对 calculateResolved 直接传参,纯函数)**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
// 其余 import 照 damage_calculator 既有测试文件复制(SkillDef/枚举/NumbersConfig)

void main() {
  // [P0-READ] 先读 test/features/battle 下既有 calculateResolved 测试,
  // 复制其构造 SkillDef + NumbersConfig + 枚举入参的 setup,只多传 proficiencyDamageMult。
  test('proficiencyDamageMult=1.30 时主伤害 = 基线 ×1.30(取整)', () {
    // baseline = calculateResolved(... proficiencyDamageMult: 1.0, forceCritical:false)
    // boosted  = calculateResolved(... proficiencyDamageMult: 1.30, 其余同)
    // expect(boosted.mainDamage, (baseline.mainDamage * 1.30).toInt()); 容 ±1 取整误差
  });

  test('默认 proficiencyDamageMult=1.0 时与旧行为一致(回归守)', () {
    // 不传该参数 → 与改动前同输入的 mainDamage 一致
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/battle/damage_calculator_proficiency_test.dart`
Expected: FAIL — 命名参数 `proficiencyDamageMult` 不存在。

- [ ] **Step 3: 实现**

`calculateResolved` 签名加默认参数(放 `forceCritical` 旁):

```dart
  double proficiencyDamageMult = 1.0,
```

伤害合并链(damage_calculator.dart:172-178)加一项:

```dart
final raw = base *
    cultMult *
    schoolMult *
    critMult *
    defMult *
    realmMult *
    attackPowerMultiplier *
    proficiencyDamageMult;   // ← 可玩性 P1a:熟练度综合倍率(已含 130% cap)
```

- [ ] **Step 4: 跑测试确认通过 + 全量 damage 测回归**

Run: `flutter test test/features/battle/damage_calculator_proficiency_test.dart`
Run: `flutter test test/features/battle/`
Expected: PASS,旧 damage 测全绿(默认 1.0 不改行为)。

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/domain/damage_calculator.dart test/features/battle/damage_calculator_proficiency_test.dart
git commit -m "feat(p1a): damage_calculator 加 proficiencyDamageMult 乘项(默认1.0零回归)"
```

### Task C5: [P0-READ] 战斗里算 proficiencyDamageMult 并传入

**Files:**
- Modify: `lib/features/battle/domain/damage_calculator.dart`(calculate(ctx,n):37-71 路径)
- 可能 Modify: AttackContext 定义(让其携带当前招的 skillUsageCount;**先读结构定**)
- Test: `test/features/battle/damage_calculator_proficiency_wire_test.dart`

- [ ] **Step 1: [P0-READ] 读结构**

读 `damage_calculator.dart:1-71`(AttackContext 定义 + calculate)。确认:从 ctx 能否拿到 `ctx.skill.id` + 攻方该招的累积使用次数。该招属 `ctx.skill.parentTechniqueDefId` 对应的 Technique 实例,其 `skillUsageCount.countOf(skill.id)` 即次数。判断 AttackContext 是否已携带攻方 Technique 实例;若无,加一个可选 `int skillUses = 0` 字段由调用方填(battle_resolution 出招时已知 owner.skillUsageCount)。

- [ ] **Step 2: 写失败测试**

```dart
// 构造两个 AttackContext:同招同攻防,uses=0 vs uses=800;
// 期望 uses=800 的 mainDamage ≈ uses=0 的 ×1.30(取整,容±1)。
// per-skill effects=null 时综合 = 全局阶段倍率。
```

- [ ] **Step 3: 实现**

`calculate(ctx, n)` 内,调 `calculateResolved` 前算:

```dart
final uses = ctx.skillUses; // 或从 ctx 的 Technique 实例 countOf(ctx.skill.id)
final perSkillPct = ctx.skill.proficiency?.damagePctAt(
        SkillProficiency.stageFor(uses, n.skillProficiency).id) ??
    0.0;
final profMult = SkillProficiency.combinedMult(uses, perSkillPct, n.skillProficiency);
```

传 `proficiencyDamageMult: profMult` 进 calculateResolved。调用方(battle_resolution 出招处,见 :268 邻近构造 AttackContext 的地方)填入 `skillUses: owner.skillUsageCount.countOf(skillId)`。

- [ ] **Step 4: 跑测试 + 全量 battle 测回归**

Run: `flutter test test/features/battle/`
Expected: PASS。

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle/ test/features/battle/damage_calculator_proficiency_wire_test.dart
git commit -m "feat(p1a): 战斗出招按 skillUsageCount 算熟练度综合倍率并传入伤害计算"
```

### Task C6: [P0-READ] per-skill cooldown_delta / interrupt 效果应用

> 范围:仅给配了 proficiency.effects 的少数招应用 cooldown_delta(技能可用性判定处)+ interrupt_power_pct / interrupt_window_bonus_ticks(复用 P0 canInterrupt/踉跄链路)。**若 Phase 0 发现破招判定无现成钩子可低风险注入,interrupt 两项降级为 schema-only,记 backlog,P1a 只落 cooldown_delta + damage_pct**(damage_pct 已在 C5)。

**Files:**
- [P0-READ] Modify: 技能冷却可用性判定处(grep `cooldownTurns` 在 battle 域的消费点) + 破招判定处(grep `canInterrupt` 消费点,P0 实装)
- Test: 对应单测

- [ ] **Step 1: [P0-READ]** grep `cooldownTurns` / `canInterrupt` 在 `lib/features/battle/` 的消费点,定位注入点。判断 interrupt 两项可否低风险注入;不能则按上方降级并在 `playability_phase2_backlog.md` 加一行。
- [ ] **Step 2:** 写失败测试(熟练阶段 ≥ 配置阶时,该招有效 cooldown = base + cooldown_delta,下限 0;破招力/窗口按阶加成)。
- [ ] **Step 3:** 在定位点应用:`final stage = SkillProficiency.stageFor(uses, cfg).id; effectiveCd = (base + skill.proficiency!.cooldownDeltaAt(stage)).clamp(0, base);` interrupt 同理。
- [ ] **Step 4:** 跑测试 + 全量 battle 测回归。Expected: PASS。
- [ ] **Step 5:** Commit `feat(p1a): per-skill 熟练度效果应用(cooldown/破招;interrupt 视 Phase0 可注入性)`

---

## Phase 2 · 单元 A:技能解锁进度

### Task A1: SkillUnlockEntry 嵌入类 + SaveData 字段

**Files:**
- Create: `lib/core/domain/skill_unlock_entry.dart`(照 `skill_usage_entry.dart` 全文体例)
- Modify: `lib/core/domain/save_data.dart`(加 `List<SkillUnlockEntry> skillUnlockProgress = []`)
- 需跑 build_runner 生成 `.g.dart`(见步骤)
- Test: `test/core/domain/skill_unlock_entry_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';

void main() {
  test('MapLike: addFragment 累加 + unlock 标记幂等', () {
    final list = <SkillUnlockEntry>[];
    expect(list.isUnlocked('s1'), false);
    expect(list.fragmentCountOf('s1'), 0);

    list.addFragment('s1', 3);
    expect(list.fragmentCountOf('s1'), 3);
    list.addFragment('s1', 2);
    expect(list.fragmentCountOf('s1'), 5);

    list.markUnlocked('s1');
    expect(list.isUnlocked('s1'), true);
    list.markUnlocked('s1'); // 幂等
    expect(list.where((e) => e.skillId == 's1').length, 1);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/domain/skill_unlock_entry_test.dart`
Expected: FAIL — 文件不存在。

- [ ] **Step 3: 实现(照 skill_usage_entry.dart 体例,用 indexWhere 不用 firstWhere 回写坑)**

```dart
import 'package:isar_community/isar.dart';

part 'skill_unlock_entry.g.dart';

/// 技能解锁进度(可玩性 P1a · spec §一,账号级 B2 轻量)。
/// 嵌入在 `SaveData.skillUnlockProgress`,模拟 Map<String, {fragmentCount, unlocked}>。
@embedded
class SkillUnlockEntry {
  String skillId = '';
  int fragmentCount = 0;
  bool unlocked = false;
}

extension MapLikeOnSkillUnlock on List<SkillUnlockEntry> {
  SkillUnlockEntry? _find(String skillId) {
    final idx = indexWhere((e) => e.skillId == skillId);
    return idx >= 0 ? this[idx] : null;
  }

  bool isUnlocked(String skillId) => _find(skillId)?.unlocked ?? false;
  int fragmentCountOf(String skillId) => _find(skillId)?.fragmentCount ?? 0;

  void addFragment(String skillId, [int delta = 1]) {
    final idx = indexWhere((e) => e.skillId == skillId);
    if (idx >= 0) {
      this[idx].fragmentCount += delta;
    } else {
      add(SkillUnlockEntry()
        ..skillId = skillId
        ..fragmentCount = delta);
    }
  }

  void markUnlocked(String skillId) {
    final idx = indexWhere((e) => e.skillId == skillId);
    if (idx >= 0) {
      this[idx].unlocked = true;
    } else {
      add(SkillUnlockEntry()
        ..skillId = skillId
        ..unlocked = true);
    }
  }
}
```

SaveData 加字段(save_data.dart 末,triggeredBossRecruitStageIds 后):

```dart
  /// 技能解锁进度(可玩性 P1a · spec §一)。账号级,Boss 真解/残页来源。
  /// 真解首通直接 markUnlocked;爬塔残页 addFragment 累加,达阈值自动 markUnlocked。
  /// 不含奇遇技能(走 equippedEncounterSkillId,两套并存)。
  List<SkillUnlockEntry> skillUnlockProgress = [];
```

- [ ] **Step 4: 跑 build_runner + 测试**

Run: `dart run build_runner build --delete-conflicting-outputs`(生成 skill_unlock_entry.g.dart + 更新 save_data.g.dart;注意 .g.dart gitignored,fresh checkout 必跑 — memory feedback_wuxia_pen_build_runner)
Run: `flutter test test/core/domain/skill_unlock_entry_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/domain/skill_unlock_entry.dart lib/core/domain/save_data.dart test/core/domain/skill_unlock_entry_test.dart
git commit -m "feat(p1a): SkillUnlockEntry 嵌入类 + SaveData.skillUnlockProgress 字段"
```

### Task A2: SkillUnlockService

**Files:**
- Create: `lib/features/cultivation/domain/skill_unlock_service.dart`
- Test: `test/features/cultivation/skill_unlock_service_test.dart`(Isar setUp 照 stage_boss_recruit_test.dart:28-48 体例)

- [ ] **Step 1: 写失败测试(Isar 真库,照 stage_boss_recruit_test setUp)**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
// IsarSetup / SaveData / SkillUnlockService import

void main() {
  late Directory tempDir;
  setUpAll(() async { await Isar.initializeIsarCore(download: true); });
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_skill_unlock_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });
  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('grantManual 直接解锁;重复 grant 幂等', () async {
    final svc = SkillUnlockService(IsarSetup.instance);
    await svc.grantManual('skill_qingshan_qingfeng');
    expect(await svc.isUnlocked('skill_qingshan_qingfeng'), true);
    await svc.grantManual('skill_qingshan_qingfeng'); // 幂等
    final (cur, _) = await svc.fragmentProgress('skill_qingshan_qingfeng');
    expect(cur, anyOf(0, isPositive)); // manual 不依赖残页
  });

  test('addFragment 累加,达阈值(5)自动解锁,过阈值不重复', () async {
    final svc = SkillUnlockService(IsarSetup.instance, fragmentThreshold: 5);
    await svc.addFragment('skill_x', 3);
    expect(await svc.isUnlocked('skill_x'), false);
    final (cur, total) = await svc.fragmentProgress('skill_x');
    expect(cur, 3); expect(total, 5);
    await svc.addFragment('skill_x', 2); // 达 5
    expect(await svc.isUnlocked('skill_x'), true);
    await svc.addFragment('skill_x', 9); // 已解锁后再掉不重复解锁/不报错
    expect(await svc.isUnlocked('skill_x'), true);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/cultivation/skill_unlock_service_test.dart`
Expected: FAIL — service 不存在。

- [ ] **Step 3: 实现(同事务读写 SaveData 单例 id=0)**

```dart
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';

/// 技能解锁进度服务(可玩性 P1a · spec §一)。账号级,操作 SaveData.skillUnlockProgress。
class SkillUnlockService {
  final Isar _isar;
  final int fragmentThreshold;
  SkillUnlockService(this._isar, {this.fragmentThreshold = 5});

  Future<SaveData> _save() async =>
      await _isar.saveDatas.get(0) ?? (SaveData()..saveVersion = '0.2.0');

  Future<void> grantManual(String skillId) async {
    await _isar.writeTxn(() async {
      final s = await _save();
      s.skillUnlockProgress.markUnlocked(skillId);
      await _isar.saveDatas.put(s);
    });
  }

  Future<void> addFragment(String skillId, [int n = 1]) async {
    await _isar.writeTxn(() async {
      final s = await _save();
      if (!s.skillUnlockProgress.isUnlocked(skillId)) {
        s.skillUnlockProgress.addFragment(skillId, n);
        if (s.skillUnlockProgress.fragmentCountOf(skillId) >= fragmentThreshold) {
          s.skillUnlockProgress.markUnlocked(skillId);
        }
      }
      await _isar.saveDatas.put(s);
    });
  }

  Future<bool> isUnlocked(String skillId) async =>
      (await _save()).skillUnlockProgress.isUnlocked(skillId);

  Future<(int, int)> fragmentProgress(String skillId) async {
    final s = await _save();
    return (s.skillUnlockProgress.fragmentCountOf(skillId), fragmentThreshold);
  }
}
```

> [P0-READ] 确认 Isar collection accessor 名(`_isar.saveDatas` / `.get(0)`)与现有 GameRepository 用法一致;SaveData() 新建是否需补 createdAt/lastSavedAt 等 late 字段(测里只 put/get 同库,确认 late 不触发即可,否则用既有 SaveData.create 工厂)。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/cultivation/skill_unlock_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/cultivation/domain/skill_unlock_service.dart test/features/cultivation/skill_unlock_service_test.dart
git commit -m "feat(p1a): SkillUnlockService(grantManual/addFragment 阈值幂等)"
```

---

## Phase 3 · 单元 B:Boss 掉技能书 wire

### Task B1: numbers.yaml skill_unlock 段 + 解析

**Files:**
- Modify: `data/numbers.yaml`(加 skill_unlock 段)
- Modify: `lib/data/numbers_config.dart`(加 SkillUnlockConfig,照 SectRecruitConfig 体例)
- Test: `test/data/numbers_config_skill_unlock_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
test('skill_unlock 阈值 + 残页掉率', () {
  final u = GameRepository.instance.numbers.skillUnlock;
  expect(u.fragmentThreshold, 5);
  expect(u.towerFragmentDropProb, closeTo(0.20, 1e-9));
});
```

- [ ] **Step 2: 跑测试确认失败** — `numbers.skillUnlock` 不存在。

- [ ] **Step 3: numbers.yaml 加段**

```yaml
skill_unlock:
  # 可玩性 P1a · spec §二。Boss 技能书来源。
  fragment_threshold: 5          # 爬塔残页集齐 N 片解锁(§16 #4 默认,可调)
  tower_fragment_drop_prob: 0.20 # 爬塔 Boss 掉残页概率(主线真解首通必给,无需概率)
```

numbers_config.dart 加(照 SectRecruitConfig.fromYaml):

```dart
class SkillUnlockConfig {
  final int fragmentThreshold;
  final double towerFragmentDropProb;
  const SkillUnlockConfig(
      {required this.fragmentThreshold, required this.towerFragmentDropProb});
  static const empty = SkillUnlockConfig(fragmentThreshold: 5, towerFragmentDropProb: 0.20);
  factory SkillUnlockConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null || y.isEmpty) return empty;
    return SkillUnlockConfig(
      fragmentThreshold: (y['fragment_threshold'] as num?)?.toInt() ?? 5,
      towerFragmentDropProb: (y['tower_fragment_drop_prob'] as num?)?.toDouble() ?? 0.20,
    );
  }
}
```

挂 NumbersConfig:`final SkillUnlockConfig skillUnlock;` + fromYaml 里 `skillUnlock: SkillUnlockConfig.fromYaml((y['skill_unlock'] as Map?)?.cast<String,dynamic>())`。

- [ ] **Step 4: 跑测试确认通过** — Run: `flutter test test/data/numbers_config_skill_unlock_test.dart` → PASS

- [ ] **Step 5: Commit** — `feat(p1a): numbers.yaml skill_unlock 段(阈值+残页掉率)+ 解析`

### Task B2: StageDef 加 dropSkill 字段 + 红线校验

**Files:**
- Modify: `lib/data/defs/stage_def.dart`(加 `String? dropSkillManualId` / `String? dropSkillFragmentId`,照 bossRecruit 体例 :77-81,159-163)
- Modify: `lib/data/game_repository.dart`(加 `_enforceSkillDropRedLines()`,照 `_enforceBossRecruitRedLines` :1257-1281,并在调 bossRecruit 校验处一并调用)
- Test: `test/data/stage_skill_drop_redline_test.dart`(brokenLoader transform 体例,照 stage_boss_recruit_test:89-128)

- [ ] **Step 1: 写失败测试(红线:非 Boss 关配 dropSkill → 抛 / id 不存在 → 抛)**

```dart
// brokenLoader: 读 production stages.yaml 字符串后 String.replace 注入一处违例,
// 期望 GameRepository.loadAllDefs(loader: brokenLoader) 抛 StateError。
// 正例:production 中 3 主线 Boss 配 dropSkillManualId 且 id 存在 → 不抛。
```

- [ ] **Step 2: 跑测试确认失败** — 字段/校验不存在。

- [ ] **Step 3: 实现**

StageDef 加字段 + fromYaml `dropSkillManualId: y['dropSkillManualId'] as String?`(同 dropSkillFragmentId)。
game_repository.dart 加:

```dart
void _enforceSkillDropRedLines() {
  for (final s in stageDefs.values) {
    final manual = s.dropSkillManualId;
    final frag = s.dropSkillFragmentId;
    if (manual == null && frag == null) continue;
    if (!s.isBossStage) {
      throw StateError('stage ${s.id} 配 dropSkill 但 isBossStage=false,仅 Boss 关可配(P1a §二红线)');
    }
    for (final id in [manual, frag]) {
      if (id != null && skillDefs[id] == null) {
        throw StateError('stage ${s.id} dropSkill id=$id 未在 skills.yaml(P1a §二红线)');
      }
    }
  }
}
```

在 `_enforceBossRecruitRedLines()` 被调处旁加 `_enforceSkillDropRedLines();`([P0-READ] grep 该调用点)。

- [ ] **Step 4: 跑测试确认通过 + 全量 data 测** — Run: `flutter test test/data/` → PASS

- [ ] **Step 5: Commit** — `feat(p1a): StageDef dropSkillManualId/FragmentId + 红线校验`

### Task B3: victory hook wire 掉技能书

**Files:**
- Create: `lib/features/cultivation/presentation/stage_skill_drop_hook.dart`(照 stage_boss_recruit_hook 体例,函数 `runStageSkillDropHookAfterVictory`)
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart`(victory 链 :206 后加调用)
- Test: `test/features/cultivation/stage_skill_drop_hook_test.dart`(e2e:Boss 胜利 → 真解解锁 / 残页累加 / 首通防重复)

- [ ] **Step 1: 写失败测试(e2e domain)**

```dart
// seed:SaveData clearedStageIds 不含 stage_01_05 → 调 hook(模拟首通胜利) →
//   svc.isUnlocked(该 Boss dropSkillManualId) == true。
// 再次调(clearedStageIds 已含)→ 真解不重复给(幂等),残页型 Boss 改 addFragment。
// 爬塔残页:rng 命中 → fragmentCount += 1;集齐 5 次 → 自动解锁。
```

- [ ] **Step 2: 跑测试确认失败** — hook 不存在。

- [ ] **Step 3: 实现 hook**

```dart
/// Boss 胜利后掉技能书(可玩性 P1a · spec §二)。
/// 主线 dropSkillManualId:首通(stage 未在 clearedStageIds)必给真解,重复不再给。
/// 爬塔 dropSkillFragmentId:按 towerFragmentDropProb rng 命中掉 1 残页,集齐自动解锁。
Future<void> runStageSkillDropHookAfterVictory({
  required StageDef stage,
  required SkillUnlockService svc,
  required Set<String> clearedStageIds,
  required double towerFragmentDropProb,
  required Random rng,
}) async {
  final manual = stage.dropSkillManualId;
  if (manual != null && !clearedStageIds.contains(stage.id)) {
    await svc.grantManual(manual); // 首通必给
  }
  final frag = stage.dropSkillFragmentId;
  if (frag != null && rng.nextDouble() < towerFragmentDropProb) {
    await svc.addFragment(frag, 1);
  }
}
```

stage_entry_flow.dart 在 `runStageBossRecruitHookAfterVictory`(:206)之后加调用([P0-READ] 拿 clearedStageIds / numbers / rng 的 provider 入口,照既有 hook 取 ref.read 方式)。

> 注:首通判定要用"本场胜利写 clearedStageIds **之前**"的快照。[P0-READ] 确认 stage_entry_flow 里 clearedStageIds 何时写入,本 hook 须在写入前读,或传入旧快照。

- [ ] **Step 4: 跑测试确认通过 + 全量 mainline/battle 回归** — PASS

- [ ] **Step 5: Commit** — `feat(p1a): victory hook wire Boss 掉技能书(真解首通/残页概率)`

---

## Phase 4 · 最小验证内容 + 装配 gate

### Task D1: skills.yaml 补技能级 source tag + 3 真解 + 残页 + per-skill effects

**Files:**
- Modify: `data/skills.yaml`(166 招加 source tag;真解/残页/破势/青锋绝 加 proficiency.effects)
- Modify: `data/stages.yaml`(3 主线 Boss 加 dropSkillManualId;1-2 爬塔 Boss 加 dropSkillFragmentId)
- Test: `test/data/p1a_min_content_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
test('3 主线章末 Boss 配 dropSkillManualId 且 id 在 skills.yaml', () {
  final repo = GameRepository.instance;
  for (final sid in ['stage_01_05', 'stage_02_05', 'stage_03_05']) {
    final m = repo.stageDefs[sid]!.dropSkillManualId;
    expect(m, isNotNull, reason: '$sid 应配真解');
    expect(repo.skillDefs[m], isNotNull);
  }
  // 02_05 复用青锋绝
  expect(repo.stageDefs['stage_02_05']!.dropSkillManualId, 'skill_qingshan_qingfeng');
});

test('真解/破势 配 proficiency.effects', () {
  final repo = GameRepository.instance;
  expect(repo.skillDefs['skill_qingshan_qingfeng']!.proficiency, isNotNull);
  expect(repo.skillDefs['skill_po_shi']!.proficiency, isNotNull);
});
```

- [ ] **Step 2: 跑测试确认失败** — 字段未配。

- [ ] **Step 3: 改 yaml**

stages.yaml:stage_01_05 加 `dropSkillManualId: <现有某主线代表招 id>`;stage_02_05 加 `dropSkillManualId: skill_qingshan_qingfeng`;stage_03_05 加 `dropSkillManualId: <id>`。选 1-2 个爬塔 Boss(grep stages.yaml isBossStage 的爬塔关)加 `dropSkillFragmentId: <id>`。
([P0-READ] 选真解招 id:用各章已有的代表性 powerSkill,别造新招。stages.yaml 编辑从 `- id:` 正向定位,不从 isBossStage 反搜 — memory feedback_stages_yaml_edit_direction)
skills.yaml:真解(青锋绝/2 个主线代表招)+ 破势 加:

```yaml
    proficiency:
      effects:
        shuLian: { damage_pct: 0.08 }
        jingTong: { interrupt_power_pct: 0.12 }
        huaJing: { interrupt_window_bonus_ticks: 1 }
```

166 招 source tag:沿 techniques.yaml `acquireSourceTags` 体例给 skills.yaml 加技能级来源标(若 §一/装配 gate 不消费则本批可降级为占位注释,记 backlog;**source tag 不阻塞 P1a 验收路径**,优先级低于真解/残页/熟练度)。

- [ ] **Step 4: 跑测试确认通过 + schema 校验全量** — Run: `flutter test test/data/` → PASS(红线校验 B2 不抛)

- [ ] **Step 5: Commit** — `feat(p1a): 最小内容 3真解+残页+per-skill effects(青锋绝/破势)`

### Task D2: 技能装配 gate(§5.3 三系锁死)

**Files:**
- [P0-READ] Modify: 技能装配/可用判定处(grep 技能如何 attach 到角色 + 是否已有境界 gate)
- Test: `test/features/.../skill_equip_gate_test.dart`

- [ ] **Step 1: [P0-READ]** grep 技能装配入口(skill 如何进战斗可用池 / equippedEncounterSkillId 装配处),确认有无境界比较。照 `equipment.dart:107 isEquippableAtRealm` 体例(`tier.index <= realmTier.index`)给技能加 `canEquipByTier`。
- [ ] **Step 2: 写失败测试** — 高 tier 真解 + 低境界角色 → canEquip=false;够境界 → true。
- [ ] **Step 3: 实现** — SkillDef 或 SkillRepository 加 `bool canEquipAtRealm(RealmTier r) => (tier ?? 0) <= r.index;` 装配入口调用守。**解锁≠可装配**:已解锁但不够境界仍 false(§5.3 师承遗物不例外同理)。
- [ ] **Step 4: 跑测试 + 回归** — PASS
- [ ] **Step 5: Commit** — `feat(p1a): 技能装配境界 gate(§5.3 高阶真解低境界不可装配)`

---

## Phase 5 · 收口(过闸)

### Task E1: 红线测 + balance_simulator + 全量

**Files:**
- Test: `test/data/p1a_redline_test.dart`

- [ ] **Step 1: 写红线测**

```dart
test('熟练满阶 huaJing + per-skill damage_pct 综合不破 130% cap', () {
  final cfg = GameRepository.instance.numbers.skillProficiency;
  // 任意 per-skill damage_pct,combinedMult ≤ 1.30
  for (final pct in [0.0, 0.08, 0.20, 0.50]) {
    expect(SkillProficiency.combinedMult(800, pct, cfg), lessThanOrEqualTo(1.30));
  }
});

test('§5.4 绝对线:最高倍率招 × 1.30 后普伤仍 ≤ 8000', () {
  // [P0-READ] 取 skills.yaml 中最高 powerMultiplier 的 normal/power 招(非大招),
  // 按满配 calculateResolved × 1.30 算,断言 mainDamage <= 8000(大招走"几万"档另算)。
});
```

- [ ] **Step 2: 跑红线测** — Run: `flutter test test/data/p1a_redline_test.dart` → PASS
- [ ] **Step 3: balance_simulator** — [P0-READ] 跑项目平衡校验(grep `balance` 在 test/ 下的 simulator 入口 / `test/tools/`;按 memory 该项目有 balance_simulator 真 build)。失败的平衡测逐个确认是预期内力/伤害变化才调断言,**别硬改掩盖**(memory feedback_phase05)。
- [ ] **Step 4: analyze 0 + 全量** — Run: `flutter analyze`(0)+ `flutter test`(全绿,记 baseline delta)。Expected: 全绿。
- [ ] **Step 5: Commit** — `test(p1a): 熟练度130% cap + §5.4 绝对线红线测`

### Task E2: 合 main 过闸 + 文档

- [ ] analyze 0 / 全量测试全绿 / §5.4 红线不破 / 硬编码扫(无新增中文/数值常量)/ balance_simulator 通过。
- [ ] 更新 `playability_phase2_backlog.md`:勾掉 P1a 已落项,补 Phase0 降级项(若 interrupt 效果/source tag 降级)。
- [ ] 更新 PROGRESS.md 顶段一条。
- [ ] ff 合 main(或留用户决定 push)。

---

## Self-Review(写 plan 后自查)

- **Spec 覆盖**:单元 A→Phase2(A1/A2)✓ 单元 B→Phase3(B1/B2/B3)✓ 单元 C→Phase1(C1-C6)✓ 最小内容→D1 ✓ 装配 gate→D2 ✓ 红线/测试→E1 ✓。spec §一/二/三/四/五全有任务对应。
- **偏离 spec 记录**:① proficiency 配置放 numbers.yaml 非 data/proficiency.yaml(避免新 loader,spec §11 允许"以代码现状为准")。② interrupt 两项视 Phase0 可注入性可能降级 schema-only(C6 已写降级路径 + 记 backlog)。③ source tag 优先级低、可降级占位(D1)。三条均已在任务内标注。
- **类型一致**:SkillProficiencyConfig/StageConfig(C1)→ SkillProficiency.combinedMult(C2)→ calculateResolved proficiencyDamageMult(C4)→ calculate 传入(C5)一致;SkillUnlockEntry MapLike(A1)→ SkillUnlockService(A2)一致;dropSkillManualId/FragmentId(B2)→ hook(B3)→ 内容(D1)一致。
- **Phase 0 依赖**:C5/C6/B2(调用点)/B3/D1(选招 id)/D2/E1(最高倍率招)标 `[P0-READ]`,执行时先读现状——本 plan 写于 spec 阶段,battle 内部结构(AttackContext/cooldown/破招判定/clearedStageIds 写入时机)未全抓,故诚实标注,不臆造。
