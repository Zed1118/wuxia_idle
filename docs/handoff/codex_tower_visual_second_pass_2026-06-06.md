# Codex 爬塔界面二次包装交接（2026-06-06）

## 范围

本轮聚焦 `TowerFloorListScreen` 主体列表，不改变爬塔挑战流程：

- 将原满宽行列表改为宽屏“中轴塔脊 + 左右石阶”布局。
- 每层节点保留原有三态：已通 / 可挑战 / 锁定。
- Boss 层保留小 Boss / 大 Boss chip，并改成更强的关口视觉：方形节点、左侧醒目标识、金 / 紫边框。
- 窄屏自动回退单列，避免移动或窄窗口挤压。
- 原行为不变：available 直接挑战，locked 不响应，cleared 弹重打确认。

## 改动文件

- `lib/features/tower/presentation/tower_floor_list_screen.dart`
- `lib/features/tower/presentation/tower_floor_card.dart`

## 验证

- `flutter test test/features/tower/presentation/tower_floor_list_screen_test.dart`
- `flutter analyze lib/features/tower/presentation/tower_floor_card.dart lib/features/tower/presentation/tower_floor_list_screen.dart test/features/tower/presentation/tower_floor_list_screen_test.dart`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=tower_floor_list`

## 截图

- `docs/handoff/codex_tower_visual_second_pass_2026-06-06/01_tower_stepped_spine.png`

## 结论

通过。爬塔主体从工程列表转为更贴合“登塔”的视觉结构，同时保留原测试覆盖的挑战、锁定和重打路径。
