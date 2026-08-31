# Phase 2 M6 工程集成 Gate 审计

日期：2026-09-01

基线：`a6a76917a1731fe96ed3ba650b741961eba05788`

任务：`P2-M6-ENGINEERING-INTEGRATION-GATE`

## 当前结论

U01–U14 的分项候选已在 main 汇合，但旧记录多次明确只关闭纵切，不能靠 READY 数量推导 M6。此次以二阶段方案 M6 的四条正式 Gate 重新建立固定 `0/1` 工程分母，并新增七类 production admission 的同源占用集成守卫。

当前生产实现未发现新的代码缺陷：同一空闲掌门可通过主线、塔、轻功、守城、心魔、百草岭和断魂庄的真实应用 API；同一角色进入闭关后七条路径全部拒绝，远征与断魂庄保持零新增 run，断魂帖不扣。因而本轮生产代码零 diff，新增的是能在共享真相源或任一入口漂移时变红的顶层守卫。

## 四门证据映射

| M6 Gate | 生产 owner / 证据链 | 工程结果 |
|---|---|---|
| 占用冲突 fail closed | `CharacterOccupancyService` → `DiscipleSchedulingSummary` → 七类 exact admission；新增同一 Isar 角色联合守卫 | PASS |
| 掌门闭关不可战、空闲可支线 | 新守卫对 idle/retreat 两态逐一调用七类 production API，并检查活动零写 | PASS |
| 主菜单到选人、亲战/差遣、结算、报告 | 四入口真实路由、六模式 picker/admission、共享 live/headless、durable receipt、U10 事实报告组合保护网 | PASS（工程链） |
| 连续主线不弹强制文本 | 精确 `stage_01_01..stage_21_05` 的 105 关拓扑与 `StageType.mainline` 判据 | PASS |

## 破坏证红

| 破坏 | 实测结果 |
|---|---|
| 删除闭关占用聚合 | 新集成守卫 `1 FAIL` |
| 反转塔入口 idle/occupied 判定 | 新集成守卫 `2 FAIL` |
| 将主菜单江湖地图动作错误路由到章节页 | 生产路由守卫 `1 FAIL` |
| 丢弃百草岭返程 actual participant name | 返程结算守卫 `1 FAIL` |
| 让主线恢复自动展示叙事 | 105 关叙事守卫 `2 FAIL` |

全部破坏均使用精确反向补丁还原；还原后生产文件零 diff。新增联合守卫 `2/2 PASS`，M6 组合定向 `157/157 PASS`。

## 最终验证

- `flutter analyze --no-pub lib test`：0 issue，末行 `No issues found! (ran in 14.7s)`。
- `dart format .`：`1699 files / 0 changed`。
- 锁保护全量：`5822/5822 PASS`，退出码 0，`[E]=0`，末行 `05:09 +5822: All tests passed!`。
- 项目 Gate：必须在最终 READY tip 上独立执行并 PASS 后才允许合并。
- main 合并、push、精确 SHA CI：待完成。

## 挂账与判定边界

- 真人桌面验收：四入口可发现性、选人/差遣手感、报告可读性、连续五关主观连贯性。
- Windows 实机、性能和无障碍矩阵仍属后续正式验收。
- 因上述人工门挂账，本结论即使工程验证全绿，也只允许写“M6 工程集成候选 `1/1`”，不允许写“正式 M6 PASS”或提升顶层 M0–M9。
