# 三人协同 · 破绽窗口链路（第六阶段）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 3v3 的三单位真协同——某单位破招/破防敌人开「破绽窗口」，窗口内 AI 自动集火 + 即放提示玩家爆发 + 表现层反馈，形成「破招→破防→爆发」链路。

**Architecture:** 方案 A 泛化现有踉跄为统一「破绽窗口」，复用 `BattleCharacter.staggerTicksRemaining` / `staggerDefenseDownOverride`，不新建并行状态。破防 = 新 `SkillDef.defenseBreakPct` 命中即开窗（不要求蓄力，刷新不叠加）；AI 集火 = `battle_ai.decide` 目标优先级加破绽敌；表现/即放复用第五阶段 2.4 题字 overlay + 2.3 即放路径。

**Tech Stack:** 纯 Dart 领域层（damage/strategy/ai 无 Flutter 依赖）+ Riverpod + Isar 无关测 + flutter_test。

**上游 spec:** `docs/spec/2026-06-18-phase6-coop-break-window-design.md`

**红线（每 task 守）:** §5.4 破防+踉跄减防硬 clamp 地板、刷新不叠加、集火不抬高单次输出（不进百万）· §5.5 即放/集火不改逻辑速度、自动战斗 AI 集火等价生效 · §5.6 数值进 yaml、中文进 UiStrings · §5.7 爽感走表现层 · 三系锁死不涉及。

---

## 文件结构

| 文件 | 责任 | 动作 |
|---|---|---|
| `lib/data/defs/skill_def.dart` | `SkillDef.defenseBreakPct` 字段 + yaml parse | Modify |
| `lib/data/numbers_config.dart` | `DefenseBreakConfig` 强类型 + 接入 `CombatConfig` | Modify |
| `data/numbers.yaml` | `combat.defense_break` 配置块 | Modify |
| `lib/features/battle/domain/strategy/default_ground_strategy.dart` | 破防开窗分支（统一破招/破防窗口字段 + 刷新不叠加 + 减防地板 clamp） | Modify |
| `lib/features/battle/domain/battle_action.dart` | `openedBreakWindow` bool（表现层读，沿 `interrupted` 体例） | Modify |
| `lib/features/battle/domain/battle_ai.dart` | `decide` 目标优先级加破绽敌集火 | Modify |
| `lib/features/battle/presentation/impact_profile.dart` | 「破绽」glyph 派生（开窗 action） | Modify |
| `lib/features/battle/presentation/battle_screen.dart` | 开窗题字「破绽」+ 破绽敌高亮 + 即放提示「该爆发了」 | Modify |
| `lib/features/cultivation/application/skill_loadout_resolver.dart` | autoFill 按 lineage 角色倾向（破防/爆发/控制） | Modify |
| `lib/shared/strings.dart` | `UiStrings`「破绽」「该爆发了」破防释义 | Modify |
| `data/skills.yaml` | 破防技内容（刚猛震系 + 流派缺口补招） | Modify |
| `test/...` | 各 task 纯函数 + 确定性 + widget + 红线测 | Create |

---

## Task 1: 破防 schema（`SkillDef.defenseBreakPct` + `DefenseBreakConfig`）

**Files:**
- Modify: `lib/data/defs/skill_def.dart`（字段 ~:60-66 区 / 构造 :89 / parse :123）
- Modify: `lib/data/numbers_config.dart`（`BossChargeConfig` 后 :1166 区 + `CombatConfig` 字段 ~:1091）
- Modify: `data/numbers.yaml`（`combat.boss_charge` 后 ~:130）
- Test: `test/data/defense_break_schema_test.dart`

- [ ] **Step 1: 写失败测**

