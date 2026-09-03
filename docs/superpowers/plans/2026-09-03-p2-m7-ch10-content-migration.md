# P2 M7 第十章内容迁移计划

## 结果合同

- 单一结果：把既有 `stage_10_01..05` 五关接入 typed production catalog、runtime binding 与 production encounter factory，第十章工程水位 `0/5 → 5/5`。
- 固定分母：全主线 typed production catalog `46/105 → 51/105`；塔保持 `0/49`，legacy runtime retirement 仍开放，正式 Phase 2 保持 `1/10`。
- 实时基线：分支 `codex/p2-m7-ch10-content-migration-20260903` 建于 `main == origin/main == 7c5517e8863a19f10adfd53735e710a61759675b`；第九章治理尾 exact-SHA CI run `33729258734` 为 `completed/success`。
- 关键阻塞：五关 StageDef 与 13 份正文完整，但 assignment、encounter、runtime binding 与 factory route 均缺失。
- 成本上限：只处理本章 5 条真实缺口；约 90 分钟无 `46 → 51` 可验证增量则停线重评。

## 审计选择依据

- 现查主线水位逐章为 Ch1–Ch9 全部 `5/5`，Ch10 `0/5`，Ch11/12、Ch14–21 也为 `0/5`，Ch13 为 `1/5`。
- 第十章不是按序默认选择：它已具备完整 StageDef、13 份正文、单链前置、两名 Boss 身份和既有可复用门派/军阵生态，且五关正文均明确为单敌，语义决策面最小、可一次闭合完整章节。

## 非目标与保护边界

- 不改 `data/stages.yaml`、`data/numbers.yaml`、数值、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。
- 不改 Isar、`schemaVersion`、`saveVersion`，不处理 `stage_02_05` 历史风险，不启动 M8/M9，不新增玩法原语。
- 真人桌面、视觉、音频、手感与 Windows 继续 `DEFERRED`；自动化不代签。

## CLAUDE.md §8.2 验收清单

1. `10_01..05` 各有唯一 migrated assignment、encounter 与 runtime binding，`base_enemy_id` 严格等于对应 `StageDef.enemyTeam.single`。
2. 真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 完整消费；第十章 `5/5`，全主线候选 `51/105`。
3. 五关均按正文冻结单敌，不凭空扩编；10-01/02/03 使用 defeat-target，10-04/05 使用 commander 目标。
4. 10-04/05 名称、原图、全技能、蓄力技、阶段与 `createActor` Boss 身份保持 `StageDef` 原值；不改基础数值/技能/正文。
5. 测试先红，覆盖 exact actor set、目标、factory 构建、流派/行为壳、Boss identity 与五关 dynamic headless victory；至少两向 mutation 精确证红并反向还原。
6. targeted、相邻回归、analyze、format、持锁全量、测试契约门与标准 Gate 如实记录；最终 tip `[READY]`、worktree clean，候选不冒充正式 M7/Phase 2。

## 任务切片

1. 只读复核 13 份正文、StageDef、现有生态与生产消费者，冻结五关单敌/目标边界。
2. 先加第十章生产合同测试并记录有效 RED。
3. 增加五条 assignment、一个 encounter source 与五组 runtime binding，只复用现有 typed 生态。
4. 运行 targeted 并修正 factory/objective/dynamic host 真实缺口；完成 mutation 与精确恢复。
5. 跑相邻回归、analyze/format、批末持锁全量及 Gate，刷新治理证据后冻结 READY、受控合入并核 exact-SHA CI。

## 当前恢复点

- 状态：第十章生产迁移与主代理合入复核已完成，候选水位 `51/105`；尚未进入 `main`，不计集成水位。
- 最后完成：修复 10-05 守拙翁从轻功突进型偏离到军阵守势型，并以精确角色契约防回归；修复后定向 `6/6`、全量 `5929/5929`。
- 下一步：冻结 `[READY]` tip，运行测试迁移门与标准 Gate，然后受控合入并核对 exact-SHA CI。
- 已跑验证：有效 RED `0/6`；定向 `6/6`；Phase 2 data `120/120`；mainline application `183/183`；analyze 无问题；format `1724 files (0 changed)`；修复后持锁全量 `5929/5929`、异常块 `0`、锁已释放；测试迁移门 `PASS`。
- 阻塞项：当前无须人类拍板；真人桌面、视觉、音频、手感与 Windows 按用户要求挂账。
