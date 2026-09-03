# P2 M7 第十六章内容迁移计划

## 结果合同

- 单一结果：把既有 `stage_16_01..05` 五关接入 typed production catalog、runtime binding 与 production encounter factory，第十六章工程水位 `0/5 → 5/5`。
- 固定分母：全主线 typed production catalog `71/105 → 76/105`；塔保持 `0/49`，legacy runtime retirement 仍开放，正式 Phase 2 保持 `1/10`。
- 实时基线：分支 `codex/p2-m7-ch16-content-migration-20260904` 建于 `main == origin/main == bf60ec04e28a5bab09163f749613d9aeab26bce7`；该 SHA 的 CI run `33803760075` 为 `completed/success`。
- 关键阻塞：五关 StageDef、13 份正文与 5 个敌人图标完整，但 assignment、encounter、runtime binding 与 factory route 均缺失。
- 成本上限：只处理本章 5 条真实缺口；北京时间 06:40 前若无 `71 → 76` 可验证候选增量，停线重评；08:00 不开新批。

## 审计选择依据

- 第十六章五关 StageDef 与冻结 spec 均为单一对手，正文与图标完整，全仓无既有 typed route 或任务登记重叠。
- `16_04` 正文的随行马队是场景叙事，冻结战斗合同与 StageDef 均只有游骑将一名对手，不扩为群战。
- `16_05` 是唯一特殊风险：必须保留 `skill_tie_ma_bing_he` 蓄力技、两相位及入相蓄力机制的完整快照。

## 非目标与保护边界

- 不改 `data/stages.yaml`、`data/numbers.yaml`、数值、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。
- 不处理第十三章或第十七章及以后章节，不启动 M8/M9，不新增玩法原语。
- 真人桌面、视觉、音频、手感与 Windows 继续 `DEFERRED`；自动化不代签。

## 验收清单

1. `16_01..05` 各有唯一 migrated assignment、encounter 与 runtime binding，`base_enemy_id` 严格等于对应 `StageDef.enemyTeam.single`。
2. 真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 完整消费；第十六章 `5/5`，全主线候选 `76/105`。
3. 五关保持冻结单敌；16-01/02/03 使用 defeat-target，16-04/05 使用 commander 目标。
4. 16-04/05 保留 Boss 身份；16-05 姓名、原图、全技能、蓄力技、相位与 `createActor` Boss 身份与 StageDef 一致。
5. 测试先红，覆盖 exact actor/role、目标、factory 构建、流派、Boss identity 与五关 dynamic headless victory；至少两向 mutation 精确证红并恢复。
6. targeted、相邻回归、analyze、format、持锁全量、测试契约门与标准 Gate 如实记录；候选 READY 不冒充正式 M7/Phase 2。

## 当前恢复点

- 状态：生产接线 `7e41f106`、旧合同迁移 `c551832b` 与测试契约登记 `511d8e9d` 已完成，候选 `5f5c8006` 经 no-ff merge `8c5d9fdb` 进入 `main` 与 `origin/main`，集成水位为 `76/105`。
- 已跑验证：有效初始 RED `0/6`；三向 mutation 分别精确转红 `1/1/2` 并恢复；第十六章 `6/6`；第十五/十六章 `12/12`；Phase 2 data `150/150`；mainline application `183/183`；analyze 0 issue；整仓 format `1729/0`；测试契约迁移 Gate `PASS`；候选与合并后持锁整仓均 `5959/5959`；标准 Gate 原始结论仅 `FAIL: test_deletions`，其余子项全通过；merge exact-SHA CI run `33809487636` 全部 jobs/steps 成功。
- 下一步：同步治理状态并推送精确 SHA CI；完成后只做下一非竞争 M7 缺口的限时只读审计。
- 挂账：真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。
