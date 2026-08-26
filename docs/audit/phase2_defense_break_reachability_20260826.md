# Phase 2 破防技可达性诊断（2026-08-26）

- 基线：`e4f0f1713023dba97c08b4d1e9843100e9e9a535`
- 结论：**可达，已知缺陷；本分支按 `[BLOCKED]` 等用户选处置方式。**

## 决定性证据

- `data/skills.yaml:243-257` 的真实 `skill_gangmeng_changlian_skill` 是 `powerSkill`，且 `defenseBreakPct: 0.30`。
- 实测同值命中共 3 处：`data/skills.yaml:257,307,357`。
- 生产 assembler 在 `lib/shared/battle_shared/player_combatant_snapshot_assembler.dart:121-139` 调真实 autoFill，并在 `:224-232` 将持久槽映射为战斗快照。
- **决定性可达点**：`lib/shared/battle_shared/combatant_skill_loadout.dart:37-44` 把 `main1/main2` 列入 `numericSlots`。
- `lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:1065-1080` 对该槽构造 `Phase0aNumericSkillBinding`。
- `lib/features/battle/application/phase0a/phase0a_numeric_skill_binding.dart:37-41` 精确因 `defenseBreakPct != 0` 抛 `StateError`。
- 决定性测试：`test/features/battle/application/phase0a/phase0a_defense_break_reachability_test.dart:41-122`；真 Isar 大弟子 + 真 YAML + 生产 snapshot assembler + 真 mapper。
- 因果修正：`skill_loadout.dart:104` 的 `!isFounder` 偏好不是必要条件；本测试的小成常练功默认排序已将破防技装入主修槽。

## 实际验证

- `flutter test --no-pub test/features/battle/application/phase0a/phase0a_defense_break_reachability_test.dart` → `1/1` 通过。
- `flutter test --no-pub test/features/battle/application/phase0a/phase0a_numeric_skill_binding_test.dart` → `4/4` 通过。
- `flutter test --no-pub test/features/battle/application/phase0a/phase0a_numeric_skill_mapping_test.dart` → `3/3` 通过。
- `flutter analyze --no-pub test/features/battle/application/phase0a/phase0a_defense_break_reachability_test.dart` → `0` issue。
- `flutter analyze` → 失败；根 package 误扫独立 `tools/phase0minus_probe` 子工程，实测 `1,943` 个既存缺包/URI issue。

## 候选处置（只列不选）

1. 实装 Phase 0A 破防开窗及 reducer 状态消费。
2. 从招式定义/schema 砍掉 `defenseBreakPct` 字段。
3. 在 autoFill 或 binding 层过滤该技能，阻止其进入 Phase 0A 数字槽。
