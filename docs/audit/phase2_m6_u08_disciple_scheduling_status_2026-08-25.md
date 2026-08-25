# P2-M6-U08 门人调度当前态审计

## 交付身份

- 任务：`P2-M6-U08-DISCIPLE-SCHEDULING-STATUS`
- 基线：`9354ff9521ee469c238226bd29a1702bec7631cb`
- 分支：`codex/phase2-m6-u08-disciple-scheduling-status-20260825`
- 代码/语义复核候选：`1e12d0f155b19d72b01979b02eef3f2d00a02ca8`
- 状态：`ready_reviewed`

## 生产语义

- 宗门 Hub 与门派谱两个玩家可达入口不再引用 `TeamLineupScreen`，统一进入只读 `DiscipleSchedulingScreen`。
- 当前掌门必须经 `CurrentLeaderResolver` 核实；当代门人口径与既有门派谱一致，使用掌门直系列表、`masterId` 及 active/recruited 兼容引用，已绑定旧掌门的兼容成员不串入当代。
- 闭关、百草岭和断魂庄只从 `CharacterOccupancyService.snapshot()` 读取；无效掌门、悬空成员、掌门直系列表跨代、重复占用或 provider/Isar 异常均 fail closed。
- 新页无 `LineupService`、`writeTxn`、`activeCharacterIds` 或 `isActive` 写入；亲战、重打与差遣参与者仍由各活动入口逐次选择。
- 旧屏与 `LineupService` 仅留兼容/debug `visual_route_host`，本切片不删 schema 或兼容字段。

## 红绿与验证

- 接管后首轮定向：provider/页面/生产路由/宗门入口均绿，门派谱路由测试因只等待一帧而失败；改为等待完整导航动画后通过，未修改生产导航。
- 语义复核新增“掌门直系列表指向旧代成员”破坏测试，修复前 `0/1`，修复后 fail closed；这是本轮唯一生产语义返工。
- 聚合测试补入真实 Isar `BossGauntletRun`，不再用“三类占用”标题冒充只覆盖闭关+远征。
- 定向五路：`29/29 PASS`；lineup 全目录 + 统一占用 + 宗门行止相邻域：`49/49 PASS`；页面 `1280x720` / `1440x900`：`2/2 PASS`。
- scoped `flutter analyze --no-pub lib/features/lineup` 与根应用 `flutter analyze --no-pub lib test tool`：均 `0 issue`。
- 无路径范围的 `flutter analyze --no-pub` 仍会误纳入独立嵌套包 `tools/phase0minus_probe`，实测 `1943 issues`，首项为该包缺自身 package URI；这是已有根包边界问题，本切片未越界修改，也未将其写成 analyze 0。
- 最终全量只运行一次：`flutter test --no-pub --reporter compact` → `5516/5516 PASS`，耗时 `5:42`。
- 主控二次语义复核 `P0=0 / P1=0 / P2=0`；`git diff --check`、生产路由/零写入扫描、精确白名单和 primary `main@e292d3a` clean 均在 READY 前复核。本轮未启用子 Agent，因此不将主控复核冒称为独立 Agent 复审。

## 结果驱动记录

- 验收门变化：U08 必要生产子门 `WIP 0/1 → READY 1/1`；M6 顶层四门不由此晋升。
- 可观测耗时：结果合同 `09:28` 到最终全量结束约 `14 分钟`，低于 90 分钟路线上限的 25% 检查点。
- 可观测用量：无可靠周用量读数，未伪造百分比；仅记录墙钟时间。
- 集成返工：1 个生产 fail-closed 缺口、1 个导航测试等待缺口、1 个断魂庄覆盖缺口；均在最终全量前关闭。
- 这是新工作流第 1 个可比 gate；不宣称 40%-70% 效率提升，等第 2 个可比 gate 后再比较。

## 边界与未关闭项

- 本结论只关闭“生产入口去旧三席 + 当代门人三类占用只读/fail closed”子门，不代表 U08 完整差遣策略、M6 或二阶段完成。
- 不修改 schema/saveVersion、YAML、`TUNING/candidate`、数值、奖励、经济、解锁、叙事、战斗或 main；不新建 reducer/session/headless/事件/结算真相源。
- 双视口 widget 测试不替代真实 Flutter Desktop 截图、Profile、Windows 或无障碍人工验收；本子门不以这些证据签署 M6。