```dart
// test/data/defense_break_schema_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

void main() {
  test('SkillDef.defenseBreakPct 默认 0、可从 yaml parse', () {
    const d = SkillDef(
      id: 'x', name: 'x', description: 'x', type: SkillType.powerSkill,
      powerMultiplier: 1000, internalForceCost: 50, cooldownTurns: 2,
      requiresManualTrigger: false, visualEffect: 'none',
    );
    expect(d.defenseBreakPct, 0.0);

    final parsed = SkillDef.fromYaml({
      'id': 'y', 'name': 'y', 'description': 'y', 'type': 'powerSkill',
      'powerMultiplier': 1000, 'internalForceCost': 50, 'cooldownTurns': 2,
      'requiresManualTrigger': false, 'visualEffect': 'none',
      'defenseBreakPct': 0.3,
    });
    expect(parsed.defenseBreakPct, 0.3);
  });

  test('DefenseBreakConfig.fromYaml 解析 + fallback 默认', () {
    final c = DefenseBreakConfig.fromYaml({'window_ticks': 3, 'defense_down_pct': 0.3});
    expect(c.windowTicks, 3);
    expect(c.defenseDownPct, 0.3);
    final fb = DefenseBreakConfig.fromYaml({});
    expect(fb.windowTicks, 3);
    expect(fb.defenseDownPct, 0.3);
  });
}
```

- [ ] **Step 2: 跑测确认失败** — `flutter test test/data/defense_break_schema_test.dart`。Expected: FAIL（`defenseBreakPct` / `DefenseBreakConfig` 未定义）。

- [ ] **Step 3: 加 `SkillDef.defenseBreakPct`**

`skill_def.dart`：在 `targetType` 字段后（:73 后）加
```dart
  /// 第六阶段三人协同:>0 = 命中存活敌人即开「破绽窗口」(不要求蓄力),
  /// 施加该幅度减防,与破招踉跄共用 staggerTicksRemaining/staggerDefenseDownOverride
  /// 字段,刷新不叠加。减防经 boss_charge.interrupt_power_cap 地板 clamp(红线 §5.4)。
  final double defenseBreakPct;
```
构造（:94 `targetType` 后）加 `this.defenseBreakPct = 0.0,`。
parse（:138 `targetType` 后）加
```dart
      defenseBreakPct: (y['defenseBreakPct'] as num?)?.toDouble() ?? 0.0,
```

- [ ] **Step 4: 加 `DefenseBreakConfig` + 接入 `CombatConfig`**

`numbers_config.dart`：在 `BossChargeConfig` 类后（~:1166）加
```dart
/// 第六阶段三人协同:破防开窗参数。fixture 不带该段时回落默认(沿 BossChargeConfig 体例)。
class DefenseBreakConfig {
  final int windowTicks;
  final double defenseDownPct;
  const DefenseBreakConfig({this.windowTicks = 3, this.defenseDownPct = 0.3});
  factory DefenseBreakConfig.fromYaml(Map y) => DefenseBreakConfig(
        windowTicks: (y['window_ticks'] as num?)?.toInt() ?? 3,
        defenseDownPct: (y['defense_down_pct'] as num?)?.toDouble() ?? 0.3,
      );
}
```
在 `CombatConfig`（持 `bossCharge` 的类，~:1091）加字段 `final DefenseBreakConfig defenseBreak;`、构造 `required this.defenseBreak,`（或给默认 `this.defenseBreak = const DefenseBreakConfig(),` 以免动所有 fixture），fromYaml（:1129 `bossCharge:` 后）加
```dart
      defenseBreak: DefenseBreakConfig.fromYaml(
          (y['defense_break'] as Map?) ?? const {}),
```

- [ ] **Step 5: 加 yaml 配置** — `data/numbers.yaml` `combat.boss_charge:`（:125-129）后加
```yaml
  defense_break:            # 第六阶段:破防开窗(破招外的第二开窗来源)
    window_ticks: 3         # 破绽窗口时长(踉跄 default_stagger_ticks=2,破防略长)
    defense_down_pct: 0.30  # 减防幅度,与 stagger_defense_down 同档;经 interrupt_power_cap 0.5 地板 clamp
```

- [ ] **Step 6: 跑测确认通过** — `flutter test test/data/defense_break_schema_test.dart`。Expected: PASS。

- [ ] **Step 7: 全量 analyze + commit** — `flutter analyze`（Expected: 0）；
```bash
git add lib/data/defs/skill_def.dart lib/data/numbers_config.dart data/numbers.yaml test/data/defense_break_schema_test.dart
git commit -m "feat(第六阶段): 破防 schema - SkillDef.defenseBreakPct + DefenseBreakConfig"
```

---

## Task 2: 破防开窗逻辑（`default_ground_strategy` 统一窗口 + 刷新不叠加 + 减防地板）

