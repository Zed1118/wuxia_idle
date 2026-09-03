# P2 M7 第十五章内容迁移计划

## 结果合同

- 单一结果：把既有 `stage_15_01..05` 五关接入 typed production catalog、runtime binding 与 production encounter factory，第十五章工程水位 `0/5 → 5/5`。
- 固定分母：全主线 typed production catalog `66/105 → 71/105`；塔保持 `0/49`，legacy runtime retirement 仍开放，正式 Phase 2 保持 `1/10`。
- 实时基线：分支 `codex/p2-m7-ch15-content-migration-20260904` 建于 `main == origin/main == ede300351fea236d29cd6cf1a8e83403f59ef415`；该 SHA 的 CI run `33795062658` 为 `completed/success`。
- 关键阻塞：五关 StageDef、13 份正文（1 个 chapter 文件、12 个 stage 文件）与敌人图标完整，但 assignment、encounter、runtime binding 与 factory route 均缺失。
- 成本上限：只处理本章 5 条真实缺口；约 90 分钟无 `66 → 71` 可验证增量则停线重评。

## 审计选择依据

- 第十五章不是因顺序而选：五关 StageDef 与冻结 spec 均为单一对手，两个 Boss 的技能与相位边界完整，5 个敌人图标均在位，没有既有 typed route 或任务登记重叠。
- 第十三章既有 `stage_13_02` typed ecology 是 25 actor，正文明确为一名知客僧应战且路径受 M4 合同约束；继续留作独立审计，不与本批争夺 WIP。

## 非目标与保护边界

- 不改 `data/stages.yaml`、`data/numbers.yaml`、数值、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。
- 不处理第十三章、第十六章及以后章节，不启动 M8/M9，不新增玩法原语。
- 真人桌面、视觉、音频、手感与 Windows 继续 `DEFERRED`；自动化不代签。

## 验收清单

1. `15_01..05` 各有唯一 migrated assignment、encounter 与 runtime binding，`base_enemy_id` 严格等于对应 `StageDef.enemyTeam.single`。
2. 真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 完整消费；第十五章 `5/5`，全主线候选 `71/105`。
3. 五关按冻结 spec 保持单敌；15-01/02/03 使用 defeat-target，15-04/05 使用 commander 目标。
4. 15-04/05 姓名、原图、全技能、蓄力技、阶段与 `createActor` Boss 身份保持 StageDef 原值。
5. 测试先红，覆盖 exact actor/role、目标、factory 构建、流派、Boss identity 与五关 dynamic headless victory；至少两向 mutation 精确证红并恢复。
6. targeted、相邻回归、analyze、format、持锁全量、测试契约门与标准 Gate 如实记录；候选 READY 不冒充正式 M7/Phase 2。

## 当前恢复点

- 状态：第十五章生产接线已由候选 `f26ffc82` 经 no-ff merge `8976362a` 进入 `main` 与 `origin/main`，全主线集成水位为 `71/105`；merge exact-SHA CI run `33800564328` 为 `completed/success`。
- 已跑验证：有效初始 RED `0/6`；三向 mutation 分别精确转红 `1/1/2` 并按反向补丁与 SHA-256 恢复；第十五章 `6/6`；第十四/十五章 `12/12`；Phase 2 data `144/144`；mainline application `183/183`；analyze 0 issue；整仓 format `1728/0`；持锁全量 `5953/5953`、异常块 `0`；测试契约迁移 Gate `PASS`；标准 Gate 原始终行仅 `FAIL: test_deletions`，其余项 PASS；合入后定向/analyze/format/持锁全量及 exact-SHA CI 全部通过。
- 下一步：本治理尾进入 `origin/main` 并核 exact-SHA CI 后，只对下一非竞争章节做限时只读审计；第十三章 25-actor 合同冲突继续隔离。
- 挂账：真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。
