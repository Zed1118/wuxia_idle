# Codex MJ 素材接入记录 2026-06-07

## 范围

- 素材来源：`/Users/a10506/Downloads/autojourney/筛选留用_37组_2026-06-07`
- 本轮接入第一批低风险素材：主菜单背景、主入口缩略图、仪式/特效/头像框资源入库。
- 战斗特效、仪式底图本轮仅入库，未直接接动画或结算弹层，避免纸底/伪文字素材未经处理影响画面。

## 代码改动

- `pubspec.yaml`
  - 显式声明 `assets/ui/mj/` 与 `assets/scenes/mj/`。
- `lib/shared/theme/wuxia_tokens.dart`
  - 新增 MJ 主菜单背景与入口缩略图 asset token。
- `lib/shared/widgets/wuxia_ink_button.dart`
  - `WuxiaInkButton` 新增 `thumbnailPath`。
  - 有缩略图时左侧显示固定宽度地点/系统缩略图，并保留原语义图标叠层。
- `lib/features/main_menu/presentation/main_menu.dart`
  - 主菜单背景切换为 `menu_splash_pier_01.png`。
  - 主线、角色、装备、心法、闭关、爬塔、轻功、江湖志等入口接入缩略图。
- `test/shared/widgets/wuxia_ink_button_test.dart`
  - 增加 `thumbnailPath` 渲染与保留图标测试。

## 资源入库

- `assets/ui/mj/`：38 张。
- `assets/scenes/mj/`：1 张。

## 视觉截图

- `docs/handoff/codex_mj_asset_integration_2026-06-07/01_main_menu_mj_assets.png`
  - 旧版山门背景截图。中央黑色笔触干扰标题，不作为最终门面选择。
- `docs/handoff/codex_mj_asset_integration_2026-06-07/02_main_menu_mj_assets_clean_bg.png`
  - 新版码头雾景背景截图。标题区域干净，入口图正常加载。

## 验证

- `flutter analyze lib/features/main_menu/presentation/main_menu.dart lib/shared/widgets/wuxia_ink_button.dart lib/shared/theme/wuxia_tokens.dart`
- `flutter analyze lib/features/main_menu/presentation/main_menu.dart lib/shared/widgets/wuxia_ink_button.dart lib/shared/theme/wuxia_tokens.dart test/shared/widgets/wuxia_ink_button_test.dart`
- `flutter test test/shared/widgets/wuxia_ink_button_test.dart test/features/main_menu/presentation/main_menu_test.dart`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=main_menu`

## 后续

1. 接 `ceremony` 到胜利、首通、突破、领悟、闭关收功等界面，注意遮盖伪文字。
2. 对 `battle_fx`、`overlay` 做透明/混合预处理，再接战斗动画层。
3. `ui_parts` 头像框单独做 mask 后再接 Boss 头像。
