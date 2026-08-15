# Character Attribute Roles Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在不迁移旧存档属性值的前提下，统一体魄、悟性、身法、机缘的实际职责，并让战斗、成长、奇遇和角色面板使用同一套数据驱动规则。

**Architecture:** 新增无状态 `AttributeEffectPolicy` 与强类型 `AttributeEffectRules`，所有属性换算集中在纯函数层；`NumbersConfig` 只负责从 `numbers.yaml` 严格解析规则。存档继续保存原始属性和真实招式使用次数，属性加成仅在伤势生成、修炼增量、熟练度展示/战斗快照和奇遇判定边界派生，避免 schema 与旧档迁移。

**Tech Stack:** Flutter/Dart、Riverpod、Isar Community、YAML、flutter_test

**Workspace:** `/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/character-attribute-roles`

**Branch / Baseline:** `codex/character-attribute-roles` / `b44a8942`

---

## Task 1: 建立属性规则的单一真相源

**Files:**
- Create: `lib/core/domain/attribute_effect_policy.dart`
- Modify: `lib/data/numbers_config.dart`
- Modify: `data/numbers.yaml`
- Create: `test/core/domain/attribute_effect_policy_test.dart`
- Modify: `test/data/numbers_config_red_lines_test.dart`

**Step 1: Write the failing tests**

覆盖以下精确锚点：体魄 5/10/15 对 8 小时重伤得到 8/7.2/6.4 小时；悟性 5/10/15 的成长倍率为 1/1.1/1.2；有效熟练度使用次数向下取整；心法修炼使用累计差值计算；武学领悟概率使用悟性，普通奇遇概率使用机缘；缺失或非法 `attribute_effects` 配置抛出 `FormatException`。

```dart
expect(policy.heavyInjuryHours(baseHours: 8, constitution: 10), 7.2);
expect(policy.growthMultiplier(enlightenment: 15), 1.2);
expect(policy.effectiveUsageCount(rawUses: 29, enlightenment: 10), 31);
expect(policy.effectiveProgressDelta(rawBefore: 9, rawDelta: 1, enlightenment: 10), 2);
expect(policy.encounterProbability(base: .5, type: EncounterType.techniqueInsight,
  attributes: attrs), .625);
```

Run: `flutter test test/core/domain/attribute_effect_policy_test.dart test/data/numbers_config_red_lines_test.dart --no-pub`

Expected: FAIL because policy/rules and YAML section do not exist.

**Step 2: Implement the minimum policy and strict parser**

新增：

```dart
final class AttributeEffectRules {
  final int referenceValue;
  final double heavyInjuryReductionPerPoint;
  final double heavyInjuryReductionMax;
  final double growthBonusPerPoint;
  final double growthBonusMax;
  final double insightProbabilitySensitivity;
  final double fortuneProbabilitySensitivity;
  final int specialChoiceRequired;
}

final class AttributeEffectPolicy {
  const AttributeEffectPolicy(this.rules);
  // pure calculation methods only
}
```

`NumbersConfig.fromYaml` 对生产配置执行必填、类型、正数和上限区间校验；测试 fixture 必须由 fixture 自己补齐配置，不在生产解析器静默兜底。

Run the same test command; expected PASS. Then run `dart format` and `git diff --check`.

**Step 3: Commit**

```bash
git add lib/core/domain/attribute_effect_policy.dart lib/data/numbers_config.dart data/numbers.yaml test/core/domain/attribute_effect_policy_test.dart test/data/numbers_config_red_lines_test.dart
git commit -m "实现角色属性效果规则"
```

## Task 2: 接入体魄重伤与身法暴击职责

**Files:**
- Modify: `lib/features/injury/application/injury_service.dart`
- Modify: `lib/features/battle/domain/derived_stats.dart`
- Modify: `data/numbers.yaml`
- Modify: `test/features/injury/application/injury_service_test.dart`
- Modify: `test/features/battle/application/battle_resolution_test.dart`
- Modify: `test/combat/derived_stats_test.dart`

**Step 1: Write RED tests**

