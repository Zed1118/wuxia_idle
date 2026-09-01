# Phase 2 M5 九霄塔个人记录审计

日期：2026-09-01

任务：`P2-M5-TOWER-PERSONAL-RECORD`

基线：`b530d804940930628ea1b61e83b188416bc0b1d2`

## 结论

九霄塔原有 `TowerProgress` 只能表达存档级首通、周目和统计，不能证明某个角色的个人最高层或最好成绩。本切片新增版本化 Isar `TowerPersonalRecord`，由手动、扫荡、持久差遣共用的 `applyTowerVictorySettlement` 在原奖励结算事务内按 exact participant 写入。

该工程格由 `BLOCKED` 形成可集成候选，M5 固定矩阵由 `38/42` 推进到 `39/42`；顶层 M5 仍为 `0/1 BLOCKED`。真人桌面、视觉和 Windows 实机验收继续挂账，本审计不据自动测试宣称正式 M5 或 Phase 2 PASS。

## 持久与事务合同

- `saveVersion 0.43.0 → 0.44.0`，新增 `TowerPersonalRecord` collection；canonical key 为 `v1:<saveDataId>:<participantId>`，存档和角色组合唯一。
- 个人最高层只随真实胜利单调递增；最好成绩取有效正耗时中的最短通关时间。即时扫荡传入 `0`，只更新最高层，不伪造或覆盖最好耗时。
- `applyTowerVictorySettlement` 在任何进度或奖励写入前验证 settlement 已结束且 participant 与真实战斗快照一致；角色不存在时 fail closed。
- 个人记录与 `TowerProgress`、U09 reward receipt、角色成长/伤势、掉落和图鉴共用同一 caller-owned write transaction。测试注入故障后所有写入整体回滚；同一 occurrence 重放被 receipt 拦截且不重复更新个人记录。
- 手动胜利直接调用共享边界；生产扫荡经 `settleTowerAutomationVictory` 调用；持久差遣经 `DurableActivityAutomationCoordinator` 调用，三条路径没有新增第二结算 owner。

## 旧档边界

0.43 旧档即使同时存在角色和存档级 17 层塔进度，也不能证明历史参战者。0.44 迁移只注册新集合并升版，个人记录保持空；不从 `TowerProgress`、Boss 纪念或 reward receipt 猜人，不补发奖励。

## 破坏证红

1. 临时删除共享事务中的个人记录写入：手动结算 `2`、生产扫荡 `1`、持久差遣 `1`，共 `4` 条失败。
2. 临时把落库 participant 偏移为另一个角色：原子结算与多角色隔离共 `2` 条失败。
3. 临时从旧档全局塔进度猜第一个在籍角色并回填：迁移守卫精确 `1` 条失败。初版夹具因没有角色而假绿，随后补强为“有角色但无参战证明”并重新取得有效 RED。

三组破坏均用精确反向补丁还原；还原后的扩展定向全部通过。

## 当前验证

- 初始 schema/version RED：`2` 条失败；未接生产写入时，手动 `2`、扫荡 `1`、持久差遣 `1` 条失败。
- 扩展定向：完整塔域 `132/132`、扫荡 application `25/25`、持久差遣协调器 `4/4`、0.44 迁移 `3/3`，合计 `164/164 PASS`。
- `flutter analyze --no-pub lib test tool`：`No issues found!`。
- `dart format .`：`1704 files / 0 changed`。
- 首轮锁保护全量推进到 `5840` 个通过项并发现 `4` 条失败；四条均为既有迁移测试仍把当前版本写死成 `0.43.0`，没有业务、奖励或个人记录失败。更新为精确 `0.44.0` 后相关迁移集 `10/10 PASS`。
- 修复后锁保护整仓复跑：`5844/5844 PASS`，退出码 `0`，`[E]=0`，末行 `07:56 +5844: All tests passed!`；原始日志位于忽略目录 `build/m5_tower_personal_record_full_rerun.log`。
- 塔个人记录测试本身只增不删；另有四处版本值替换为 `4` 增 / `4` 删。两条单行 load-bearing `expect` 已登记测试契约迁移；另外两处仅替换多行 `expect` 的值行，不被专用 Gate 计为断言删除。
- exact READY tip Gate 必须在最终提交后由 receipt 绑定；本文不在执行前预写 PASS。

## 范围

- 未改塔奖励、数值、概率、经济、解锁、周目、战斗规则、玩家属性、技能、YAML 或 `strings.dart`。
- 未从旧档猜测参与者，未伪造个人记录或奖励。
- 未启动 M3/M4；所有真人目检继续挂账。