**Files:**
- Modify: `lib/features/battle/domain/strategy/default_ground_strategy.dart`（`_resolveOneTarget` 结算区 ~:595-646）
- Modify: `lib/features/battle/domain/battle_action.dart`（加 `openedBreakWindow`）
- Test: `test/features/battle/domain/defense_break_window_test.dart`

- [ ] **Step 1: 写失败测**（破防命中非蓄力敌也开窗 + 刷新不叠加 + 减防 clamp）

```dart
// test/features/battle/domain/defense_break_window_test.dart
// 用既有战斗 fixture 构造:攻方持 defenseBreakPct=0.3 的 powerSkill,守方未蓄力。
// 断言:resolve 后守方 staggerTicksRemaining == defenseBreak.windowTicks、
//       staggerDefenseDownOverride == 0.3(< interruptPowerCap 0.5 不被 clamp)、
//       action.openedBreakWindow == true。
// 第二招再破防:staggerTicksRemaining 刷新(不累加超过 windowTicks)、override 取 max 不叠加。
```
（实现者按 `test/features/battle/application/master_disciple_battle_test.dart` 既有 fixture 体例构造攻守双方 BattleCharacter + NumbersConfig，调 `DefaultGroundStrategy` 单步结算。具体 fixture 代码在实现时照该文件 setUp 写全。）

- [ ] **Step 2: 跑测确认失败**。Expected: FAIL（`openedBreakWindow` 未定义 / 非蓄力敌 stagger 仍 0）。

- [ ] **Step 3: 加 `BattleAction.openedBreakWindow`** — `battle_action.dart` 沿 `interrupted` bool 体例加 `final bool openedBreakWindow;`（构造默认 false）。

- [ ] **Step 4: 改 `_resolveOneTarget` 统一窗口**（:603-626）

把 `staggerDefDown` / `staggerTicksRemaining` / `staggerDefenseDownOverride` 三处条件重构为同时处理破招与破防：
```dart
    // 破招(现有):打断蓄力敌 → 加深减防 base × (1+power_pct) clamp cap。
    final cap = n.combat.bossCharge.interruptPowerCap;
    final interruptDef = brokeCharging
        ? (n.combat.bossCharge.staggerDefenseDown *
                (1 + SkillProficiency.interruptPowerPct(skill,
                    preActor.skillUses[skill.id] ?? 0, n.skillProficiency)))
            .clamp(0.0, cap)
        : null;
    // 破防(新增):命中存活敌即开窗,不要求蓄力。减防 clamp 到同一 cap 地板。
    final opensBreak = !result.isDodged &&
        skill.defenseBreakPct > 0 &&
        newTargetHp > 0;
    final breakDef =
        opensBreak ? skill.defenseBreakPct.clamp(0.0, cap) : null;
    // 统一窗口:破招优先(更强/特定);否则破防;刷新不叠加(取较强减防 + 刷新时长)。
    final bool windowOpened = brokeCharging || opensBreak;
    final int newStaggerTicks = brokeCharging
        ? n.combat.bossCharge.defaultStaggerTicks +
            SkillProficiency.interruptWindowBonus(skill,
                preActor.skillUses[skill.id] ?? 0, n.skillProficiency)
        : opensBreak
            ? n.combat.defenseBreak.windowTicks
            : target.staggerTicksRemaining;
    final double? newStaggerDef = brokeCharging
        ? interruptDef
        : opensBreak
            // 刷新不叠加:与现有 override 取 max,不连乘穿透。
            ? [breakDef!, target.staggerDefenseDownOverride ?? 0.0]
                .reduce((a, b) => a > b ? a : b)
            : target.staggerDefenseDownOverride;
```
`copyWith` 改用 `newStaggerTicks` / `newStaggerDef`；`BattleAction(...)` 加 `openedBreakWindow: windowOpened,`。

- [ ] **Step 5: 跑测确认通过**。Expected: PASS。

- [ ] **Step 6: 全量测 + analyze 防回归** — `flutter test`（既有破招/踉跄测须全绿）+ `flutter analyze`（0）。

- [ ] **Step 7: commit**
```bash
git add lib/features/battle/domain/strategy/default_ground_strategy.dart lib/features/battle/domain/battle_action.dart test/features/battle/domain/defense_break_window_test.dart
git commit -m "feat(第六阶段): 破防开窗 - 统一破招/破防窗口字段 + 刷新不叠加 + 减防地板 clamp"
```

