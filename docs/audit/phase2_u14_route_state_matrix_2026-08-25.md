# Phase 2 U14 六模式入口全状态路由收口审计

## 结论

`P2-M6-U14-ROUTE-STATE-MATRIX` 固定验收门由 `0/1` 关闭为 `1/1`，状态 `READY`。五个江湖活动地点与心魔角色入口现已对适用的 `loading/hidden/locked/open/active/complete/error/zero-eligible` 状态形成生产路由证据；异步 provider 未决或异常时不再暴露可操作入口。

- branch: `codex/phase2-u14-route-state-matrix-20260825`
- base: `837be271bd0a7f3c6fb058245b6e3dc57cf2e00c`
- code candidate: `2496dd2f2202259eb920912d2e5fdfd30f1f408f`
- 异步边界：`2/12 → 12/12`
- U14 权威门：仍 `0/1 BLOCKED`
- 顶层 M0–M9：仍 `1/10`

## 适用状态矩阵

| 状态 | 生产入口与结果 |
| --- | --- |
| loading | 塔、轻功、守城、断魂庄、百草岭地图卡片 disabled 且 `onTap == null`；心魔角色入口隐藏 |
| hidden | 断魂庄/百草岭沿既有江湖游历隐藏门隐藏；心魔首节点前及主菜单均无入口 |
| locked | 轻功/守城沿既有主线门槛禁用且不导航 |
| open | 五地点进入各自统一详情；心魔只从当前角色突破入口进入 |
| active | 断魂庄/百草岭显示真实 active 状态并进入原恢复路径 |
| complete | 塔/轻功/守城保留重打；心魔全通后无 CTA |
| error | 五地点地图入口和详情均 fail closed；心魔角色入口隐藏 |
| zero-eligible | 五地点 idle CTA 全禁用；断魂庄/百草岭 active 恢复不受当前零候选影响 |

这些状态继续消费既有 `towerProgressProvider`、`mainlineProgressProvider`、`activeGauntletProvider`、`activeExpeditionProvider`、`mainMenuSaveSnapshotProvider` 与 `innerDemonProgressProvider`。本门只把现有 AsyncValue 是否已取得数据纳入按钮 enabled/onTap 派生，没有新建 provider、路由或业务真相源。

## RED 与验证证据

- 修正测试夹具后的首轮 RED：`50 PASS / 10 FAIL`；10 个失败精确对应五地点 loading/error 两格，心魔两格已通过。
- 异步边界定向 green：`60/60 PASS`，其中新增固定分母 `12/12`。
- 六模式适用状态路由集合：`117/117 PASS`。
- 江湖地图 + 角色面板 + 心魔相邻域：`256/256 PASS`。
- `flutter analyze --no-pub lib test`：`0 issue`。
- `git diff --check`：通过。

遵守 90 分钟成本停止线，未重复运行多小时整仓全量。风险匹配验证已覆盖入口、详情、角色面板、心魔 typed 手动入口和相关 provider。

## 上级门仍被阻塞

入口全状态路由已闭环，但 U14 同时要求六模式允许矩阵由真实生产 admission 消费。前三个阻塞保持不变：

1. 九霄塔缺首通后玩家可达的 automation runner / typed admission。
2. 轻功缺首通后 bot/headless/差遣 runner / typed admission。
3. 守城缺首通后 bot/headless/差遣 runner / typed admission。

## 非变更边界

本门未改 schema/saveVersion、YAML、TUNING/candidate、奖励、经济、解锁、叙事或战斗规则，未新增 reducer、session、headless 内核、provider、policy 表或 settlement 真相源，未修改 main。
