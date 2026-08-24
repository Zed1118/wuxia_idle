# P2-M6-U06 九霄塔统一地点详情审计

- 日期：2026-08-25
- 基线：`7adb0d9eca6506f0bae1b3c1ae1aa61c71858ac0`
- 登记：`8627114be07fac16536522dc9a52895d84f6f923`
- 代码候选：`087b64238f6a1ec97e83c8acb782abd0dddc305f`
- 状态：`ready_reviewed`

## 问题与权威归属

二阶段方案 §11.2 要求江湖地点统一展示进度、推荐境界、敌方生态、核心收获、参与者、进入方式和预计占用。基线九霄塔地点直接进入塔层列表，没有详情层。仓库已有完整权威来源：`towerProgressProvider`、下一层 `TowerFloorDef`、`DropRumorTable`、`CurrentLeaderResolver` 与真实 `Phase0aTowerBattleHost`，无需新增 schema、配置或参与者规则。

## 实现边界

- 江湖地图九霄塔入口先进入 `TowerLocationDetailScreen`，不再绕过地点详情。
- 详情只读当前最高层、生产塔总层数和下一层配置，展示推荐境界、敌人姓名/流派、首通掉落传闻与基础修为。
- 实际参与者经 `CurrentLeaderResolver` 从存档和真实角色表解析，与塔战 Host 的生产口径一致；不回退硬编码角色。
- Isar 未初始化、进度越界、领队指针缺失/悬空或 provider 异常时 fail closed，只显示不可核实状态且不暴露进入 CTA。
- 登顶态明确没有下一层情报，但保留进入塔层列表重打已通层的能力。
- 详情 CTA 继续经过原 `guardBattleEntry`；闭关中仍被原门禁阻挡，放行后真实进入 `TowerFloorListScreen`。
- “亲自挑战，不可派遣”和“仅本次亲战过程，不建立长期派遣占用”只描述现有路由，不创造持久占用、派遣、自动化或 U14 参与矩阵。
- 未修改 schema/saveVersion、YAML、TUNING、数值、概率、奖励、经济、解锁或叙事。

## TDD 与验证

- 真实红测：`0/1`，精确失败于地图点击后缺少 `tower-location-detail-screen` 且仍直达塔层列表。
- provider + 详情 + 地图聚焦证据：合计 `22/22 PASS`。
- 江湖地图/塔/闭关/掉落/主菜单入口/纸面对比相邻域：`403/403 PASS`。
- 详情双视口：1280×720、1440×900，`2/2 PASS`，无布局异常。
- scoped analyze 与 root `flutter analyze`：均 `0 issue`；`git diff --check` 通过。
- 独立复核：`42/42 PASS`，`P0=0 / P1=0 / P2=0`，建议 `READY`。
- 最终 root full suite：`5419/5419 PASS`。

## 结论

九霄塔统一地点详情首纵切达到 `READY`。该证据不代表其余地点详情、差遣、自动化、U06、U14、M6 或二阶段完成。
