# P2 M6 U06 江湖地图断魂庄地点 READY 审计

- 日期：2026-08-25
- 基线：`cec23572e10bb3f47eff7a1875f6b4a6abec490a`
- 分支：`codex/phase2-m6-u06-jianghu-map-gauntlet-location-20260825`
- 代码候选：`c06489f2ec79caf7766959a3431f75da6b228ac2`
- 结论：`READY_REVIEWED`

## 产品结果

“断魂庄”已离开主菜单平铺区，成为 `JianghuMapScreen` 的第四个生产地点。地点可见性只读 `mainMenuSaveSnapshotProvider` 中既有 `SaveData.jianghuJourneyUnlocked`，加载未决、异常或空值均 fail closed；进行中状态只读 `activeGauntletProvider` 并覆盖四个 `GauntletPhase`。点击仍直达既有 `GauntletLoadoutScreen`，由原页面处理新建与崩溃恢复。

## 红绿与修复链

- fresh worktree 先离线补齐根依赖、生成件和隔离探针 package metadata；这些是测试基础设施准备，不计作红测。
- 首次批次因测试 fixture 未调用 `loadTestGameRepository` 而无效，不计证据。修正 fixture 后重跑为 `1/4`，三项真实红测分别证明断魂庄仍在主菜单、地图没有断魂庄地点、地图没有生产路由；未解锁隐藏案例保持绿色。
- 转绿：断魂庄门控与地图 `15/15`，纸面对比审计 `4/4`，合计 `19/19`；地图、断魂庄与主菜单联合 `66/66`；主菜单、江湖地图与断魂庄相邻域 `299/299`。
- 最终完整全量 `5391/5391 PASS`。

## 门禁和复核

- `flutter analyze --no-pub lib test tool`：0 issue。
- 根应用 `flutter analyze --no-pub`：0 issue。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。
- 独立复核：`P0=0 / P1=0 / P2=0`，建议 READY；额外复跑地图、主菜单、宗门 Hub 与继续江湖 `85/85`，确认断魂庄恢复语义、宗门远征门控和精确白名单未漂移。
- 未改 schema/saveVersion、YAML、调优、数值、参与者、阵型、战斗、概率、奖励、经济、解锁或叙事；未开放前台 bot 或代选奖励；未改 `main` / `origin/main`。

## 边界

本候选只证明断魂庄第四地点纵切。远征、商店/声望及统一地点详情仍未迁移；U06、U14、M5、M6 与二阶段仍保持开放。

`[READY][CODEX][P2-M6-U06-JIANGHU-MAP-GAUNTLET-LOCATION] 迁移断魂庄到江湖地图`
