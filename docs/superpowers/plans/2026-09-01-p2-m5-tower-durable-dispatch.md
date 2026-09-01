# P2 M5 九霄塔持久差遣结果合同

## 唯一目标

- task：`P2-M5-TOWER-DURABLE-DISPATCH`。
- 基线：`09533ce357344559e6bf0b7594084b18ad107562`。
- 只关闭九霄塔“离线/差遣允许矩阵”一格：已通层从既有生产塔列表提交 exact participant 的持久差遣，复用已有 durable run、占用、`mapTower` headless runner、塔进度/战斗结算和 U09 receipt owner。
- 有效 M5 矩阵目标从 `37/42` 推至 `38/42`；九霄塔每角色最高层/最好成绩仍 `BLOCKED`，不得由存档级 `TowerProgress` 冒充。

## 生产合同

1. 首通继续只能真人亲战；只有当前周目真实已通层显示“差遣历练”。
2. request 固定为 exact `tower_<floor>`、exact participant/loadout 与 `dispatch + playerBot + headless + offlineResume`；不得与既有 direct sweep 混用。
3. 开始时在同一事务重验当前存档、周目、已通层、唯一 outstanding durable run、角色可用性与 exact 装备/心法，并先落 active run/seed/离线游标。
4. 恢复时重验同一参与者代际与装配、统一占用及塔层身份；真实 `Phase0aStageContentMapper.mapTower` 与 Phase 0A headless 内核不得另造 reducer/runner。
5. 胜利的塔进度、成长/伤势、掉落、图鉴、奖励 receipt 与 durable settlement receipt 同一事务提交；败北的成长/伤势、塔失败统计与 durable receipt 同一事务提交。
6. timeout 保留 active run；settlementApplied 只展示既有事实报告，阅报后 close 并释放占用，不重放奖励或成长。

## 验证与停止线

- production UI、policy/service、真实 runner、胜利/败北 settlement 和跨模式矩阵均有可破坏证红守卫。
- 至少三向 mutation：移除 dispatch allowlist、移除生产入口、断开 durable settlement receipt；每向必须红并精确反向还原。
- targeted、analyze、整仓 format、锁保护全量、项目 Gate、合并 push 与精确 SHA CI 全部通过后才关闭本切片。
- 本切片不关闭九霄塔个人记录，也不外推断魂庄 durable owner或百草岭首次里程碑接管。

## 禁止范围

- 不改 Isar collection 字段、schemaVersion/saveVersion、玩家数值、技能、奖励金额或概率、经济、解锁阈值、YAML TUNING 或战斗规则。
- 只在既有 `DurableActivityCombatRun.kind` 名称字符串值域增加 `tower`；不新增持久字段或集合。
- 不启动 M3/M7；真人桌面交互、视觉与 Windows 实机继续挂账，不冒充正式 M5/Phase 2 验收。
