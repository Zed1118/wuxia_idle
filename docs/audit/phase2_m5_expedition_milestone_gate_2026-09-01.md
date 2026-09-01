# Phase 2 M5 百草岭首次险关亲战审计

日期：2026-09-01

任务：`P2-M5-EXPEDITION-MILESTONE-GATE`

基线：`73eedc7a7a7e114d224032afdb5a7712ad867263`

实现提交：`80d95a1415c73f168786836a7de28eb474f32e08`

## 结论

本候选关闭 M5 固定 `6 × 7 = 42` 工程矩阵中百草岭剩余两格：首次险关必须从真实百草岭入口进入可见真人 Phase 0A 战斗，以及同一 `routeId + milestoneId` 亲战通过后才允许后续自动越门。M5 工程候选因此由 `40/42` 推进至 `42/42`；这只表示工程生产接线候选完整，真人桌面、视觉手感和 Windows 实机仍挂账，不冒充正式二阶段或 G2 人工签字。

## 生产合同

- 远征普通节点继续使用原 timed/headless 推进；遇到尚未亲战通过的险关模板时，在该节点前停止，不调用 headless 战斗。
- `ExpeditionMilestoneRecord` 以 `saveDataId + routeId + milestoneId` 形成 canonical key。离线撞门只写待办发现事实；`manualClearedAt` 只能由可见真人险关胜利事务写入。
- 撞门后先结清已完成节点并走原返程奖励、run 删除与 U09 receipt 事务，释放实际参与者；生产总览显示待亲战状态和“亲自破关”入口。
- pending 存在时，`ExpeditionService._dispatch` 在同一入场事务内拒绝所有新派遣，且不建 run、不消费 serial；这使 stale UI、恢复竞态或其它 caller 也不能绕过首次门。模板亲战清除 pending 后，派遣恢复正常。
- 真人入口重新核验 exact 当前角色、装配和待办游标，复用真实 Phase 0A snapshot/content mapper。失败只写共享战斗账本并保留待办；胜利把共享账本、原险关奖励、三层 reward receipt、最深节点和 `manualClearedAt` 合并在同一事务。
- 通过一个险关模板只解锁同一模板；另一个未通过模板仍会停门。已通过模板后续恢复原 headless 推进。

## 迁移边界

- 新增版本化 Isar `ExpeditionMilestoneRecord`，`saveVersion 0.44.0 → 0.45.0`，迁移为纯加法。
- 旧档最深深度、返程或奖励事实不能证明具体险关模板及亲战参与者，因此不猜模板、不回填 `manualClearedAt`、不补发奖励。
- 未修改远征并发、节点时长、敌人数值、玩家属性、技能、奖励金额/概率、经济、解锁阈值、周目、伤势或战斗 reducer。

## 有效验证

- 实现前 RED：未解锁险关仍从节点 `4` 越到 `5`，`1` 条真实失败。
- 扩展定向：`143/143 PASS`。
- 破坏证红并精确反向还原：移除首次门得到 `1` 条失败；移除 `manualClearedAt` 胜利写入得到 `1` 条失败；断开生产 UI 到真人 Host 得到 `1` 条失败。
- 测试契约迁移：`expect` 删除 `3` / 新增 `40`，用例删除 `1` / 新增 `10`，登记 `4` 条，专用 Gate `PASS: test_contract_migration`。
- `flutter analyze --no-pub lib test tool`：`0` issue。
- `dart format .`：`1709 files / 0 changed`。
- 锁保护整仓全量：`5860/5860 PASS`，退出码 `0`，`[E]=0`，末行 `All tests passed!`。

stacked 集成复核随后发现 `baab3fbe…` 只在 UI 替换派遣 CTA，service 没有 pending 入场守卫；该候选因此被淘汰而非直接交付。新增 production typed dispatch 用例在旧实现上真实返回 `runId=1`，取得 `1` 条 RED；补入事务守卫后 PASS，并证明清除 pending 后仍可派遣。删除守卫 mutation 再得到精确 `1` 条失败并反向还原，远征核心组 `58/58 PASS`，analyze 0 issue；格式化只调整新增测试，最终持锁整仓全量为 `5861/5861 PASS`、退出码 `0`、末行 `All tests passed!`。

## Gate 口径

最终候选必须在新的 exact `[READY]` tip 再执行正式 Gate。因生产 UI 新增必要文案命中 `lib/shared/strings.dart`，且版本精确断言替换命中原始 `test_deletions`，原始 Gate 预计只保留这两个显式 FAIL；后者必须由专用迁移 Gate 覆盖，前者依据用户“遇到授权自行授权”的当前批次授权登记为一次性豁免。原始输出必须保留，不得改写为脚本原生全绿。其余 `commit_msg`、`worktree_clean`、`full_test`、`analyze`、`format` 与 `receipt_crosscheck` 必须全部 PASS，组合结论方可记为 `PASS_WITH_EXPLICIT_ONE_TIME_WAIVER`。

## 挂账

- macOS 真实生产入口、待办卡片、真人险关战斗与胜败回流目检。
- Windows 实机布局、输入、性能与恢复目检。
- 本批不启动 M3/M4，不自动合并或 push。
