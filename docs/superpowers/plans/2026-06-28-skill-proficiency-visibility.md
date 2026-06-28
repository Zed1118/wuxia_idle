# 招式熟练度可视化打磨 第一切片计划

**目标:** 在不改战斗公式、不调数值的前提下，让玩家在藏经阁武学库行里更清楚看见招式熟练度的当前效果、下一阶段效果与来源说明。

**分支:** `codex/skill-proficiency-visibility`

**验收标准:**
- 藏经阁 `SkillProficiencyRow` 继续复用 `StageProgressRow`。
- 当前效果同时展示全局阶段伤害倍率与已有 per-skill 效果（如伤害、冷却、破招力、破招窗口）。
- 下一阶段展示下一阶会获得的效果；最高阶显示已达化境。
- 来源短句说明熟练度来自战斗放招，不引入闭关、加速或新系统。
- 中文文案集中在 `UiStrings`，不散写到 widget。
- 不修改 `battle/` 公式、不修改 `data/numbers.yaml` 或技能数值。
- 跑 targeted test 与 touched-file analyze。

**任务切片:**
- [x] 读取 `AGENTS.md`、`CLAUDE.md §8.0`、`GDD.md §4.2-4.5 / §7.2`、`docs/spec/playability_phase2_backlog.md §十二`。
- [x] 创建并切到 `codex/skill-proficiency-visibility`。
- [x] 定位招式熟练度数据源与当前展示点。
- [x] 抽纯 Dart formatter：当前加成、下一阶、来源短句、进度字段。
- [x] 为 formatter 与藏经阁行补 targeted 测试。
- [x] 接入藏经阁 `SkillProficiencyRow`，文案走 `UiStrings`。
- [x] 跑 targeted test + touched-file analyze。
- [x] 小切片提交并更新恢复点。

## 当前恢复点

**状态:** 第一切片完成。

**最后完成:** 已新增 `SkillProficiencyFormatter.summarize`，藏经阁 `SkillProficiencyRow` 改为展示当前效果、下一阶效果与“战斗放招增长”来源短句；补了纯 formatter 测试与藏经阁 widget 测试。

**下一步:** 交主窗口检查；后续可继续扩到角色页或战报入口。

**已跑验证:** `DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/cultivation/skill_proficiency_formatter_test.dart test/features/cangjingge/cangjingge_widgets_test.dart`；`DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter analyze lib/features/cultivation/application/skill_proficiency_formatter.dart lib/features/cangjingge/presentation/skill_proficiency_row.dart lib/shared/strings.dart test/features/cultivation/skill_proficiency_formatter_test.dart test/features/cangjingge/cangjingge_widgets_test.dart`。

**阻塞项:** 无。
