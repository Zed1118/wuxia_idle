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
- [ ] 抽纯 Dart formatter：当前加成、下一阶、来源短句、进度字段。
- [ ] 为 formatter 与藏经阁行补 targeted 测试。
- [ ] 接入藏经阁 `SkillProficiencyRow`，文案走 `UiStrings`。
- [ ] 跑 targeted test + touched-file analyze。
- [ ] 小切片提交并更新恢复点。

## 当前恢复点

**状态:** 进行中。

**最后完成:** 已读指定文档，已在 worktree 创建并切到 `codex/skill-proficiency-visibility`；CodeGraph 未初始化，已改用 `rg`/直接读文件定位。确认熟练度数据源为 `SkillProficiencyConfig`、`SkillDef.proficiency` 与 `SkillProficiency` 纯域，当前展示点为藏经阁 `SkillProficiencyRow`。

**下一步:** 新增纯 formatter，接入 `SkillProficiencyRow`，补 formatter/widget 测试。

**已跑验证:** 文档/代码定位命令；尚未跑测试。

**阻塞项:** 无。
