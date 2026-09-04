# P2 M7 第十七章内容迁移计划

## 结果合同

- 单一结果：把既有 `stage_17_01..05` 五关接入 typed production catalog、runtime binding 与 production encounter factory，第十七章工程水位 `0/5 → 5/5`。
- 固定分母：全主线 typed production catalog `76/105 → 81/105`；塔保持 `0/49`，legacy runtime retirement 仍开放，正式 Phase 2 保持 `1/10`。
- 实时基线：分支 `codex/p2-m7-ch17-content-migration-20260904` 建于 `main == origin/main == a4d8cd954ad9831f2eedee0471b9e472dc1e1c48`；该 SHA 的 CI run `33815818040` 为 `completed/success`。
- 关键阻塞：五关 StageDef、12 份正文与 5 个敌人图标完整，但 assignment、encounter、runtime binding 与 factory route 均缺失。
- 成本上限：只处理本章 5 条真实缺口；若本批无法形成 `76 → 81` 的可验证集成增量，则在 clean 恢复点停线，不扩到 Ch18。

## 审计选择依据

- 第十七章五关 StageDef 与既有签署会话均为单一对手，正文与图标完整，全仓无既有 typed route、分支或任务登记重叠。
- 17-04 的 `lingQiao` 是既有签署会话对早期 spec 的明确修正；本批只保真迁移，不重新做数值或流派决策。
- 17-04/05 均为 Boss；必须保留 charge、两相位，且 17-05 的 `vulnerability 0.20` 不得在 typed adapter 中丢失。

## 非目标与保护边界

- 不改 `data/stages.yaml`、`data/numbers.yaml`、数值、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。
- 不处理第十三章、第十八章及以后章节或塔，不启动 M8/M9，不新增玩法原语。
- 真人桌面、视觉、音频、手感与 Windows 继续 `DEFERRED`；自动化不代签。

## 验收清单

1. `17_01..05` 各有唯一 migrated assignment、encounter 与 runtime binding，`base_enemy_id` 严格等于对应 `StageDef.enemyTeam.single`。
2. 真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 完整消费；第十七章 `5/5`，全主线候选 `81/105`。
3. 五关保持冻结单敌；17-01/02/03 使用 defeat-target，17-04/05 使用 commander 目标。
4. 17-04/05 保留 Boss 姓名、原图、全技能、蓄力技、两相位与 `createActor` Boss 身份；17-04 不带 vulnerability，17-05 精确为 `0.20`。
5. 测试先红，覆盖 exact actor/role、目标、factory 构建、流派、Boss identity 与五关 dynamic headless victory；至少两向 mutation 精确证红并恢复。
6. targeted、相邻回归、analyze、format、持锁全量、测试契约门与标准 Gate 如实记录；候选 READY 不冒充正式 M7/Phase 2。

## 当前恢复点

- 状态：五关 production route 与测试已接通；三向 mutation 已精确转红并恢复；旧 Ch16 精确水位断言已迁为 `>=76`，测试契约登记已写入。
- 已跑验证：基线 main/origin/remote 同为 `a4d8cd95` 且 clean；精确 SHA CI `33815818040` 成功；Ch17 typed route/分支/任务重叠为 0；StageDef `5/5`、正文 `12/12`、敌人图标 `5/5`；有效初始 RED `0/6`；接线后 Ch17 `6/6`；三向 mutation 分别精确 `1/1/2` 红，恢复后 `6/6`。
- 下一步：运行测试契约门、相邻/Phase 2/mainline application 回归、analyze、format、持锁全量与标准 Gate。
- 挂账：真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。
