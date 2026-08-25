# P2-M6-U06 百草岭统一地点详情审计

## 交付身份

- 任务：`P2-M6-U06-EXPEDITION-LOCATION-DETAIL`
- 基线：`c6c9e7a9eef846a2125c4d33cccf33499352c4b2`
- 分支：`codex/phase2-m6-u06-expedition-location-detail-20260825`
- 代码/独立复审候选：`bf6dcfc3a6e11b1adf83678d051cd0170a3c794e`
- 精确白名单：`task_registry.yaml` 本任务 `owned_files` 的 15 个文件。

## 生产语义

- 江湖地图百草岭从直达远征总览改为先进入统一详情；idle/active 详情 CTA 均进入原 `ExpeditionOverviewScreen`。
- provider 只读真实存档、`expeditionConfigProvider`、`expeditionMaxDepthProvider`、`activeExpeditionProvider`、`expeditionCandidatesProvider` 与 `GameRepository`，不建立平行 fixture 或状态镜像。
- 统一详情展示生产解锁、历史/进行中深度、战败、方针、周目、基础推荐境界、普通/险关敌队、节点时长、由 `ExpeditionRules.rewardsForNode` 派生的实际奖励类别、候选人与 active 真实参与者。
- 当前生产规则被如实展示为仅支持单名非祖师门人差遣；该门人及冻结装备/心法持续占用至召回或战败返程。
- 隐藏门、配置/奖励定义、历史进度、候选、active save 归属、负深度/负周目、非单成员或悬空参与者、provider 异常均 fail closed，错误态不暴露进入 CTA；legacy 周目 0 兼容映射为第一周目。
- 原选人、方针、周目、离线推进、召回、战败结算、奖励、返程与 combat runner 未改。

## 红绿与验证证据

- 依赖安装/生成后，3 个目标因缺失新 domain/provider/screen/strings/route 真实编译失败：`0/3`；红测 commit `77b7f511`。
- 聚焦 provider/详情屏/地图：`19/19 PASS`。
- 详情屏含 `1280x720` 与 `1440x900` 双视口：`6/6 PASS`，其中双视口 `2/2`。
- 地图、远征与宗门入口相邻域：`211/211 PASS`。
- scoped analyze（8 项）：`0 issues`；根应用 `flutter analyze --no-pub lib test tool`：`0 issues`。
- 独立语义复审在候选 `bf6dcfc3` 上重跑聚焦 `19/19`、远征生产域 `59/59`、两组 scoped analyze 0；结论 `P0=0, P1=0, P2=0`，建议 READY。
- 最终全量只运行一次：`flutter test --no-pub --reporter compact` → `5490/5490 PASS`。
- truth-source guard、`git diff --check`、registry YAML 解析与精确白名单检查在 READY 前终检。

## 边界与未关闭项

- 当前远征仍只支持单名非祖师门人差遣和 headless 战斗；不新增亲战、前台 bot、多人、新自动化、参与者 policy 或渐进解锁决策。
- 不修改 schema/saveVersion、YAML、`TUNING/candidate`、奖励数值、经济、战斗、主线或 main。
- 本证据只关闭百草岭统一地点详情首缺口；江湖恩怨统一详情、U06、U14、M5、M6 与整体二阶段仍开放。
- 双视口 widget 测试不替代真实运行时截图、Profile、Windows 或长时间离线证据；这些仍属后续 Gate。
