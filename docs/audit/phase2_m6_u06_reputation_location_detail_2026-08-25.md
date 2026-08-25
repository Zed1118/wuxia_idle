# P2-M6-U06 江湖恩怨统一地点详情审计

## 交付身份

- 任务：`P2-M6-U06-REPUTATION-LOCATION-DETAIL`
- 基线：`5966e2348987a87bf1e61b237bc209f17ee85716`
- 分支：`codex/phase2-m6-u06-reputation-location-detail-20260825`
- 代码/最终独立复审候选：`a358571228460c8719144987753bc7e350e33abb`
- 精确白名单：`task_registry.yaml` 本任务 `owned_files` 的 15 个文件。

## 生产语义

- 江湖地图“江湖恩怨”从直达声望面板改为先进入统一详情；详情 CTA 仍进入原 `ReputationPanelScreen`。
- provider 只读第一章末关 gate、`GameRepository.factionDefs`、`numbersConfigProvider`、`reputationServiceProvider` 与 `reputationsForCurrentPlayerProvider`，不建立平行 fixture、状态镜像或写路径。
- 统一详情展示生产六门派、playerId=1 稀疏持久声望、七阶连续区间及现有 Boss/互动声望来源；没有持久行的门派明确保持未记录，不自动补零。
- 第一章未通、repository/service 缺失、门派数量不是六个、门派 ID/名称/立场、七阶连续覆盖、trigger、player/faction/value、重复或未知持久行异常以及 provider 错误均 fail closed，错误态不暴露进入 CTA。
- 当前地点入口没有冻结的 NPC relation source character 身份；详情明确不猜测当前角色或仇敌数量。
- 原声望写入、`[-100,+100]` clamp、tier 映射、Boss/encounter 触发、NPC 关系战斗倍率与原声望面板未改。

## 红绿、复审与验证证据

- 3 个目标因缺失新 domain/provider/screen/strings/route 真实编译失败：`0/3`；红测 commit `a154f8e5`。
- 初始候选 `3c94eb0c` 的首轮独立复审为 `P0=0, P1=0, P2=1`：门派定义不是六个时未 fail closed。
- 新增复审红测在缺失公开校验器时真实编译失败：`0/1`；红测 commit `bc998a29`。修复后强制恰六门派，最终候选 `a3585712`。
- 聚焦 provider/详情屏/地图逐文件：`10/10 + 5/5 + 4/4 = 19/19 PASS`。
- 江湖地图、声望、主菜单与声望写线相邻域：`268/268 PASS`；双视口 `2/2`。
- scoped analyze（8 项）与根应用 `flutter analyze --no-pub lib test tool`：均 `0 issues`。
- 最终独立复审重跑聚焦 `19/19`、生产相邻链 `42/42`、两组 scoped analyze 0；结论 `P0=0, P1=0, P2=0`，建议 READY。
- 最终全量只运行一次：`flutter test --no-pub --reporter compact` → `5505/5505 PASS`，耗时 4:17。
- truth-source guard、`git diff --check`、registry YAML 解析与精确白名单检查在 READY 前终检。

## 边界与未关闭项

- 不新增 NPC 关系面板，不猜测当前 source character 或仇敌数量，不改变声望/关系生产写入或战斗效果。
- 不修改 schema/saveVersion、YAML、`TUNING/candidate`、奖励数值、经济、战斗、主线或 main。
- 本证据只关闭当前六个生产地点的统一详情首轮覆盖；其他未迁移野外内容、U06、U14、M6 与整体二阶段仍开放。
- 双视口 widget 测试不替代真实运行时截图、Profile、Windows 或无障碍人工验收；这些仍属后续 Gate。