---

## Task 3: AI 集火（`battle_ai.decide` 目标优先级加破绽敌）

**Files:**
- Modify: `lib/features/battle/domain/battle_ai.dart`（`decide` :60-68 + 新 `_pickFocusTargetId`）
- Test: `test/features/battle/domain/battle_ai_focus_fire_test.dart`

- [ ] **Step 1: 写失败测** — 敌队中一个敌 `staggerTicksRemaining>0`，非破招技 actor 的 `decide` 应锁定该破绽敌（即使它不是血最低）；无破绽敌时回落血最低。

```dart
// 构造 enemyTeam:e0(staggerTicksRemaining=0, hp=100), e1(staggerTicksRemaining=3, hp=200)。
// actor 普攻(非 canInterrupt)。decide 返回 targetIds.first == e1.characterId(集火破绽敌)。
// 再测无破绽敌:全 staggerTicksRemaining=0 → 回落血最低 e0。
```

- [ ] **Step 2: 跑测确认失败**。Expected: FAIL（现回落血最低，选 e0 非 e1）。

- [ ] **Step 3: 改 `decide` 目标分支**（:62-68）

```dart
    final charging =
        enemyTeam.where((e) => e.isAlive && e.chargingSkill != null);
    final int targetId;
    if (skill.canInterrupt && charging.isNotEmpty) {
      targetId = charging.first.characterId; // P0:破招技锁定蓄力敌人
    } else {
      // 第六阶段:破绽窗口内敌优先集火(链路爆发);无则回落血最低。
      targetId = _pickFocusTargetId(actor, state) ?? _pickTargetId(actor, state);
    }
    return (skill, [targetId]);
```
新增（`_pickTargetId` 后）：
```dart
  /// 第六阶段集火:对面处于破绽窗口(staggerTicksRemaining>0)的活角色中血最低、
  /// 同 hp 取 slotIndex 小;无破绽敌返回 null(回落 _pickTargetId)。纯函数无 side effect。
  static int? _pickFocusTargetId(BattleCharacter actor, BattleState state) {
    final enemyTeam = actor.teamSide == 0 ? state.rightTeam : state.leftTeam;
    BattleCharacter? best;
    for (final e in enemyTeam) {
      if (!e.isAlive || e.staggerTicksRemaining <= 0) continue;
      if (best == null ||
          e.currentHp < best.currentHp ||
          (e.currentHp == best.currentHp && e.slotIndex < best.slotIndex)) {
        best = e;
      }
    }
    return best?.characterId;
  }
```

- [ ] **Step 4: 跑测确认通过**。Expected: PASS。

- [ ] **Step 5: 确定性测**（沿 memory feedback_battle_determinism_test_via_notifier）— 经 `ProviderContainer` + 永久 listener 跑 `notifier.advance`，同 seed 下「破防开窗→队友集火」序列可复现（断言 actionLog targetId 序列确定）。文件 `test/features/battle/application/coop_chain_determinism_test.dart`。

- [ ] **Step 6: 全量测 + analyze** — `flutter test` + `flutter analyze`（0）。

- [ ] **Step 7: commit**
```bash
git add lib/features/battle/domain/battle_ai.dart test/features/battle/domain/battle_ai_focus_fire_test.dart test/features/battle/application/coop_chain_determinism_test.dart
git commit -m "feat(第六阶段): AI 集火 - decide 目标优先级加破绽窗口敌 + 确定性测"
```

---

## Task 4: 表现层（开窗题字「破绽」+ 破绽敌高亮）

**Files:**
- Modify: `lib/features/battle/presentation/impact_profile.dart`（`impactProfileFor` 加开窗 glyph 派生）
- Modify: `lib/features/battle/presentation/battle_screen.dart`（`_playAction` 调度区，复用 2.4 `ImpactGlyphOverlay`）
- Modify: `lib/shared/strings.dart`（`UiStrings.impactGlyphBreakWindow = '破绽'`）
- Test: `test/features/battle/presentation/break_window_feedback_widget_test.dart`

