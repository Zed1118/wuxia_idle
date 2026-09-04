# P2 M7 第二十章内容迁移计划

## 结果合同

- 单一结果：把既有 `stage_20_01..05` 五关接入 typed production catalog、runtime binding 与 production encounter factory，第二十章工程水位 `0/5 → 5/5`。
- 固定分母：全主线 typed production catalog `91/105 → 96/105`；塔保持 `0/49`，legacy runtime retirement 仍开放，正式 Phase 2 保持 `1/10`。
- 实时基线：分支 `codex/p2-m7-ch20-content-migration-20260904` 建于 `main == origin/main == 900a0e86b17a8ef612a89833826ebb23a2b076fb`；该 SHA 的 CI run `33846929799` 为 `completed/success`。
- 关键阻塞：五关 StageDef、12 份关卡正文、章节正文与 5 个敌人图标完整，但 assignment、encounter、runtime binding 与 factory route 均缺失。
- 成本上限：只处理本章 5 条真实缺口；无可靠用量表，约 90 分钟无工程门变化即重评，不扩到 Ch21。

## 审计选择依据

- 第二十章五关都是既有单敌合同；20-01/02/03 是普通目标，20-04/05 是 Boss，不新增多敌生态或玩法原语。
- 当前 StageDef 是权威输入：20-01 为 `lingQiao`，20-02/05 为 `yinRou`，20-03/04 为 `gangMeng`；不被旧 spec 已明确作废的关名、人物与流派覆盖。
- 20-04 必须保留 charge、三段 phase 与 vulnerability `0.18`；20-05 必须保留首周目 `0.12`、二周目 `0.06`，且 `skill_gu_cheng_kai` 同时作为 `dropSkillManualId` 与 Boss `chargeSkillId`。

## 非目标与保护边界

- 不改 `data/stages.yaml`、`data/numbers.yaml`、数值、技能、Boss、掉落、奖励、经济、正文、解锁、周目或结算 owner。
- 不处理第二十一章、第十三章剩余关卡或塔，不启动 M8/M9，不新增玩法原语。
- 真人桌面、视觉、音频、手感与 Windows 继续 `DEFERRED`；自动化不代签。

## 验收清单

1. `20_01..05` 各有唯一 migrated assignment、encounter 与 runtime binding，`base_enemy_id` 严格等于对应 `StageDef.enemyTeam.single`。
2. 真实 repository、factory、runtime adapter、AI/director、objective 与 reducer 完整消费；第二十章 `5/5`，全主线候选 `96/105`。
3. 五关保持冻结单敌；20-01/02/03 使用 defeat-target，20-04/05 使用 defeat-commander。
4. 20-04/05 保留 Boss snapshot、蓄力技、三段 phase 与 `createActor` Boss 身份；vulnerability 精确为 `0.18` 与 `0.12 / 0.06`，20-05 chargeSkill 与掉落真解均为 `skill_gu_cheng_kai`。
5. 测试先红，覆盖 exact actor/role、目标、factory 构建、流派、Boss identity 与五关 dynamic headless victory；至少三向 mutation 精确证红并恢复。
6. targeted、相邻回归、analyze、format、持锁全量、测试契约门与标准 Gate 如实记录；候选 READY 不冒充正式 M7/Phase 2。

## 当前恢复点

- 状态：第二十章五关已由候选 `b28088eff48c6520ebfc3f3c662b612c00ccffef` 经 no-ff merge `4ff2157a1d75fac406c2fbef164ad0cf4a122c1a` 集成到 `main` 与 `origin/main`；merge exact-SHA CI run `33851259205` 已全部成功，工程水位为 `96/105`。
- 有效 RED：新增 Ch20 合同测试首次运行 `0/6`，分别在 assignment、identity/role、真实 factory、objective、Boss runtime 与 dynamic victory 处因生产路由缺失失败；接线后 `6/6` 通过。Ch19+Ch20 首次相邻回归仅留下预期水位失败（期望 `91`、实际 `96`），迁移后 `12/12` 通过。
- 变异证据：删除 `stage_20_01` assignment 时 catalog loader 因 encounter 未分配失败；把 `stage_20_02.base_enemy_id` 改错时 runtime loader 因 StageDef 不一致失败；把 `stage_20_03` role 从 `sect_outer` 改为 `sect_lightfoot` 时 runtime loader 因 attack-set closure 缺失/多余失败。三处均已恢复，assignment/runtime/encounter SHA-256 分别回到 `c65984df2bb944a6bec4072ca775c1f13be9ea0de4f48ed8aac3c9efcd9716cc`、`64f822cfff0856a39184d9ac7601c60ecd270b104d1c1cf943936cdc632dfcdd`、`46d519d5459f8a936cbc6bf494fbfebaae040038b1ba45cd74c68f4d185568b4`。
- 已跑验证：Ch20 `6/6`、Ch19+Ch20 `12/12`、Phase 2 data `174/174`、主线 application `183/183`；候选 analyze 零问题、format `1643` 文件零改动；专用 `test_contract_migration` 门 PASS（实现删 1/增 39、用例删 0/增 6、登记 1 条）。标准 Gate 的白名单、禁改、commit、clean、隔离 full `5987/5987`、analyze 与 format 均 PASS，receipt 因无 `lib/` 改动 SKIP；原始总结果仅 `FAIL: test_deletions`，该 1 行由专用迁移门覆盖。合并态 Ch19+Ch20 `12/12`、full `5987/5987`、analyze 零问题、format `1644` 文件零改动；merge exact-SHA CI 的 Ubuntu coverage/ratchet 与 macOS build 均成功。
- 分支提交：`70b91861` 接通生产目录，`87a57a1d` 迁移 Ch19 水位合同，`56e3727d` 登记 Ch20 测试契约。
- 下一步：提交并推送治理尾，等待最终 exact-SHA CI；随后在最终 HEAD 生成只读真人验收包并校验，不启动 GUI、不代签真人或 Windows 门。
- 挂账：真人桌面、视觉、音频、手感与 Windows 均继续 `DEFERRED`。
