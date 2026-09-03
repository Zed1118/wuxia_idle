# P2 M7 第十二章内容迁移计划

## 结果合同

- 单一结果：把既有 `stage_12_01..05` 五关接入 typed production catalog、runtime binding 与 production encounter factory，第十二章工程水位 `0/5 → 5/5`。
- 固定分母：全主线 typed production catalog `56/105 → 61/105`；塔保持 `0/49`，legacy runtime retirement 仍开放，正式 Phase 2 保持 `1/10`。
- 实时基线：分支 `codex/p2-m7-ch12-content-migration-20260904` 建于 `main == origin/main == 273c0fcb55029df32a6d0fa16deb41058b37291c`；该 SHA 的 CI run `33775826982` 为 `completed/success`。
- 关键阻塞：五关 StageDef 与 13 份正文完整，但 assignment、encounter、runtime binding 与 factory route 均缺失。
- 成本上限：只处理本章 5 条真实缺口；约 90 分钟无 `56 → 61` 可验证增量则停线重评。

## 审计选择依据

- 第十二章不是因顺序而选：五关正文和 StageDef 均把战斗冻结为单一对手，两个 Boss 的技能与相位完整，没有既有 typed route 重叠，可用第十一章已验证的行为壳一次关闭 5 门。
- 第十三章虽然只缺 4 门，但既有 `stage_13_02` typed ecology 是 25 actor，正文明确为一名知客僧应战且路径受 M4 合同约束；继续留作独立审计，不与本批争夺 WIP。

## 非目标与保护边界

- 不改 `data/stages.yaml`、`data/numbers.yaml`、数值、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。
- 不处理第十三章及以后章节，不启动 M8/M9，不新增玩法原语。
- 真人桌面、视觉、音频、手感与 Windows 继续 `DEFERRED`；自动化不代签。

## 验收清单

1. `12_01..05` 各有唯一 migrated assignment、encounter 与 runtime binding，`base_enemy_id` 严格等于对应 `StageDef.enemyTeam.single`。
2. 真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 完整消费；第十二章 `5/5`，全主线候选 `61/105`。
3. 五关按正文冻结单敌；12-01/02/03 使用 defeat-target，12-04/05 使用 commander 目标。
4. 12-04/05 姓名、原图、全技能、蓄力技、阶段与 `createActor` Boss 身份保持 StageDef 原值。
5. 测试先红，覆盖 exact actor/role、目标、factory 构建、流派、Boss identity 与五关 dynamic headless victory；至少两向 mutation 精确证红并恢复。
6. targeted、相邻回归、analyze、format、持锁全量、测试契约门与标准 Gate 如实记录；候选 READY 不冒充正式 M7/Phase 2。

## 当前恢复点

- 状态：第十二章生产接线和三向变异恢复完成，候选水位 `61/105`；主线集成水位仍为 `56/105`。
- 已跑验证：有效 RED `0/6`；定向 `6/6`；第十一/十二章 `12/12`；Phase 2 data `132/132`；mainline application `183/183`；测试契约迁移门 `PASS`。
- 下一步：完成 analyze、format、持锁全量、治理证据与 exact-tip 标准 Gate；未发生的 merge、push 与 CI 不预写。
- 挂账：真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。