- [ ] **Step 1: 写失败测** — `impactProfileFor` 对 `action.openedBreakWindow==true` 的 action 返回 glyph「破绽」；widget 测 `_playAction` 收到开窗 action 时挂载 `ImpactGlyphOverlay`，破绽敌头像有高亮标记。

- [ ] **Step 2: 跑测确认失败**。Expected: FAIL。

- [ ] **Step 3: `impact_profile.dart` 加开窗 glyph** — 在 `impactProfileFor` 派生 glyph 时，`action.openedBreakWindow` 为真且非破招（破招已有「破!」）时 glyph = `UiStrings.impactGlyphBreakWindow`。复用现有 tier/三参数管线，不新建通道。

- [ ] **Step 4: `battle_screen._playAction` 接入** — 复用 2.4 既有 `ImpactGlyphOverlay` 命令式 spawn（照 2.4 `_playAction` 题字分支体例，搜 `ImpactGlyphOverlay`）；额外：开窗 action 的 target slot 头像加高亮（复用既有受击/选中高亮装饰，集火指示）。全走 actionLog 边沿，不写 BattleState。

- [ ] **Step 5: 跑测确认通过**。Expected: PASS。

- [ ] **Step 6: 全量测 + analyze**。

- [ ] **Step 7: commit**
```bash
git add lib/features/battle/presentation/impact_profile.dart lib/features/battle/presentation/battle_screen.dart lib/shared/strings.dart test/features/battle/presentation/break_window_feedback_widget_test.dart
git commit -m "feat(第六阶段): 表现层 - 开窗题字「破绽」+ 破绽敌高亮(复用 2.4 overlay)"
```

---

