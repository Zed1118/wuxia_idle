# P2 M7 第九章内容迁移计划

## 结果合同

- 单一结果：把已存在的 `stage_09_01..05` 五关接入 typed production catalog、runtime binding 与 production encounter factory，第九章工程水位 `0/5 → 5/5`。
- 固定分母：全主线 typed production catalog `41/105 → 46/105`；塔保持 `0/49`，legacy runtime retirement 仍开放，正式 Phase 2 仍 `1/10`。
- 实时基线：分支 `codex/p2-m7-ch9-content-migration-20260903` 建于 `main == origin/main == 972bc6d413b7c7d2dbf911467b076bdb5c4781b7`；exact-SHA CI run `33714277377` 为 `completed/success`。
- 关键阻塞：五关 StageDef、冻结 A 案和 13 份正文均完整，但 assignment、encounter 与 runtime binding 均缺失；09-01/02 只写“几个人/几条人影”，须在开工前保守冻结有限角色集合。
- 成本上限：后续实施只处理这 5 条真实缺口；约 90 分钟无 `41 → 46` 可验证增量则停线重评。

## 非目标与保护边界

- 不改 `data/stages.yaml`、`data/numbers.yaml`、数值、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。
- 不改 Isar、`schemaVersion`、`saveVersion`，不处理 `stage_02_05` 历史风险，不启动 M8/M9，不新增玩法原语。
- 真人桌面、视觉、音频、手感与 Windows 继续 `DEFERRED`；自动化不代签。

## CLAUDE.md §8.2 验收清单

1. `09_01..05` 各有唯一 migrated assignment、encounter 与 runtime binding，`base_enemy_id` 严格等于对应 `StageDef.enemyTeam.single`。
2. 真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 完整消费；第九章 `5/5`，全主线候选 `46/105`。
3. 09-01/02 先按正文保守冻结角色集合；09-03 为单一蜃楼幻影，09-04/05 为单 Boss，禁止凭空扩编。
4. 两场 Boss 的名称、原图、全技能、蓄力技、阶段与 `createActor` 身份保持 `StageDef` 原值；不改基础数值/技能/文案。
5. 测试先红，覆盖 exact actor set、目标、factory 构建、Boss identity 与五关 dynamic headless victory；至少两向 mutation 精确证红并反向还原。
6. targeted、相邻回归、analyze、format、持锁全量、测试契约门与标准 Gate 如实记录；最终 tip `[READY]`、worktree clean，候选不冒充正式 M7/Phase 2。

## 任务切片

1. 独立复核 13 份正文与 StageDef，冻结五关角色/目标边界。
2. 先加第九章生产合同测试并记录有效 RED。
3. 增加五条 assignment、一个 encounter source 与五组 runtime binding，只复用现有 typed 生态。
4. 运行 targeted，修正 factory/objective/dynamic host 真实缺口；完成 mutation 与精确恢复。
5. 跑相邻回归、analyze/format、批末持锁全量及 Gate，刷新治理证据后冻结 READY。

## 当前恢复点

- 状态：第九章五条 typed production 路由已形成工程候选；主线候选水位 `46/105`，尚未独立评审或进入 main。
- 最后完成：冻结正文角色数 `4/3/1/1/1`，接通 assignment、encounter、runtime binding、真实 factory/objective/reducer；两名 Boss 保留 StageDef 全身份。
- 下一步：冻结 `[READY]` exact tip，执行标准 Gate；随后由独立复核决定是否受控集成，不在本候选内自合并或 push。
- 已跑验证：初始 RED `0/6`；三向 mutation 均命中并按 SHA-256 恢复；Ch8/Ch9 各 `6/6`、Phase 2 data `114/114`、mainline application `183/183`、analyze 0 issue、format `1723/0`、持锁全量 `5923/5923`；测试契约门 `PASS`。
- 阻塞项：正式 M7 仍需主线余下内容、塔 `49` 条、legacy runtime retirement 与真人/视觉/音频/手感/Windows 验收；本候选还需独立复核和集成。
