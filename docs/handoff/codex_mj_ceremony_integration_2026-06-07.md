# Codex MJ 仪式素材第二批接入 2026-06-07

## 范围

- 分支：`codex/t11-inventory-section-header`
- 素材来源：`assets/ui/mj/ceremony_*`
- 本批只接入仪式页底图，不处理 `battle_fx` / `overlay` / `ui_parts`。
- 关键中文仍由 Flutter 字体渲染，MJ 图只作底景；统一用半透明宣纸面遮盖伪文字。

## 代码改动

- `lib/shared/theme/wuxia_tokens.dart`
  - 新增 9 个 `ceremony*` asset token。
- `lib/shared/widgets/wuxia_ui/ceremony_image_panel.dart`
  - 新增 `CeremonyImagePanel`，用于“MJ 底图 + 宣纸遮罩 + Flutter 正文”。
- `lib/features/battle/presentation/victory_overlay.dart`
  - 胜 / 败结算卡接入 `ceremony_victory_tag_01` / `ceremony_failure_ink_01`。
- `lib/features/mainline/presentation/stage_victory_dialog.dart`
  - 首通封签接入 `ceremony_boss_first_victory_01`。
  - 共鸣晋阶接入 `ceremony_equipment_resonance_01`。
- `lib/features/cultivation/presentation/advancement_summary.dart`
  - 多角色升层 banner 接入 `ceremony_realm_breakthrough_01`。
- `lib/features/technique_panel/presentation/technique_panel_screen.dart`
  - 凝练领悟小帖接入 `ceremony_technique_scroll_01`。
- `lib/features/encounter/presentation/encounter_dialog.dart`
  - 奇遇 outcome toast 接入 `ceremony_insight_bamboo_01`。
- `lib/features/seclusion/presentation/retreat_result_screen.dart`
  - 闭关收功 hero 接入 `ceremony_offline_retreat_result_01`。

## 测试改动

- `test/features/battle/presentation/victory_overlay_test.dart`
- `test/features/mainline/presentation/stage_victory_dialog_test.dart`
- `test/features/seclusion/presentation/retreat_result_screen_test.dart`
- `test/features/encounter/presentation/encounter_outcome_banner_test.dart`
- `test/features/technique_panel/presentation/technique_panel_screen_test.dart`

补充 asset token 断言，防止后续误删仪式底图挂载。

## 验证

- `flutter analyze lib/shared/theme/wuxia_tokens.dart lib/shared/widgets/wuxia_ui/ceremony_image_panel.dart lib/shared/widgets/wuxia_ui/wuxia_ui.dart lib/features/battle/presentation/victory_overlay.dart lib/features/mainline/presentation/stage_victory_dialog.dart lib/features/cultivation/presentation/advancement_summary.dart lib/features/technique_panel/presentation/technique_panel_screen.dart lib/features/encounter/presentation/encounter_dialog.dart lib/features/seclusion/presentation/retreat_result_screen.dart test/features/battle/presentation/victory_overlay_test.dart test/features/mainline/presentation/stage_victory_dialog_test.dart test/features/seclusion/presentation/retreat_result_screen_test.dart test/features/encounter/presentation/encounter_outcome_banner_test.dart test/features/technique_panel/presentation/technique_panel_screen_test.dart`
- `flutter test test/features/battle/presentation/victory_overlay_test.dart test/features/mainline/presentation/stage_victory_dialog_test.dart test/features/seclusion/presentation/retreat_result_screen_test.dart test/features/encounter/presentation/encounter_outcome_banner_test.dart test/features/technique_panel/presentation/technique_panel_screen_test.dart`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=battle_victory_first_clear`
- `flutter run -d macos --dart-define=VISUAL_ROUTE=seclusion_result`
- `flutter run -d macos --dart-define=VISUAL_ROUTE=battle_victory_first_clear`
- `flutter run -d macos --dart-define=VISUAL_ROUTE=technique_refine_insight_dialog`

## 视觉截图

- `docs/handoff/codex_mj_ceremony_integration_2026-06-07/seclusion_result_ceremony_full.png`
- `docs/handoff/codex_mj_ceremony_integration_2026-06-07/battle_victory_first_clear_ceremony_full.png`
- `docs/handoff/codex_mj_ceremony_integration_2026-06-07/technique_refine_insight_dialog_ceremony_full.png`

结论：

- 三张截图均在扩展屏真实 app 窗口截取。
- 无红屏、无 debug banner、无明显 overflow。
- 伪文字没有作为关键内容出现，Flutter 中文正文可读。
- `battle_victory_first_clear` 仍保留既有偏窄 preview 构图；本批只替换卡片底图，不扩大胜利弹窗。

## 后续

- 第三批再处理 `battle_fx` 与 `overlay`，先做透明 / 混合 / mask 预处理后再接战斗动画层。
- `ui_parts` Boss 头像框需要单独做透明通道或裁切后再接入。
