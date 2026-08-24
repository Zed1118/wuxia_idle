# P2 M6 U06 江湖地图百草岭远征地点 READY 审计

- 日期：2026-08-25
- 基线：`0f7e576c1a9b5c77f0b4b68eaa00d4721d542a04`
- 分支：`codex/phase2-m6-u06-jianghu-map-expedition-location-20260825`
- 代码候选：`77292fb3ee897bcd727cb8072adad2f0d878c144`
- 结论：`READY_REVIEWED`

## 产品结果

“百草岭”已作为 `JianghuMapScreen` 的第五个生产地点出现。可见性只读 `mainMenuSaveSnapshotProvider` 中既有 `SaveData.jianghuJourneyUnlocked`，加载未决、异常或空值均 fail closed；进行中状态只读 `activeExpeditionProvider`，复用既有深度/战败文案。点击仍进入 `ExpeditionOverviewScreen`。

宗门 Hub 的“江湖远行”派遣/管理入口保留，与地图“百草岭”共享同一生产页和会话真相源。

## 红绿与验证

- fresh worktree 先离线补齐根依赖、生成件和隔离探针 package metadata；这些是测试基础设施，不计红测。
- 真实红测 `1/4`：未解锁隐藏案例绿色，三项目标行分别精确失败于无地点、无 active 深度和无生产路由。
- 转绿：地图与百草岭 `16/16`，纸面对比 `4/4`，合计 `20/20`；地图、远征总览与宗门 Hub 联合 `38/38`；完整远征相邻域 `136/136`。
- 最终完整全量 `5396/5396 PASS`。

## 门禁和复核

- `flutter analyze --no-pub lib test tool`：0 issue。
- 根应用 `flutter analyze --no-pub`：0 issue。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。
- 独立复核：`P0=0 / P1=0 / P2=0`，建议 READY；额外复跑地图远征、地图相邻、主菜单与宗门 Hub `79/79`，确认双入口共享同一生产页且精确白名单未漂移。
- 未改远征 schema/saveVersion、YAML、调优、数值、参与者、占用、节点、战斗、召回、伤势、奖励、经济、解锁、记录或离线推进；未改 `main` / `origin/main`。

## 边界

本候选只证明百草岭第五地点纵切。商店/声望、其他地点及统一地点详情仍未迁移；U06、U14、M5、M6 与二阶段仍保持开放。

`[READY][CODEX][P2-M6-U06-JIANGHU-MAP-EXPEDITION-LOCATION] 接入百草岭远征地点`
