# Phase 2 视觉目标→调试路由映射（2026-08-26）

基线：`c799b964`；分支：`codex/p2-a-visual-acceptance-20260826`。`NAV-ONLY` 以真实生产导航为准，涉及门控的路径需存档满足相应解锁/可用条件。

| 目标 | 状态 | 路由枚举名或导航入口 | 备注 |
|---|---|---|---|
| `main_menu.dart` | EXISTING | `VisualRoute.mainMenu` | 可直达生产主菜单 |
| `jianghu_map_screen.dart` | NAV-ONLY | `VisualRoute.mainMenu` → 江湖地图 | 主菜单真实入口 |
| `sect_hub_screen.dart` | NAV-ONLY | `VisualRoute.mainMenu` → 宗门 | 主菜单真实入口 |
| `martial_inventory_hub_screen.dart` | NAV-ONLY | `VisualRoute.mainMenu` → 武学与行囊 | 主菜单真实入口 |
| `jianghu_chronicle_hub_screen.dart` | NAV-ONLY | `VisualRoute.mainMenu` → 江湖纪事 | 主菜单真实入口 |
| `expedition_location_detail_screen.dart` | NAV-ONLY | `VisualRoute.mainMenu` → 江湖地图 → 百草岭 | 需远行门控解锁 |
| `gauntlet_location_detail_screen.dart` | NAV-ONLY | `VisualRoute.mainMenu` → 江湖地图 → 断魂庄 | 需远行门控解锁 |
| `light_foot_location_detail_screen.dart` | NAV-ONLY | `VisualRoute.mainMenu` → 江湖地图 → 轻功试炼 | 需轻功入口可用 |
| `mass_battle_location_detail_screen.dart` | NAV-ONLY | `VisualRoute.mainMenu` → 江湖地图 → 守城试炼 | 需守城入口可用 |
| `reputation_location_detail_screen.dart` | NAV-ONLY | `VisualRoute.mainMenu` → 江湖地图 → 江湖恩怨 | 需声望入口解锁 |
| `tower_location_detail_screen.dart` | NAV-ONLY | `VisualRoute.mainMenu` → 江湖地图 → 九霄塔 | 需塔入口可用 |
| `stage_entry_flow` | NAV-ONLY | `VisualRoute.stageList` → 可进入关卡 | `StageListScreen` 真实调用 `runStageFlow` |
| `stage_list_screen` | EXISTING | `VisualRoute.stageList` | 直接挂载 `StageListScreen` |
| `stage_victory_dialog` | NAV-ONLY | `VisualRoute.stageList` → 关卡→胜利结算 | `runStageFlow` 胜利后打开 |
| `tower_entry_flow` | NAV-ONLY | `VisualRoute.towerFloorList` → 可挑战塔层 | `TowerFloorListScreen` 真实调用塔入场流 |
| `sweep_screen` | NAV-ONLY | `VisualRoute.stageListCycle` → 已通关关卡→无人值守重打 | 亦可从 `towerCycle` 一键扫荡进入 |
| `phase0a_mainline_battle_host` | NAV-ONLY | `VisualRoute.stageList` → 可进入关卡→战斗 | 主线 flow 挂载真实 Host |
| `phase0a_battle_screen` | EXISTING | `VisualRoute.phase0aBattlePlayable` | 直接挂载可玩 Phase 0A 战斗屏 |
| `inner_demon_screen` | NAV-ONLY | `VisualRoute.characterPanelGrowth` → 突破 | 成长瓶颈种子已提供生产 CTA |
| `tower_floor_list_screen` | EXISTING | `VisualRoute.towerFloorList` | 直接挂载 `TowerFloorListScreen` |
| `mass_battle_screen` | NAV-ONLY | `VisualRoute.mainMenu` → 江湖地图→守城详情→进入 | 需可用参与者并通过入场守卫 |
| `light_foot_screen` | NAV-ONLY | `VisualRoute.mainMenu` → 江湖地图→轻功详情→进入 | 需有可用参与者 |
| `main_menu_status_summary` | EXISTING | `VisualRoute.mainMenu` | 面板嵌入 `MainMenu`，主线要事项提供可见状态 |
| `phase0a_visual_roster` | EXISTING | `VisualRoute.phase0aBattlePlayable` | 非 Widget；战斗屏真实消费名册绘制立绘/姓名 |
| `mainline_location_archive_screen` | NAV-ONLY | `VisualRoute.mainMenu` → 江湖纪事→主线地点 | Hub 真实入口 |
| `pending_jianghu_affairs_screen` | NAV-ONLY | `VisualRoute.mainMenu` → 江湖纪事→待处理江湖事 | Hub 真实入口 |
| `light_foot_participant_picker` | NAV-ONLY | 轻功详情→轻功列表→可挑战路线 | 挑战前真实 `PaperDialog` |
| `disciple_scheduling_screen` | NAV-ONLY | `VisualRoute.mainMenu` → 宗门→门人调度 | 亦可从门派谱进入 |
| `mass_battle_participant_picker` | NAV-ONLY | 守城详情→守城列表→可挑战关 | 挑战前真实 `PaperDialog` |
| `sect_itinerary_panel` | NAV-ONLY | `VisualRoute.mainMenu` → 宗门 | 嵌入 `SectHubScreen` 顶部 |
| `technique_panel_screen` | EXISTING | `VisualRoute.techniquePanelTierAll` | 亦有 `techniquePanelHero` |
| `expedition_recap_screen` | EXISTING | `VisualRoute.expeditionRecap` | 直接挂载只读返程结果 |
| `expedition_overview_screen` | EXISTING | `VisualRoute.expeditionOverview` | 亦有 active/cycle 状态路由 |
| `gauntlet_reward_screen` | EXISTING | `VisualRoute.gauntletReward` | 直接挂载待选奖励状态 |
| `lineage_panel_screen` | EXISTING | `VisualRoute.lineageCodex` | 直接挂载 `LineagePanelScreen` |

- EXISTING：11 个。
- NAV-ONLY：24 个。
- MISSING：0 个；因此未修改路由/Host/测试，也无 Dart 格式化对象。

## 自验

```text
$ flutter analyze
Analyzing 挂机武侠-p2-a-visual...
No issues found! (ran in 3.1s)
```

`flutter test --no-pub test/features/debug/visual_route_test.dart`：`+4: All tests passed!`
