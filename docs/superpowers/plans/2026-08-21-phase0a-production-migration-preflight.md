# Phase 0A 生产内容迁移预检

## 目标

复用 Phase 0A production mapper、flow assembler 与 headless runner，对 Ch1 之外的主线战斗关和 49 层塔建立可重复预检。预检只输出装配、确定性、终局/超时和伤害红线证据，不修改 YAML、战斗公式或平衡数值，也不把尚未实现的 Boss 阶段、蓄力、守护、破绽语义伪装成已迁移。

## 分支

`codex/phase0a-production-preflight-0821`

## 验收标准

- [x] 生产接线：主线继续走 `Phase0aStageContentMapper`；塔通过同一 mapper 的薄适配入口装配，敌方 snapshot 必须复用 `EnemyCombatantSnapshotAssembler` 且传入塔语义。
- [x] 内容 manifest 从生产定义派生；状态只允许 `eligible` / `skipped`，稳定记录 content kind、id 与 skip reason。装配异常不得吞成 skip 或 timeout。
- [x] 忠实性边界：Boss phase/charge、guardian ward、vulnerability、非 `defeatAll`、特殊 stage type/waves 等未支持语义默认 skipped。
- [x] 对所有 eligible 条目运行 smoke，检查唯一键、合法终局或 timeout、tick 预算、6 个技能槽观测、单次伤害 `< 1,000,000`；固定 canonical case 全字段重放一致。
- [ ] targeted test 明确覆盖 stage/tower mapper、manifest 分类和 headless 预检主路径，并记录命令与通过数。
- [ ] 批末执行 `flutter analyze` 与一次并发 `flutter test --no-pub`；若后续改动可能使结果失效则重跑相关验证。
- [ ] 红线影响：零 YAML、零公式、零平衡数值、零 UI；不触及三系锁死、在线=离线和反主流条目；Dart 不新增中文玩家文案或散写战斗数值。
- [ ] 残留风险明确记录：skipped 内容、bot 不等于真人、Mac headless 不能替代六人主观 Gate 与 Windows 实机 Gate。
- [ ] 合并 Gate：检查无高频 debug 日志、临时输出/截图/生成文件误提交；commit message 使用中文动宾；分支 tip 以 `[READY]` 标记且工作树干净。

## 任务切片

1. 冻结生产内容分类规则与 mapper 边界。
2. 抽取通用 profile runner，并保持 Ch1 helper 兼容。
3. 增加塔 mapper 薄适配、manifest 与生产内容预检 diagnostic。
4. 审查 diff，执行 targeted、analyze、全量验证。
5. 更新恢复点与 `PROGRESS.md`，标记就绪并合回 `main`。

## 当前恢复点

- 状态：实现完成，批末验证中。
- 最后完成：通用 profile runner、塔 mapper、稳定 manifest 与生产预检 diagnostic 已落地。按仓库真实 21 章订正范围为 Ch2–Ch21 主线 100 关，其中 73 eligible；塔 41/49 eligible。10-seed 全画像共 3420 局，555 胜 / 2865 负 / 0 timeout，最大单击 2056；35 条 skipped = Boss/蓄力 24、破绽 8、守护 2、特殊胜负 1。
- 下一步：完成 analyze、批末全量、diff/误提交 Gate，更新进度并标记 READY。
- 已跑验证：targeted smoke 19 pass / 0 fail；10-seed diagnostic 1 pass / 0 fail（3420 runs）；`git diff --check` 通过；实现态 `flutter analyze` 已返回 0 issue，最终态仍会重跑。
- 阻塞项：无。六人主观 Gate 与 Windows 实机 Gate 明确不属于本批。
