# Codex MJ red seal integration handoff (2026-06-07)

分支：`codex/t11-inventory-section-header`

## 本批完成

- 预处理并新增透明红印：
  - `assets/ui/mj/ceremony_red_seal_blend.png`
- `WuxiaUi.ceremonyRedSeal` 改为指向透明版，避免原图黑色桌面背景进入 UI。
- `VictoryOverlay` 顶部小印章改用 MJ 红印，保留 Flutter 渲染的 `武`。
- `FirstClearBanner` 右侧新增 MJ 红印，首胜标题和副标题仍由 Flutter 字体渲染。
- 测试新增红印 asset 断言：
  - `victory_overlay_test.dart`
  - `stage_victory_dialog_test.dart`

## 验证

- `dart format lib/shared/theme/wuxia_tokens.dart lib/features/battle/presentation/victory_overlay.dart lib/features/mainline/presentation/stage_victory_dialog.dart test/features/battle/presentation/victory_overlay_test.dart test/features/mainline/presentation/stage_victory_dialog_test.dart`
- `flutter analyze lib/shared/theme/wuxia_tokens.dart lib/features/battle/presentation/victory_overlay.dart lib/features/mainline/presentation/stage_victory_dialog.dart test/features/battle/presentation/victory_overlay_test.dart test/features/mainline/presentation/stage_victory_dialog_test.dart`
- `flutter test test/features/battle/presentation/victory_overlay_test.dart test/features/mainline/presentation/stage_victory_dialog_test.dart test/widget_test.dart`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=battle_boss_frame`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=battle_victory_first_clear`

说明：首次并行 build 时 `battle_victory_first_clear` 因 Xcode `build.db` 锁冲突失败，随后顺序补跑通过。

## 视觉验收截图

- `docs/handoff/codex_mj_red_seal_integration_2026-06-07/01_first_clear_red_seal.png`
- `docs/handoff/codex_mj_red_seal_integration_2026-06-07/02_battle_victory_red_seal.png`

观察结论：

- 扩展屏截图无红屏、无 debug banner、无明显 overflow。
- 首通封签右侧红印无黑底，不遮挡 `首胜 · 风雨渡口`。
- 战斗结算顶部红印无黑底，中央 `勝` 仍由 Flutter 字体渲染。

## 仍未接入 / 待下一批处理

- `assets/ui/mj/menu_mountain_gate_01.png`
- `assets/ui/mj/menu_mountain_gate_wide_01.png`：已有 `WuxiaUi.mainMenuMountainBg` token，但当前未实际使用。
- `assets/ui/mj/menu_splash_pier_02.png`

建议下一批做主菜单背景 A/B 对比：现用 `menu_splash_pier_01.png` 已验收通过，剩余 3 张都属于门面/备用背景，不应硬塞到非门面页面。