验证重伤仅在新伤/再伤生成时按体魄缩短，既有恢复倒计时不受后续属性变化影响；验证身法 0/5/15 的基础暴击均为 7.5%，灵巧流派及祖师加成仍在末端叠加并 clamp。

Run: `flutter test test/features/injury/application/injury_service_test.dart test/combat/derived_stats_test.dart test/features/battle/application/battle_resolution_test.dart --no-pub`

Expected: FAIL on duration and critical anchors.

**Step 2: Implement**

`applyBattleInjuries` 在调用 `applyHeavyInjury` 前读取角色体魄并通过 policy 计算新时长；不修改任何恢复服务。`critical.base_rate` 改为 `0.075`，`agility_per_point_rate` 改为 `0.0`，代码公式移除身法项但保留流派与祖师加成。

Run the same tests; expected PASS.

**Step 3: Commit**

```bash
git add lib/features/injury/application/injury_service.dart lib/features/battle/domain/derived_stats.dart data/numbers.yaml test/features/injury/application/injury_service_test.dart test/features/battle/application/battle_resolution_test.dart test/combat/derived_stats_test.dart
git commit -m "统一体魄重伤与身法暴击规则"
```

## Task 3: 接入悟性的心法修炼与招式熟练度

**Files:**
- Modify: `lib/features/cultivation/application/cultivation_service.dart`
- Modify: `lib/features/cultivation/application/insight_exchange_service.dart`
- Modify: `lib/features/battle/application/battle_resolution.dart`
- Modify: `lib/features/battle/domain/battle_state.dart`
- Modify: `lib/features/battle/domain/damage_calculator.dart`
- Modify: `lib/features/technique_panel/presentation/technique_panel_screen.dart`
- Modify: `lib/features/character_panel/presentation/character_panel_screen.dart`
- Modify: `lib/features/cangjingge/presentation/cangjingge_screen.dart`
- Modify: `lib/features/baike/application/martial_codex_provider.dart`
- Modify: `test/features/cultivation/application/cultivation_service_test.dart`
- Modify: `test/features/cultivation/application/insight_exchange_service_test.dart`
- Modify: `test/features/battle/application/battle_resolution_test.dart`
- Modify: `test/features/battle/proficiency_in_battle_test.dart`

**Step 1: Write RED tests**

覆盖：悟性 10 时真实使用 10 次仍只存 10 次，但心法修炼累计增加 11；分批 9+1 与一次 10 的最终修炼度一致；熟练度战斗快照和界面展示使用有效次数 11；悟性凝练 50 点得到 55 修炼度；辅修和独立招式只记录真实次数。

Run: `flutter test test/features/cultivation/application/cultivation_service_test.dart test/features/cultivation/application/insight_exchange_service_test.dart test/features/battle/application/battle_resolution_test.dart test/features/battle/proficiency_in_battle_test.dart --no-pub`

Expected: FAIL because enlightenment is not wired.

**Step 2: Implement cumulative growth without save migration**

`recordSkillUsage` 接受悟性或 policy 参数，在增加原始使用次数前后计算：

```dart
effectiveDelta = floor((rawBefore + delta) * multiplier)
  - floor(rawBefore * multiplier);
```

战斗结算从角色读取悟性；凝练兑换对本次兑换量使用 `floor(spend * ratio * multiplier)`；战斗快照、伤害计算和所有玩家可见熟练度入口统一把 raw uses 通过 policy 派生，禁止回写有效次数。

Run targeted tests and `flutter analyze --no-pub`; expected PASS.

**Step 3: Commit**

```bash
git add lib/features/cultivation lib/features/battle lib/features/technique_panel lib/features/character_panel lib/features/cangjingge lib/features/baike test/features/cultivation test/features/battle
git commit -m "让悟性统一影响修炼与熟练度"
```

## Task 4: 区分悟性领悟与机缘奇遇概率

**Files:**
- Modify: `lib/features/encounter/application/encounter_service.dart`
- Modify: `lib/features/encounter/application/encounter_service_providers.dart`
- Modify: `lib/features/encounter/presentation/encounter_hook.dart`
- Modify: `lib/features/seclusion/application/seclusion_service_providers.dart`
- Modify: `test/features/encounter/application/encounter_service_test.dart`

