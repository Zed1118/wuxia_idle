# P2 M7 第十九章内容迁移计划

## 结果合同

- 单一结果：把既有 `stage_19_01..05` 五关接入 typed production catalog、runtime binding 与 production encounter factory，第十九章工程水位 `0/5 → 5/5`。
- 固定分母：全主线 typed production catalog `86/105 → 91/105`；塔保持 `0/49`，legacy runtime retirement 仍开放，正式 Phase 2 保持 `1/10`。
- 实时基线：分支 `codex/p2-m7-ch19-content-migration-20260904` 建于 `main == origin/main == c5fa3b15e678deea884a9266e178d93cb0be3778`；该 SHA 的 CI run `33835017052` 为 `completed/success`。
- 关键阻塞：五关 StageDef、12 份关卡正文、章节正文与 5 个敌人图标完整，但 assignment、encounter、runtime binding 与 factory route 均缺失。
- 成本上限：只处理本章 5 条真实缺口；若本批无法形成 `86 → 91` 的可验证集成增量，则在 clean 恢复点停线，不扩到 Ch20。

## 审计选择依据

- 第十九章五关都是既有单敌合同；19-01/02/03 是普通目标，19-04/05 是 Boss，不新增多敌生态或玩法原语。
- 当前 StageDef 是权威输入：19-01/04 为 `gangMeng`，19-02 为 `lingQiao`，19-03/05 为 `yinRou`；迁移不重写数值、招式、掉落或正文。
- 19-04/05 必须保留姓名、图标、全部技能、charge 与相位；19-04 不配 vulnerability，19-05 保留首周目 `0.15`、二周目 `0.08`，且 `skill_yi_jing_shuang_zhao` 同时作为掉落真解与 Boss chargeSkill。

## 非目标与保护边界

- 不改 `data/stages.yaml`、`data/numbers.yaml`、数值、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。
- 不处理第二十章、第二十一章、第十三章剩余关卡或塔，不启动 M8/M9，不新增玩法原语。
- 真人桌面、视觉、音频、手感与 Windows 继续 `DEFERRED`；自动化不代签。

## 验收清单

1. `19_01..05` 各有唯一 migrated assignment、encounter 与 runtime binding，`base_enemy_id` 严格等于对应 `StageDef.enemyTeam.single`。
2. 真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 完整消费；第十九章 `5/5`，全主线候选 `91/105`。
3. 五关保持冻结单敌；19-01/02/03 使用 defeat-target，19-04/05 使用 defeat-commander。
4. 19-04/05 保留 Boss snapshot、蓄力技、相位与 `createActor` Boss 身份；19-04 无 vulnerability，19-05 周目弱点精确为 `0.15 / 0.08`，掉落真解与 chargeSkill 均为 `skill_yi_jing_shuang_zhao`。
5. 测试先红，覆盖 exact actor/role、目标、factory 构建、流派、Boss identity 与五关 dynamic headless victory；至少三向 mutation 精确证红并恢复。
6. targeted、相邻回归、analyze、format、持锁全量、测试契约门与标准 Gate 如实记录；候选 READY 不冒充正式 M7/Phase 2。

## 当前恢复点

- 状态：候选 `7072d7ca` 经 no-ff merge `5ab2fe35` 进入 `main/origin/main`，merge exact-SHA CI run `33844770791` 全部成功；主线工程水位入账为 `91/105`。
- 已跑验证：有效初始 RED `0/6`；三向 mutation 精确变红并按 SHA-256 恢复；Ch19 `6/6`；Ch18+19 `12/12`；Phase 2 data `168/168`；mainline application `183/183`；analyze 0 issue；format 0 changed；test-contract migration `PASS`；候选标准 Gate 隔离 full `5981/5981`、错误块 0，原始结果仅 `FAIL: test_deletions`（已登记）；合并态 full `5981/5981`；merge exact-SHA CI 全部 jobs/steps 成功。
- 下一步：本计划、task registry、PROGRESS 与独立审计组成治理尾；提交后核对该最终 exact-SHA CI，再以 Ch20 `91/105 → 96/105` 为唯一下一工程门。
- 挂账：真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。
