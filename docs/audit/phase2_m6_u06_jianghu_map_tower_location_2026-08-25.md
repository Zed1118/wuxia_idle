# P2 M6 U06 江湖地图九霄塔地点 READY 审计

- 日期：2026-08-25
- 基线：`ee51cf06baf96967b1db8882ced96f74be9ce833`
- 分支：`codex/phase2-m6-u06-jianghu-map-tower-location-20260825`
- 代码候选：`f58d2c77dfc85420eaa09f9ca687182bdf718578`
- 结论：`READY_REVIEWED`

## 产品结果

“继续江湖”仍是一级卡片的直达当前关主动作；同卡片内新增次级“江湖地图”动作，没有新增第五个一级 `WuxiaInkButton`。九霄塔已离开主菜单平铺区，成为 `JianghuMapScreen` 的首个生产地点。塔状态继续由 `towerProgressProvider` / `TowerProgressService` / 生产仓库数据派生，点击仍经 `guardBattleEntry` 进入原 `TowerFloorListScreen`。

## 红绿与修复链

- 真实红测：`main_menu_jianghu_map_tower_location_test.dart` 在生产改动前 `0/2`，分别证明九霄塔仍平铺、地图次级动作不存在。
- 转绿：新增地图/入口 `8/8`；变更、主菜单与纸面审计联合 `63/63`；主菜单/江湖地图/九霄塔相邻回归 `210/210`。
- 首轮全量为 `5376/5377`，唯一失败是 `audit_paper_text_contrast_test.dart` 精确指出新地图纸面容器两处误用 `WuxiaColors.text*`。未将此失败冒充通过。
- 修复为 `WuxiaUi.ink` / `WuxiaUi.muted` 后，精确纸面对比审计 `4/4`，最终完整全量 `5377/5377 PASS`。

## 门禁和复核

- `flutter analyze --no-pub lib test tool`：0 issue。
- 根应用 `flutter analyze --no-pub`：0 issue。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。
- 独立修复后复核：P0=0、P1=0、P2=0，建议 READY。
- 未改 schema/saveVersion、YAML、数值、概率、奖励、经济、解锁或叙事；未改 `main` / `origin/main`。

## 边界

本候选只证明九霄塔首地点纵切。轻功、群战、断魂庄、远征、商店/声望及统一地点详情仍未迁移；U06、U14、M6 与二阶段仍保持开放。