**Step 1: Write RED tests**

技术领悟事件 `base * (1 + enlightenment / 20)`；普通/节日/机缘事件 `base * (1 + fortune / 20)`；既有 `fortuneRequired` 触发门槛继续按机缘判断；概率最终限制在 0..1。

Run: `flutter test test/features/encounter/application/encounter_service_test.dart --no-pub`

Expected: techniqueInsight case FAIL because it currently uses fortune.

**Step 2: Implement through policy**

删除 service 内重复概率公式，统一调用 `AttributeEffectPolicy.encounterProbability`；providers 只注入完整 rules，不再散传 sensitivity。

Run targeted test; expected PASS.

**Step 3: Commit**

```bash
git add lib/features/encounter lib/features/seclusion/application/seclusion_service_providers.dart test/features/encounter/application/encounter_service_test.dart
git commit -m "区分悟性领悟与机缘奇遇概率"
```

## Task 5: 增加四个机缘选项与可访问的锁定交互

**Files:**
- Modify: `lib/data/encounter_event_loader.dart`
- Modify: `lib/features/encounter/presentation/encounter_dialog.dart`
- Modify: `lib/features/encounter/presentation/encounter_hook.dart`
- Modify: `lib/features/debug/presentation/encounter_debug_picker.dart`
- Modify: `lib/shared/strings.dart`
- Modify: `data/events/cha_ting_dui_ju.yaml`
- Modify: `data/events/du_ke_wen_dao.yaml`
- Modify: `data/events/feng_xue_gu_dian.yaml`
- Modify: `data/events/ye_du_gu_chuan.yaml`
- Modify: `test/features/encounter/domain/encounter_yaml_test.dart`
- Create: `test/features/encounter/presentation/encounter_dialog_test.dart`

**Step 1: Write RED parser/widget tests**

`EncounterChoice.fortuneRequired` 能解析；机缘不足时选项仍显示、按钮禁用、标签显示“机缘 8”、语义节点为 disabled，键盘焦点不能激活；机缘达标时返回既有 outcome ID。

Run: `flutter test test/features/encounter/domain/encounter_yaml_test.dart test/features/encounter/presentation/encounter_dialog_test.dart --no-pub`

Expected: FAIL because schema/UI has no lock support.

**Step 2: Implement schema, data, and UI**

新增可空 `fortune_required`。四个事件分别复用：`defend_draw`、`gain_wisdom`、`get_divination`、`negotiate`，要求机缘 8。`showEncounterDialog` 接受当前机缘，锁定态保留可读文案但 `onPressed: null`，采用现有水墨按钮组件与响应式滚动布局。

Run tests and event reference validation; expected PASS.

**Step 3: Commit**

```bash
git add lib/features/encounter lib/features/debug/presentation/encounter_debug_picker.dart lib/shared/strings.dart data/events test/features/encounter
git commit -m "增加机缘选项与锁定提示"
```

## Task 6: 重排角色面板的有效战斗属性

**Files:**
- Modify: `lib/features/character_panel/presentation/character_panel_screen.dart`
- Modify: `lib/shared/strings.dart`
- Modify: `test/features/character_panel/presentation/character_panel_screen_test.dart`
- Modify: `test/features/character_panel/presentation/character_panel_screen_edge_test.dart`

**Step 1: Write RED widget tests**

首行显示气血、内力、实战装备攻击；次行显示速度、基础防御、暴击、闪避；不在常驻面板显示气；窄宽度无 overflow，数值来自 `DerivedStats` 与境界防御配置。

Run: `flutter test test/features/character_panel/presentation/character_panel_screen_test.dart test/features/character_panel/presentation/character_panel_screen_edge_test.dart --no-pub`

Expected: FAIL on labels/layout.

**Step 2: Implement responsive layout**

聚合全身装备的 `effectiveEquipmentAttack`；基础防御使用角色当前境界的 `defenseRateByTier`；使用 `Wrap`/约束宽度实现 3+4 卡片响应式排列，保留现有 semantics 与鼠标提示。

Run widget tests and analyze; expected PASS.

**Step 3: Commit**