## Task 5: 即放提示钩子（窗口提示「该爆发了」）

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`（指令栏区，读 battle state 破绽敌）
- Modify: `lib/shared/strings.dart`（`UiStrings.coopBurstPrompt = '破绽 · 该爆发了'`）
- Test: `test/features/battle/presentation/coop_burst_prompt_widget_test.dart`

- [ ] **Step 1: 写失败测** — battle state 中任一敌 `staggerTicksRemaining>0` 时，指令栏旁渲染提示文案 `UiStrings.coopBurstPrompt`；无破绽敌时不渲染。

- [ ] **Step 2: 跑测确认失败**。Expected: FAIL。

- [ ] **Step 3: 加提示 UI** — `battle_screen` 指令栏区加 `Consumer`/派生：`state.rightTeam.any((e)=>e.isAlive && e.staggerTicksRemaining>0)` 为真时显提示条（复用既有水墨提示样式）。仅屏上提示，不动 `interveneNow`/速度（守 §5.5）。

- [ ] **Step 4: 跑测确认通过**。Expected: PASS。

- [ ] **Step 5: 全量测 + analyze**。

- [ ] **Step 6: commit**
```bash
git add lib/features/battle/presentation/battle_screen.dart lib/shared/strings.dart test/features/battle/presentation/coop_burst_prompt_widget_test.dart
git commit -m "feat(第六阶段): 即放提示 - 破绽窗口开时指令栏提示「该爆发了」"
```

---

## Task 6: 职责 autoFill 倾向（lineage 角色软引导）

**Files:**
- Modify: `lib/features/cultivation/application/skill_loadout_resolver.dart`（autoFill 候选排序）
- Test: `test/features/cultivation/lineage_role_autofill_test.dart`

- [ ] **Step 1: 写失败测** — 大弟子（lineageRole/对应身份）autoFill 时，候选含破防技（defenseBreakPct>0）则优先填入装配槽；祖师优先高 powerMultiplier 爆发技；二弟子优先控制/内伤技。无对应技时回落现有 autoFill 等价（旧档 fallback 不倒退）。

- [ ] **Step 2: 跑测确认失败**。Expected: FAIL。

- [ ] **Step 3: 加角色倾向排序** — `skill_loadout_resolver` autoFill 候选在现有「流派过滤」后，按角色身份加一层稳定排序权重（破防/爆发/控制倾向）；不改可装配集合（不锁），仅改默认填充顺序。身份判定用 `Character` 的 `isFounder` / lineage 字段（实现时 grep 确认字段名）。

- [ ] **Step 4: 跑测确认通过**。Expected: PASS。

- [ ] **Step 5: 全量测 + analyze**（既有 autoFill 测须全绿）。

- [ ] **Step 6: commit**
```bash
git add lib/features/cultivation/application/skill_loadout_resolver.dart test/features/cultivation/lineage_role_autofill_test.dart
git commit -m "feat(第六阶段): 职责软引导 - autoFill 按 lineage 角色倾向破防/爆发/控制"
```

---

## Task 7: 破防技内容覆盖（skills.yaml 按流派）

**Files:**
- Modify: `data/skills.yaml`（刚猛震系技加 `defenseBreakPct` + 流派缺口补招）
- Modify: `lib/shared/strings.dart`（破防效果 GlossaryTip 释义）
- Test: `test/data/defense_break_coverage_test.dart`

- [ ] **Step 1: 写失败测** — 数据完整性:每个流派（刚猛/灵巧/阴柔）至少存在一个 `defenseBreakPct>0` 的可装配技（保证每流派玩家摸得到开窗手）。

- [ ] **Step 2: 跑测确认失败**。Expected: FAIL（暂无破防技）。

- [ ] **Step 3: 配破防技** — 刚猛震系技（现有，grep `gang` / 震 相关 skill id）加 `defenseBreakPct: 0.30`；灵巧/阴柔缺口各补 1 招带破防（沿既有 skill yaml 体例 + 文案进对应文案规范）。破防释义进 `UiStrings`（GlossaryTip 复用帮助系统）。

- [ ] **Step 4: 跑测确认通过**。Expected: PASS。

- [ ] **Step 5: 全量测 + analyze**（skills loader 红线测须全绿）。

- [ ] **Step 6: commit**
```bash
git add data/skills.yaml lib/shared/strings.dart test/data/defense_break_coverage_test.dart
git commit -m "feat(第六阶段): 破防技内容 - 三流派各覆盖开窗手 + 释义"
```

---

## Task 8: 红线测兜底（破绽窗口爆发极值不进百万）

**Files:**
- Modify: `test/balance/full_build_damage_redline_test.dart`（加破绽窗口爆发场景）
- Modify: `test/tools/balance_simulator_test.dart`（极值×破绽窗口诊断断言，如需）
- Test: 同上

- [ ] **Step 1: 写场景测** — 满强化神物极值 build，敌处破绽窗口（staggerTicksRemaining>0 + 减防 clamp 后）下放高倍率爆发技，calculator 探针伤害硬断言 `< 1000000`（不进百万 · §5.4 软线）。

- [ ] **Step 2: 跑测确认（应直接通过或暴露越界）** — 若超百万说明减防 clamp 漏，回查 Task 2 地板。Expected: PASS（< 1,000,000）。

- [ ] **Step 3: balance_simulator 极值场景**（如需）— 在既有极值×周目诊断加「破绽窗口」维度，断言真实战斗峰值不进百万。

- [ ] **Step 4: 全量测 + analyze**（0）。

- [ ] **Step 5: commit**
```bash
git add test/balance/full_build_damage_redline_test.dart test/tools/balance_simulator_test.dart
git commit -m "test(第六阶段): 红线兜底 - 破绽窗口爆发极值不进百万"
```

---

## 收尾（全部 task 后）

- [ ] 全量 `flutter test`（baseline 须 +新增测、零回归）+ `flutter analyze`（0），贴实测输出。
- [ ] 更新 `PROGRESS.md` 顶段（续25 · 第六阶段三人协同闭环）。
- [ ] 更新 `docs/spec/playability_phase2_backlog.md`：P2 协同深度勾选；记 Boss 协同窗口为续作 backlog。
- [ ] 合 main（ff）+ push。视觉验收:破绽题字/高亮/即放提示静态可截，集火/窗口时序单帧截不出 → 真机目检（沿 memory feedback_visual_acceptance）。

## 红线自查（每 task PR 前）

- §5.4：破防+踉跄减防 clamp 到 `interrupt_power_cap` 地板，刷新不叠加（取 max 不连乘），集火只改目标不改输出 → Task 8 硬断言不进百万。
- §5.5：即放提示/集火不改逻辑速度；AI 集火在自动战斗等价生效（在线=离线）。
- §5.6：数值全进 `numbers.yaml`，中文全进 `UiStrings`。
- §5.7：爽感走表现层（题字/高亮/提示），不走数值膨胀。
