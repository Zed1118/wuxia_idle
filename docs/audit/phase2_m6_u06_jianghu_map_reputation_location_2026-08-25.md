# P2-M6-U06 江湖地图声望地点审计

- 日期：2026-08-25
- 基线：`0dc51a34544481a41b1a8212ffe182b9c0d06e96`
- 登记：`b48b3b4533cedc4c7b89f71d84a69c74bf6e500f`
- 代码候选：`898a67e25bb4168a0a90e0b2662681532a2f651c`
- 状态：`ready_reviewed`

## 问题与权威归属

二阶段方案 §11.1 冻结四个一级入口，§11.2 要求野外内容进入江湖地图。候选基线中“江湖恩怨”仍为主菜单平铺卡，与已建立的地图信息架构不一致。原生产门槛是 `kFirstChapterFinalStageId`，原去向是 `ReputationPanelScreen`；本切片只迁移入口所属，不重新设计社交系统。

## 实现边界

- 主菜单删除平铺声望卡，仍将同一 `socialLocked` 透传给宗门 Hub。
- 江湖地图新增第六个声望地点；进度未决/异常、未过第一章末关均 fail closed，不发布路由。
- 门槛后点击真实 push 既有 `ReputationPanelScreen`；声望 provider、等阶、关系与任务行为未改。
- 江湖商店仍为主菜单条件入口，既有五个地图地点生产逻辑未改。
- 未修改 schema/saveVersion、YAML、TUNING、奖励、经济、声望算法或解锁决策。

## TDD 与验证

- 红测：新增四项在接线前为 `0/4`；一项命中主菜单仍有声望，三项命中地图缺少 `jianghu-map-reputation-location`。
- 聚焦声望地点/地图/主菜单/原声望面板/纸面对比：`87/87 PASS`。
- 主菜单 + 江湖地图 + 江湖声望 + 商店相邻域：`201/201 PASS`。
- scoped analyze 与 root `flutter analyze`：均 `0 issue`；`git diff --check` 通过。
- 独立复核：`94/94 PASS`，`P0=0 / P1=0 / P2=0`，建议 `READY`。
- 最终 root full suite：`5402/5402 PASS`。

## 结论

江湖地图声望第六地点纵切达到 `READY`。该结论不代表统一地点详情、U06、U14、M6 或二阶段完成。
