# 自动观战与点选干预界面分工计划

> 上游稳定点：`codex/battle-aoe-vfx-dedup@d647b7c0`  
> 分支：`codex/battle-mode-ui-distinction`  
> worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-mode-ui-distinction`

## 1. 目标

纯自动战斗不再显示七张「看起来可点、实际不能下发」的技能按钮，改为紧凑的三人招式轮转谱，直接表达真气与技能的可用、冷却、蓄气状态；允许点选的战斗继续完整展开武学案台与待发引导。

## 2. 现状与边界

- `BattleScreen` 两种模式当前都渲染同一个 `BottomBar`，差异仅是 `SkillCommandButton.onPressed` 门控。
- 纯自动模式仍占用 188px 高度，七张招式签主要呈现为禁用控件，违反已拍板 spec §5.5。
- 本切片只改表现与输入语义；不预测 AI 的精确下一招，不复制 `BattleAI` 决策逻辑，只展示真实可用/冷却/真气门槛。
- 战备行囊仍为紧凑只读预留位，不触及已否的「药品行囊自动补位」。

## 3. 验收标准（CLAUDE.md §8.2）

- [x] **生产接线**：`BattleScreen` 依 `allowPlayerIntervention` 选择只读轮转谱或完整武学案台。
- [x] **targeted test**：自动模式显示 3 人真气与招式状态、无技能按钮，高度小于点选案台；点选模式保持 7 槽及交互回归。
- [x] **红线影响**：不改 AI、tick、伤害、真气变化、冷却、胜负、numbers、schema/saveVersion；中文只进 `UiStrings`。
- [x] **UI/UX**：`battle_tap_live` 与 `battle_inner_demon_stage` 均完成 1280×720 / 1440×900 visual smoke，无 overflow/exception/error。
- [x] **桌面语义**：轮转谱是只读 semantics，不伪装 button/focus/mouse cursor；点选技能签现有键盘与鼠标语义不变。
- [x] **残留风险**：单人/两人/三人队已测；每人只显示排序后前 3 个非普攻招式，超长招名用省略保布局。残留为未直接展示第 4–7 招，但不宣称精确 AI 下一招。
- [x] **清洁度**：无生成物、capture、日志误提交；中文动宾提交并冻结 `[READY]`。

## 4. 实施切片

1. 写失败 widget test，锁住自动/点选两种底栏的结构、高度与交互语义。
2. 实现只读 `AutoRotationBar`：三人名签、真气气脉、非普攻招式的可用/冷却/蓄气摘要。
3. 在 `BattleScreen` 生产底栏分流，不改原 `BottomBar` 点选路径。
4. 跑 targeted、presentation、analyze 与双模式双视口目检，更新恢复点并冻结。

## 5. 当前恢复点

- **状态**：完成，待 `[READY]` 冻结。
- **最后完成**：纯自动底栏由 188px 完整案台改为 116px 只读轮转谱，分角色展示真气与可用/冷却/蓄气；点选模式原七签案台与待发交互不变。
- **下一步**：从本分支 tip 创建「战斗节奏与干预价值诊断探针」切片。
- **已跑验证**：红测实证自动转谱不存在；修复后案台/点选 38/38，战斗 presentation + 播放控制器 218/218；`flutter analyze --no-pub` 0 issue；macOS debug build 成功（仅上游 audioplayers Swift warning）；自动/点选两模式在 1280×720 / 1440×900 真实窗口目检均无 overflow/exception/error。
- **阻塞项**：无。
