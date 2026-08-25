# Phase 2 U14 六模式入口全状态路由结果合同

- 单一目标：五个江湖活动地点与心魔角色入口在适用的 `loading/hidden/locked/open/active/complete/error/zero-eligible` 状态下路由一致，异步数据未决或异常时 fail closed。
- 固定验收门：本入口路由子门 `0/1 → 1/1`；不得据此宣称六模式 automation 允许矩阵或 U14 权威门完成。
- 异步边界分母：五地点各 `loading/error` 2 格，加心魔角色入口 `loading/error` 2 格，共 `12/12`。
- 实时基线：心魔两格已隐藏 CTA；轻功/守城按钮视觉禁用但回调未置空；塔/断魂庄/百草岭在相关 provider 未决或异常时仍呈可进入。
- 既有状态复核：hidden 由断魂庄/百草岭隐藏门和心魔首节点前入口承担；locked 由轻功/守城承担；open 由六模式现有手动入口承担；active 由断魂庄/百草岭承担；complete 由塔/轻功/守城/心魔承担；zero-eligible 已有五地点 `5/5` 证据。
- 预期增量：只关闭入口全状态路由子门；U14 权威门仍因塔、轻功、守城缺真实 automation runner/admission 而 `0/1 BLOCKED`，顶层 M0–M9 仍 `1/10`。
- 成本上限：90 分钟；定向 RED/green、江湖地图+角色面板相邻域、应用 analyze、真相源守卫、双向白名单；不重复多小时整仓全量。
- 非目标：新 runner、admission、policy 表、provider、reducer、session、headless 内核、settlement 真相源、schema/saveVersion、YAML、TUNING、奖励、经济、解锁、叙事、战斗规则或 main。
