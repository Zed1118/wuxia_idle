# P2 M6 U06 江湖地图守城地点 READY 审计

- 日期：2026-08-25
- 基线：`8207d4bcf1e73864b98c266500ea20a6e1acc275`
- 分支：`codex/phase2-m6-u06-jianghu-map-mass-battle-location-20260825`
- 代码候选：`e64ef14b182455379daaf7b71182d8bc47f1c8d8`
- 结论：`READY_REVIEWED`

## 产品结果

“守城试炼”已离开主菜单平铺区，成为 `JianghuMapScreen` 的第三个生产地点。地点状态只从 `MainlineProgress`、生产 `MassBattleDef` 和 `MassBattleService` 派生，不在地图复制 `stage_06_05` 门槛；加载未决、空链、异常前置或孤立进度均 fail closed。解锁后点击仍经 `guardBattleEntry` 进入原 `MassBattleScreen`。

## 红绿与修复链

- fresh worktree 先离线补齐根依赖、生成件和隔离探针 package metadata；这些是测试基础设施准备，不计作红测。
- 真实红测：`main_menu_jianghu_map_mass_battle_location_test.dart` 在生产改动前 `0/3`，分别证明守城仍平铺、地图无锁定地点、解锁后无地图路由。
- 转绿：守城地点与地图联合 `12/12`；纸面对比审计 `4/4`；合计 `16/16`。
- 首轮扩大主菜单/地图/群战回归为 `122/123`，唯一失败是前一轻功地点测试仍断言锁提示恰好 1 个；第三地点加入后实际为 2 个。将该相邻契约正式补入白名单并更新断言后，扩大回归 `123/123`。
- 最终完整全量 `5387/5387 PASS`。

## 门禁和复核

- `flutter analyze --no-pub lib test tool`：0 issue。
- 根应用 `flutter analyze --no-pub`：0 issue。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。
- 独立复核：P0=0、P1=0、P2=0，建议 READY；确认其他入口、群战阵型、战斗、奖励和经济未漂移，所有 diff 均在最终白名单内。
- 未改 schema/saveVersion、YAML、数值、阵型、概率、奖励、经济、解锁或叙事；未改 `main` / `origin/main`。

## 边界

本候选只证明守城第三地点纵切。断魂庄、远征、商店/声望及统一地点详情仍未迁移；U06、U14、M5、M6 与二阶段仍保持开放。
