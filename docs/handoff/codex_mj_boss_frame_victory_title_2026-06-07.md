# Codex MJ boss frame / victory title handoff (2026-06-07)

分支：`codex/t11-inventory-section-header`

## 本批完成

- 修正战斗结算大题字：
  - `UiStrings.victoryTitle`: `胜` → `勝`
  - `UiStrings.defeatTitle`: `败` → `敗`
- 预处理并新增 2 张透明 Boss 外框：
  - `assets/ui/mj/ui_boss_frame_blend.png`
  - `assets/ui/mj/ui_big_boss_frame_blend.png`
- `CharacterAvatar` 对 `BattleCharacter.isBoss == true` 叠加 MJ 圆环外框。
- `WuxiaUi` 新增 boss frame tokens。
- 新增 / 更新测试：
  - 胜负 overlay 测试名称更新为繁体大字语义。
  - `widget_test.dart` 新增 Boss 头像叠加 MJ 圆环外框覆盖。

## 回归原因

之前只在视觉预览 `_VictorySealMark` 使用了 `勝`，实际战斗结算 `VictoryOverlay` 仍从 `UiStrings.victoryTitle` 读取简体 `胜`。本批已改字符串源头，所以所有使用 `VictoryOverlay` 的战斗结算都会一致显示 `勝`。

## 验证

- `dart format lib/shared/theme/wuxia_tokens.dart lib/shared/strings.dart lib/features/battle/presentation/victory_overlay.dart lib/features/battle/presentation/character_avatar.dart test/features/battle/presentation/victory_overlay_test.dart test/widget_test.dart`
- `flutter analyze lib/shared/theme/wuxia_tokens.dart lib/shared/strings.dart lib/features/battle/presentation/victory_overlay.dart lib/features/battle/presentation/character_avatar.dart test/features/battle/presentation/victory_overlay_test.dart test/widget_test.dart`
- `flutter test test/features/battle/presentation/victory_overlay_test.dart test/widget_test.dart test/features/battle/presentation/battle_screen_log_test.dart`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=battle_boss_frame`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=battle_scene`

说明：首次并行 build 时 `battle_scene` 因 Xcode `build.db` 锁冲突失败，随后顺序补跑通过。

## 视觉验收截图

- `docs/handoff/codex_mj_boss_frame_victory_title_2026-06-07/01_battle_boss_frame_victory_title.png`

观察结论：

- 扩展屏截图无红屏、无 debug banner、无明显 overflow。
- 战斗结算中央大题字已显示 `勝`。
- Boss 头像圆环外框已实际渲染，无方块底；结算暗角下视觉较克制，asset 挂载由 widget test 锁定。

## 仍未接入 / 待下一批处理

- `assets/ui/mj/ceremony_red_seal_01.png`
- `assets/ui/mj/menu_mountain_gate_01.png`
- `assets/ui/mj/menu_splash_pier_02.png`

`menu_mountain_gate_wide_01.png` 已有 token，但还没有实际切到主菜单首屏，可与 `menu_mountain_gate_01.png` 一起做菜单 / 章节入口备用门面图。
