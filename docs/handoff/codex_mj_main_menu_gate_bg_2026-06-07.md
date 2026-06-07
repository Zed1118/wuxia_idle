# Codex MJ main menu gate background handoff (2026-06-07)

分支：`codex/t11-inventory-section-header`

## 本批完成

- 主菜单背景从渡口图切到山门图的清理版：
  - `assets/ui/mj/menu_mountain_gate_clean_01.png`
- 新增 / 整理 token：
  - `WuxiaUi.mainMenuBg` → `menu_mountain_gate_clean_01.png`
  - `WuxiaUi.mainMenuPierBg` → `menu_splash_pier_01.png`
  - `WuxiaUi.mainMenuPierAltBg` → `menu_splash_pier_02.png`
  - `WuxiaUi.mainMenuMountainBg` → `menu_mountain_gate_01.png`
  - `WuxiaUi.mainMenuMountainWideBg` → `menu_mountain_gate_wide_01.png`
- `main_menu_test.dart` 新增主菜单背景 asset 断言，锁定 `WuxiaUi.mainMenuBg` 被实际渲染。

## 素材取舍

- `menu_mountain_gate_01.png`：原图中上部有 MJ 伪字，直接接入后会落在主菜单标题 / 提示区域。本批用 OpenCV inpaint 生成 clean 版，只清理中心伪字，不动山门、松树和山体主体。
- `menu_splash_pier_02.png`：右下红色伪印和左下伪字明显，暂作备用，不接正式 UI。
- `menu_mountain_gate_wide_01.png`：中央大伪字更明显，暂作备用，不接正式 UI。
- `menu_splash_pier_01.png`：上一批已验收通过，保留为 `mainMenuPierBg` 备用。

## 验证

- `dart format lib/shared/theme/wuxia_tokens.dart test/features/main_menu/presentation/main_menu_test.dart`
- `flutter analyze lib/shared/theme/wuxia_tokens.dart lib/features/main_menu/presentation/main_menu.dart test/features/main_menu/presentation/main_menu_test.dart`
- `flutter test test/features/main_menu/presentation/main_menu_test.dart test/shared/widgets/wuxia_ink_button_test.dart`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=main_menu`

## 视觉验收截图

- `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07/01_main_menu_gate_bg.png`
  - 直接接原图时的诊断截图：伪字落在标题区域，不采用。
- `docs/handoff/codex_mj_main_menu_gate_bg_2026-06-07/02_main_menu_gate_bg_clean.png`
  - clean 版验收截图：无红屏、无 debug banner、无明显 overflow，中心伪字已消失。

## 仍未实际使用的 MJ 备用门面图

- `assets/ui/mj/menu_splash_pier_02.png`
- `assets/ui/mj/menu_mountain_gate_wide_01.png`

这两张不建议为了“接完”硬塞到非门面页面；当前保留 token 作为后续主菜单 A/B、章节封面或活动门面备用。
