# P2-M6-U07 宗门行止当前态审计

- 日期：2026-08-25
- 基线：`b63adc8fa41bef63b9bcd51668ec3c2e524059f4`
- 登记：`6c80724cd1302bf878182fb6a6f74dbc478f2966`
- 代码候选：`73adcd6508e7136f79460054832646c93e72788e`
- 状态：`ready_reviewed`

## 问题与权威归属

二阶段方案 §11.2 要求顶部“宗门行止”摘要展示掌门状态、门人占用和远征/断魂庄进度，U07 将其列为独立 UX 任务。基线的 `SectHubScreen` 只有七个子系统路由，没有当前态摘要。仓库已有权威 `CurrentLeaderResolver`、`CharacterOccupancyService`与 active 远征/断魂庄 provider，因此无需创建新状态或 schema。

## 实现边界

- 宗门 Hub 顶部新增独立纸面面板，原七条路由、参数和门控不变。
- 掌门必须经 `CurrentLeaderResolver` 核实；指针缺失/悬空、重复活动占用、占用角色悬空或 Isar/provider 异常均显示“暂不可核实”，不回退硬编码角色。
- 闭关、百草岭和断魂庄成员只从 `CharacterOccupancyService.snapshot()` 读取；掌门状态与其余门人占用分开显示。
- 远征深度/战败、断魂庄关次/阶段只读原 active provider，无 active run 时明确显示无当前活动。
- 不新增疗伤/听剑占用，不创建方案中已被 rejected registry 拒绝的统一完成报告。
- 未修改业务写入、schema/saveVersion、YAML、TUNING、奖励、经济、解锁或叙事。

## TDD 与验证

- 红测：首项在接线前为 `0/1`，精确失败于缺少 `sect-itinerary-panel`。
- provider/panel/宗门 Hub/占用/纸面对比联合：`25/25 PASS`。
- 宗门 + 占用 + 远征 + 断魂庄 + 主菜单完整相邻域：`533/533 PASS`。
- scoped analyze 与 root `flutter analyze`：均 `0 issue`；`git diff --check` 通过。
- 独立复核：`29/29 PASS`，`P0=0 / P1=0 / P2=0`，建议 `READY`。
- 最终 root full suite：`5408/5408 PASS`。

## 结论

宗门行止当前态首纵切达到 `READY`。该结论不代表已完成报告、疗伤/听剑占用、U07、M6 或二阶段完成。
