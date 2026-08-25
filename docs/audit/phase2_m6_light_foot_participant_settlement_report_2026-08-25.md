# P2-M6 轻功试炼实际参与者结算报告闭环审计

## 交付身份

- 任务：`P2-M6-LIGHT-FOOT-PARTICIPANT-SETTLEMENT-REPORT`
- 基线：`84199646978851297a9b3981335b48f6b9dfbc8e`
- 分支：`codex/phase2-m6-light-foot-participant-settlement-report-20260825`
- 代码/语义复核候选：`91c1e0144aceaead366adc3309e8acaee2ec7b42`
- 状态：`ready_reviewed`

## 生产语义

- 轻功地点详情与路线列表每次挑战都从当前掌门、当代存活门人中重新选择一名 eligible 实际参与者；身份与占用分别读取 `CurrentLeaderResolver` 与 `CharacterOccupancyService`。
- 选定 ID 在入战前再次复核，由 `PlayerCombatantSnapshotAssembler.loadExactRoster` 装配单人快照，并进入既有真实 `Phase0aMainlineBattleHost`；不回退掌门，不新建 reducer、session 或结算真相源。
- 轻功胜利与最终未重试战败均严格核对该单一参与者，沿共享 `CombatResolutionService` 将经验、伤势、装备战斗次数与心法使用写回实际角色；错人、缺人或悬空资源均 fail closed。
- 胜利页与最终失败报告显示实际参与者姓名。重试仍保持免结算，投降、路线解锁、周目、奖励、叙事与战斗规则不变。
- 旧地点全局闭关门禁会在掌门闭关时误拦空闲门人，已移除轻功详情上的该重复门禁；现由逐人占用契约拦闭关掌门并保留空闲门人。守城/主线门禁未改。

## 红绿与验证

- 初始 RED 四类契约因缺少真实候选、exact participant 入战、严格结算与身份报告 API 失败；实现后定向 `84/84 PASS`、轻功/地图/调度/主线/结算相邻生产域 `170/170 PASS`、双视口 `2/2 PASS`。
- scoped analyze 与根应用边界 `flutter analyze lib test` 均 `0 issue`；无参数根 analyze 的 1943 项来自独立 nested package `tools/phase0minus_probe` 未在根包语境安装自身依赖，未冒充根应用结果。
- 候选只运行一次最终全量 `flutter test`：`5545/5545 PASS`，墙钟约 `4:21`。
- 主控检查实际 diff、生产路由、fail-closed、共享结算和重试边界：`P0=0 / P1=0 / P2=0`。Luna/high 只用于开工时的只读缺口比较，因守城阵型耦合更高而快速选定轻功，不冒称最终独立复审。

## 结果驱动记录

- 验收门变化：轻功逐次选人、真实入战、共享结算与身份报告必要生产子门 `WIP 0/1 → READY 1/1`；M6 顶层仍 `WIP`。
- 可观测耗时：WIP 登记 `15:56`，代码、验证与治理收口约 30 分钟，仅越过 90 分钟上限的 25% 检查点，未到 50% 检查点。
- 可观测用量：无可靠周用量读数，未伪造百分比；只记墙钟、最终验证、1 项生产集成返工和 1 项测试框架串行修正。
- 集成返工：发现并关闭 1 项生产问题（旧全局闭关门禁误拦空闲门人）；另有 1 项 Isar async/fake-async 测试挂起调整为串行契约，不计生产缺陷。
- 这是新工作流第 5 个可比 gate；任务风险面不同，仍不宣称 40%-70% 效率提升。

## 边界与未关闭项

- 本结论只关闭轻功试炼的实际参与者生产闭环，不代表轻功所有自动化已完成，更不代表 M6 或二阶段完成。
- 守城仍固定掌门且与阵型语义耦合；派遣/自动/headless 解锁不在本切片；M6 顶层“亲战/差遣→结算→报告”仍待其他生产入口收口。
- 未修改 schema/saveVersion、YAML、`TUNING/candidate`、数值、奖励、经济、解锁、叙事、战斗规则或 main。
