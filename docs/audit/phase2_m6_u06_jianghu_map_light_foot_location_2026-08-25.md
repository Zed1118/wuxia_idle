# P2 M6 U06 江湖地图轻功地点 READY 审计

- 日期：2026-08-25
- 基线：`269e1baaad6b89544c90c66b8f86815ecb8c54ca`
- 分支：`codex/phase2-m6-u06-jianghu-map-light-foot-location-20260825`
- 代码候选：`79466fca7c7497ce190856223070aa8f791b99c6`
- 结论：`READY_REVIEWED`

## 产品结果

“轻功试炼”已离开主菜单平铺区，成为 `JianghuMapScreen` 的第二个生产地点。地点状态只从 `MainlineProgress`、生产 `LightFootDef` 和 `LightFootService` 派生，不在地图复制 `stage_06_05` 门槛；加载未决、空链、异常前置或孤立进度均 fail closed。解锁后点击仍经 `guardBattleEntry` 进入原 `LightFootScreen`。

## 红绿与基础设施事实

- fresh worktree 首次测试在执行用例前因缺少 `.dart_tool/package_config.json` 报 `Bad state: No element`；离线解析根依赖后又因缺少生成的 `.g.dart` 在编译前失败。运行离线依赖解析与 `build_runner` 后恢复测试基础设施；这两次均不计作红测。
- 真实红测：`main_menu_jianghu_map_light_foot_location_test.dart` 在生产改动前 `0/3`，分别证明主菜单仍平铺轻功、地图无锁定地点、解锁后无地图路由。
- 转绿：轻功地点与地图联合 `10/10`；纸面对比审计 `4/4`；合计 `14/14`。
- 主菜单、江湖地图与轻功相邻回归 `116/116`。
- 最终完整全量 `5382/5382 PASS`。

## 门禁和复核

- `flutter analyze --no-pub lib test tool`：0 issue。
- 根应用 `flutter analyze --no-pub`：为退役隔离探针补齐其 fresh package metadata 后 0 issue；未把此前 1943 条依赖解析噪声冒充业务缺陷或通过。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。
- 独立复核：P0=0、P1=0、P2=0，建议 READY。其记录的非阻断缺口是未单列 provider loading/error widget 红测；实现已通过 `maybeWhen(... orElse: null)` fail closed，且不改变 READY 结论。
- 未改 schema/saveVersion、YAML、数值、概率、奖励、经济、解锁或叙事；未改 `main` / `origin/main`。

## 边界

本候选只证明轻功第二地点纵切。群战、断魂庄、远征、商店/声望及统一地点详情仍未迁移；U06、U14、M5、M6 与二阶段仍保持开放。