```bash
git add lib/features/character_panel/presentation/character_panel_screen.dart lib/shared/strings.dart test/features/character_panel
git commit -m "优化角色面板战斗属性展示"
```

## Task 7: 同步设计文档和玩家文案

**Files:**
- Modify: `GDD.md`
- Modify: `CLAUDE.md`
- Modify: `lib/shared/strings.dart`
- Modify: `docs/superpowers/specs/2026-07-13-character-attribute-roles-design.md` only if implementation facts require clarification

**Step 1: Update truth sources**

明确体魄减重伤、悟性成长/领悟、身法速度/闪避、机缘普通奇遇/特殊选项；删除“机缘影响商店折扣”和“身法影响暴击”的冲突口径；记录不迁移旧属性值和不改变在线/离线等价性。

**Step 2: Validate no contradictory literal text remains**

Run: `rg -n "商店折扣|身法.*暴击|暴击.*身法|fortune_sensitivity" GDD.md CLAUDE.md lib data test`

Expected: only intentional historical/config references remain and are explained.

**Step 3: Commit**

```bash
git add GDD.md CLAUDE.md lib/shared/strings.dart docs/superpowers/specs/2026-07-13-character-attribute-roles-design.md
git commit -m "统一角色属性设计口径"
```

## Task 8: 全量验收、视觉检查和任务冻结

**Files:**
- Modify: `PROGRESS.md` if required by `CLAUDE.md §8.0`
- Modify/Create: recovery marker required by the project protocol

**Step 1: Targeted regression**

```bash
flutter test test/core/domain/attribute_effect_policy_test.dart test/combat/derived_stats_test.dart test/features/injury test/features/cultivation test/features/encounter test/features/character_panel --no-pub
```

Expected: all PASS.

**Step 2: Static, balance, migration, and full-suite checks**

```bash
flutter analyze --no-pub
flutter test test/data/numbers_config_red_lines_test.dart test/tools/balance_simulator_test.dart test/data/isar_setup_test.dart --no-pub
flutter test --no-pub
git diff --check
```

Expected: 0 analyzer issues, all tests PASS, no whitespace errors. If coverage ratchet is configured, run the repository’s documented coverage command and keep coverage at or above the current threshold.

**Step 3: Visual verification**

启动 macOS 调试应用，检查角色面板宽/窄窗口、四项属性说明，以及奇遇选项的可用/锁定/键盘焦点状态；保存必要截图证据，不修改发布环境。

**Step 4: §8.2 acceptance checklist**

- [ ] `docs/spec/rejected_task_registry.md` 无命中禁做项。
- [ ] 四项属性职责与已批准设计逐条一致。
- [ ] 旧存档属性值、schema、saveVersion 均未改变。
- [ ] 真实招式使用次数未被悟性倍率污染。
- [ ] 在线与离线使用同一属性 policy。
- [ ] 数值红线、事件引用、全量测试、静态分析全部通过。
- [ ] 文案无 Dart 中文硬编码新增；数值无业务常量硬编码新增。
- [ ] 工作树只包含本任务文件，未覆盖用户既有改动。
- [ ] 恢复点、计划状态、提交历史完整。

**Step 5: Freeze commit**

```bash
git add PROGRESS.md docs
git commit -m "完成角色属性职责优化验收"
git status --short
git log --oneline --decorate -10
```

Expected: clean worktree. Do not push until the user explicitly authorizes an external action.

## 当前恢复点（2026-07-13）

- **状态**：全部 8 个任务已完成，分支待评审/合并。
- **最后完成**：macOS 实窗检查角色面板；覆盖率全量与 ratchet 通过。
- **下一步**：由用户选择本地合并、推送建 PR 或保留分支。
- **已跑验证**：`flutter analyze --no-pub` 0 issue；属性相关 targeted 427 绿；数值红线/平衡模拟/旧档迁移守门 17 绿；`flutter test --no-pub` 3867/3867；`flutter test --coverage --no-pub` 3867/3867；行覆盖率 81.62% ≥ 81.25%；`git diff --check` 通过；macOS debug 实窗角色面板无裁切/overflow。
- **阻塞项**：无。未推送、未合并，未修改 schema/saveVersion。
