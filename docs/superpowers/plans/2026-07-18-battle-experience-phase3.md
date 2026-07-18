# 战斗体验三期首切片实施计划

> 设计审计：`docs/spec/2026-07-18-battle-experience-phase3-audit.md`  
> 分支：`codex/battle-experience-phase3`  
> worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-experience-phase3`

## 1. 目标

修复明确远程的大招被 `cinematic` 分类提前截断、无法生成弹道的问题；保留大招题字、重击、SFX、命中特效和战斗结算语义。

## 2. 验收标准（CLAUDE.md §8.2）

- [x] **生产接线证据**：`battleActionTemplateFor` 由 `BattlePlaybackController.playAction` 消费，决定人物是否前冲及是否调用 `_spawnTrail`；大招题字/重击/SFX 继续按 `skill.type` 独立触发。
- [x] **targeted test**：`flutter test --no-pub test/features/battle/presentation test/features/battle/battle_playback_controller_test.dart`，213/213 通过。
- [x] **红线影响**：零数值、零 schema/saveVersion、零三系/在线离线/反主流影响；不新增 UI 文案或数值配置。
- [x] **UI/UX 视口**：`battle_tap_live` 1280×720、1440×900 visual smoke 无 overflow/exception/error。
- [x] **桌面语义**：未改按钮、focus、键盘、mouse cursor 或 semantics。
- [x] **残留风险**：AOE 同拍特效去重、全招式视觉分类审计与动态长战目检留后续独立切片。
- [x] **清洁度**：无 debug 日志、capture、build 产物或生成文件入 git 状态；提交信息使用中文动宾。

## 3. 任务切片

1. 新增失败测试：带 `flying_sword_art` 的单体大招应使用远程交付；无远程标记的大招仍为 `cinematic`。
2. 新增控制器失败测试：远程大招 `playAction` 后弹道队列增长。
3. 最小调整动作分类优先级，保持群攻与控制优先。
4. 跑 targeted tests、analyze、双视口 visual smoke。
5. 更新恢复点并提交稳定切片。

## 4. 当前恢复点

- **状态**：首切片完成并验证，准备冻结为 `[READY]` 稳定点。
- **最后完成**：远程标记判断移到 `cinematic` 之前；`flying_sword_art` 等单体远程大招现使用 projectile 交付，同时仍保留大招题字入口和既有命中特效。
- **下一步**：等待审查/合并；下一阶段优先做 AOE 同拍特效叠加审计，再决定是否实施去重。
- **已跑验证**：红态 2 条按预期失败；修复后直接相关 12/12、战斗 presentation 213/213 通过；`flutter analyze --no-pub` 0 issue；`battle_tap_live` 1280×720 / 1440×900 截图与日志均无 overflow/exception/error；`dart format`、`git diff --check` 通过。
- **阻塞项**：无。
