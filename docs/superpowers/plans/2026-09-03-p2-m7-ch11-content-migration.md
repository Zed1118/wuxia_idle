# P2 M7 第十一章内容迁移计划

## 结果合同

- 单一结果：把既有 `stage_11_01..05` 五关接入 typed production catalog、runtime binding 与 production encounter factory，第十一章工程水位 `0/5 → 5/5`。
- 固定分母：全主线 typed production catalog `51/105 → 56/105`；塔保持 `0/49`，legacy runtime retirement 仍开放，正式 Phase 2 保持 `1/10`。
- 实时基线：分支 `codex/p2-m7-ch11-content-migration-20260903-cn` 建于 `main == origin/main == 0172263ed25dba8ad83fa75de3c766d8a87e6c15`；该 SHA 的 CI run `33760236939` 为 `completed/success`。
- 关键阻塞：五关 StageDef 与 13 份正文完整，但 assignment、encounter、runtime binding 与 factory route 均缺失。
- 成本上限：只处理本章 5 条真实缺口；约 90 分钟无 `51 → 56` 可验证增量则停线重评。

## 审计选择依据

- 第十一章并非按序默认选择：现存五关正文均把战斗主体写成单一对手，StageDef、Boss、技能与叙事完整，且没有既有 typed encounter 重叠，能以最低语义风险一次关闭 5 门。
- 第十三章虽只缺 4 门，但既有 `stage_13_02` typed ecology 为 25 actor，而正文明确是一名知客僧应战；该路径还受 M4 合同约束，留待独立审计，不与本批争夺 WIP。

## 非目标与保护边界

- 不改 `data/stages.yaml`、`data/numbers.yaml`、数值、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。
- 不处理第十二、十三章，不启动 M8/M9，不新增玩法原语。
- 真人桌面、视觉、音频、手感与 Windows 继续 `DEFERRED`；自动化不代签。

## 验收清单

1. `11_01..05` 各有唯一 migrated assignment、encounter 与 runtime binding，`base_enemy_id` 严格等于对应 `StageDef.enemyTeam.single`。
2. 真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 完整消费；第十一章 `5/5`，全主线候选 `56/105`。
3. 五关按正文冻结单敌；11-01/02/03 使用 defeat-target，11-04/05 使用 commander 目标。
4. 11-04/05 名称、原图、全技能、蓄力技、阶段与 `createActor` Boss 身份保持 `StageDef` 原值。
5. 测试先红，覆盖 exact actor/role、目标、factory 构建、流派、Boss identity 与五关 dynamic headless victory；至少两向 mutation 精确证红并恢复。
6. targeted、相邻回归、analyze、format、持锁全量、测试契约门与标准 Gate 如实记录；候选 READY 不冒充正式 M7/Phase 2。

## 任务切片

1. 添加第十一章 6 项生产合同并记录有效 RED。
2. 增加五条 assignment、一个 encounter source 与五组 runtime binding，只复用既有 typed 生态。
3. 跑 targeted、语义变异、相邻回归和批末验证。
4. 刷新治理证据；仅在集成授权边界持续成立时受控合入并核 exact-SHA CI。

## 当前恢复点

- 状态：第十一章候选已完成生产接线、变异恢复与批末自动化验证；main 集成水位仍为 `51/105`，候选为 `56/105`。
- 已跑验证：有效 RED `0/6`；定向 `6/6`；第十/十一章 `12/12`；Phase 2 data `126/126`；mainline application `183/183`；analyze/format 通过；持锁全量 `5935/5935`、异常块 `0`；测试契约迁移门 `PASS`。
- 下一步：提交当前治理证据，运行 exact-tip 标准 Gate；未发生的 merge、push 与 CI 不预写。
- 挂账：真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。
