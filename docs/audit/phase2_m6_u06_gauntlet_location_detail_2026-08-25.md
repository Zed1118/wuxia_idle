# P2-M6-U06 断魂庄统一地点详情审计

## 交付身份

- 任务：`P2-M6-U06-GAUNTLET-LOCATION-DETAIL`
- 基线：`7f57d5be2cb9d7388dd53160ffdcda6b8de26ab7`
- 分支：`codex/phase2-m6-u06-gauntlet-location-detail-20260825`
- 代码/独立复审候选：`2fdfd46cc4da5300fd98fe68ad2fbe4df98edbd5`
- 精确白名单：`task_registry.yaml` 本任务 `owned_files` 的 16 个文件。

## 生产语义

- 江湖地图断魂庄从直达整备屏改为先进入统一详情；详情 CTA 仍直接进入原 `GauntletLoadoutScreen`。
- provider 只读真实 `gauntletConfigProvider`、`activeGauntletProvider`、`gauntletLoadoutInfoProvider`、`gauntletCandidatesProvider` 与 `GameRepository` 奖励定义，不建立平行 fixture 或状态镜像。
- 统一详情显示生产进度、基础推荐境界、三关敌方生态、首通/失败奖励、断魂帖/补给、当前可用候选人或进行中真实参与者、亲战方式与会话占用。
- 隐藏门、关次/敌方/奖励引用、进度/门票、活跃关次/阶段/参与者或 provider 异常均 fail closed，错误态不暴露进入 CTA。
- 进行中庄局继续通过原整备屏恢复；原选人、补给、周目、恢复、战斗、结算与奖励选择未改。

## 红绿与验证证据

- 依赖安装/生成后，4 个目标因缺失新 domain/provider/screen/strings/route 真实编译失败：`0/4`；红测 commit `56b8fef6`。
- 聚焦 provider/详情屏/地图/主菜单门控：`31/31 PASS`。
- 断魂庄详情屏含 `1280x720` 与 `1440x900` 双视口及 active 恢复路由：`6/6 PASS`，其中双视口 `2/2`。
- 地图、主菜单与断魂庄生产相邻域：`384/384 PASS`。
- scoped analyze（9 项）：`0 issues`；根应用 `flutter analyze --no-pub lib test tool`：`0 issues`。
- 独立语义复审在候选 `2fdfd46c` 上重跑完整地点对比 `42/42`、断魂庄生产对比 `44/44`、详情屏 `6/6`、scoped analyze 0；结论 `P0=0, P1=0, P2=0`，建议 READY。
- 最终全量只运行一次：`flutter test --no-pub --reporter compact` → `5476/5476 PASS`。
- truth-source guard：`9/9 PASS`；`git diff --check`、registry YAML 解析与精确白名单检查在 READY 前终检。

## 边界与未关闭项

- 不新增差遣、前台 bot、自动化 UI、参与者 policy 或渐进解锁决策；断魂庄当前候选池仍沿用现有非掌门存活角色语义。
- 不修改 schema/saveVersion、YAML、`TUNING/candidate`、奖励数值、经济、战斗、主线或 main。
- 本证据只关闭断魂庄统一地点详情首缺口；其他地点详情、U06、U14、M5、M6 与整体二阶段仍开放。
