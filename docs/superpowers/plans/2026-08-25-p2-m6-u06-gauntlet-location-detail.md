# P2-M6-U06 断魂庄统一地点详情实施计划

## 目标

在江湖地图与现有 `GauntletLoadoutScreen` 之间接入统一地点详情，只读展示断魂庄生产进度、推荐境界、三关敌情、核心奖励、断魂帖、可用参与者、亲战方式和会话占用。进行中庄局要显示关次、阶段与真实参与者，CTA 仍进入原整备屏，保留选人、补给、周目、续战、战斗、结算与奖励选择全部现有语义。

## 基线与白名单

- 基线：`7f57d5be2cb9d7388dd53160ffdcda6b8de26ab7`
- 分支：`codex/phase2-m6-u06-gauntlet-location-detail-20260825`
- 工作树：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u06-gauntlet-location-detail`
- 精确 16 文件白名单以 `task_registry.yaml` 本任务 `owned_files` 为准。

## 实施步骤

1. 先增 provider、详情屏和地图/主菜单路由测试，确认新生产合同缺失的真实红测。
2. 新增纯展示 domain DTO 与 provider，复用 `gauntletConfigProvider`、`gauntletCandidatesProvider`、`activeGauntletProvider` 和 `gauntletLoadoutInfoProvider` 的生产语义。
3. 对隐藏门、配置引用、进行中参与者和 provider 异常 fail closed，错误态不显示 CTA。
4. 地图断魂庄改为先进详情；详情 CTA 直接进入现有 `GauntletLoadoutScreen`，不添加与断魂庄候选人逻辑冲突的掌门门禁。
5. 运行聚焦、纸面生产对比、相邻域、双视口、两层 analyze 和一次最终全量。
6. 独立语义复审后同步 audit/registry/CLAUDE/GDD/PROGRESS，通过精确白名单与 clean 门禁后产出 `[READY]`。

## 边界

- 不新增差遣、前台 bot、自动化 UI、角色 policy 或渐进解锁决策。
- 不修改 schema/saveVersion、YAML、TUNING/candidate、奖励数值、经济、战斗、主线或 main。
- 只关闭断魂庄统一地点详情首缺口，不晋升 U06、U14、M5、M6 或二阶段整体状态。
