# P2 M7 第十八章内容迁移计划

## 结果合同

- 单一结果：把既有 `stage_18_01..05` 五关接入 typed production catalog、runtime binding 与 production encounter factory，第十八章工程水位 `0/5 → 5/5`。
- 固定分母：全主线 typed production catalog `81/105 → 86/105`；塔保持 `0/49`，legacy runtime retirement 仍开放，正式 Phase 2 保持 `1/10`。
- 实时基线：分支 `codex/p2-m7-ch18-migration-20260904` 建于 `main == origin/main == 6141c7476de0b28c0002f89d87ef690efd57cfd0`；该 SHA 的 CI run `33829726825` 为 `completed/success`。
- 关键阻塞：五关 StageDef、12 份正文与 5 个敌人图标完整，但 assignment、encounter、runtime binding 与 factory route 均缺失。
- 成本上限：只处理本章 5 条真实缺口；若本批无法形成 `81 → 86` 的可验证集成增量，则在 clean 恢复点停线，不扩到 Ch19。

## 审计选择依据

- 第十八章五关都是既有单敌合同；18-01/02/03 是普通目标，18-04/05 是 Boss，不需要替用户发明多敌生态。
- 当前 StageDef 是权威输入：18-04 的流派为 `yinRou`，不得被旧 spec 中已漂移的 `gangMeng` 覆盖。
- 18-04/05 必须保留姓名、图标、全部技能、charge、两相位和 vulnerability `0.20 / 0.12`；18-05 的 `skill_yang_guan_wu_gu_ren` 同时是掉落真解与 Boss chargeSkill，迁移不得拆散。

## 非目标与保护边界

- 不改 `data/stages.yaml`、`data/numbers.yaml`、数值、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。
- 不处理第十三章、第十九章及以后章节或塔，不启动 M8/M9，不新增玩法原语。
- 真人桌面、视觉、音频、手感与 Windows 继续 `DEFERRED`；自动化不代签。

## 验收清单

1. `18_01..05` 各有唯一 migrated assignment、encounter 与 runtime binding，`base_enemy_id` 严格等于对应 `StageDef.enemyTeam.single`。
2. 真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 完整消费；第十八章 `5/5`，全主线候选 `86/105`。
3. 五关保持冻结单敌；18-01/02/03 使用 defeat-target，18-04/05 使用 defeat-commander。
4. 18-04/05 保留 Boss snapshot、蓄力技、两相位与 `createActor` Boss 身份；vulnerability 精确为 `0.20 / 0.12`，18-05 chargeSkill 与掉落真解都为 `skill_yang_guan_wu_gu_ren`。
5. 测试先红，覆盖 exact actor/role、目标、factory 构建、流派、Boss identity 与五关 dynamic headless victory；至少三向 mutation 精确证红并恢复。
6. targeted、相邻回归、analyze、format、持锁全量、测试契约门与标准 Gate 如实记录；候选 READY 不冒充正式 M7/Phase 2。

## 当前恢复点

- 状态：第十八章 `5/5` 工程候选 READY，等待独立标准 Gate 与受控集成。
- 已跑验证：有效初始 RED `0/6`；删 assignment、错 base enemy、错角色语义三向 mutation 均精确变红并恢复原 SHA；Ch18 `6/6`；Ch17+18 `12/12`；Phase 2 data `162/162`；mainline application `183/183`；analyze 0 issue；format 1636 files 0 changed；test-contract migration `PASS`（expect 删 1/增 37、用例删 0/增 6、登记 1）。
- 下一步：提交 READY，运行独立标准 Gate；通过风险匹配检查后 no-ff 合并到 main、持锁回归、推送并等待 exact-SHA CI。
- 挂账：真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。
