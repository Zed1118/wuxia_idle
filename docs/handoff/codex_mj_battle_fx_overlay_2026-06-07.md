# Codex MJ battle fx / overlay integration handoff (2026-06-07)

分支：`codex/t11-inventory-section-header`

## 本批完成

- 预处理并新增 14 张 `_blend.png`：
  - `fx_gangmeng_strike_blend.png`
  - `fx_gangmeng_ultimate_blend.png`
  - `fx_lingqiao_slash_blend.png`
  - `fx_lingqiao_ultimate_blend.png`
  - `fx_yinrou_palm_blend.png`
  - `fx_yinrou_ultimate_blend.png`
  - `fx_critical_hit_blend.png`
  - `fx_armor_break_blend.png`
  - `fx_dodge_shadow_blend.png`
  - `fx_internal_injury_blend.png`
  - `overlay_mist_layer_blend.png`
  - `overlay_ink_cloud_blend.png`
  - `overlay_lantern_glow_blend.png`
  - `overlay_low_health_blend.png`
- 新增 `BattleEffectSprite`：命中边沿短生命周期 MJ 贴片，使用 RGBA alpha，不做白色 screen 混合。
- 新增 `BattleAtmosphereOverlay`：战斗全屏轻雾、远灯、Boss 墨云、低血暗角氛围层。
- `BattleScreen` 接入特效映射：
  - 闪避：`fx_dodge_shadow_blend.png`
  - 刚猛普通 / 大招：`fx_gangmeng_strike_blend.png` / `fx_gangmeng_ultimate_blend.png`
  - 灵巧普通 / 大招：`fx_lingqiao_slash_blend.png` / `fx_lingqiao_ultimate_blend.png`
  - 阴柔普通 / 大招：`fx_yinrou_palm_blend.png` / `fx_yinrou_ultimate_blend.png`
  - 暴击：`fx_critical_hit_blend.png`
  - 高防御命中表现：`fx_armor_break_blend.png`
  - 内伤：`fx_internal_injury_blend.png`
- `battle_boss_frame` 视觉路由背景切到 `assets/scenes/mj/battle_boss_entrance_bg_01.png`。
- 新增 widget 覆盖：
  - Boss / 低血状态显示 MJ 氛围 overlay。
  - actionLog 增长触发 MJ battle_fx sprite。

## 验证

- `dart format lib/shared/theme/wuxia_tokens.dart lib/features/battle/presentation/battle_atmosphere_overlay.dart lib/features/battle/presentation/battle_effect_sprite.dart lib/features/battle/presentation/battle_screen.dart lib/features/debug/presentation/visual_route_host.dart test/features/battle/presentation/battle_screen_log_test.dart`
- `flutter analyze lib/shared/theme/wuxia_tokens.dart lib/features/battle/presentation/battle_atmosphere_overlay.dart lib/features/battle/presentation/battle_effect_sprite.dart lib/features/battle/presentation/battle_screen.dart lib/features/debug/presentation/visual_route_host.dart test/features/battle/presentation/battle_screen_log_test.dart test/widget_test.dart test/features/battle/presentation/damage_popup_test.dart test/features/battle/presentation/hit_flash_test.dart test/features/battle/presentation/projectile_trail_test.dart`
- `flutter test test/features/battle/presentation/battle_screen_log_test.dart test/widget_test.dart test/features/battle/presentation/damage_popup_test.dart test/features/battle/presentation/hit_flash_test.dart test/features/battle/presentation/projectile_trail_test.dart`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=battle_boss_frame`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=battle_scene`

说明：首次并行 build 时 `battle_scene` 因 Xcode `build.db` 锁冲突失败，随后顺序补跑通过。

## 视觉验收截图

- `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07/01_battle_boss_fx_overlay.png`
- `docs/handoff/codex_mj_battle_fx_overlay_2026-06-07/02_battle_boss_fx_overlay_restart.png`

观察结论：

- 扩展屏截图无红屏、无 debug banner、无明显 overflow。
- Boss 背景与全屏 overlay 已实际渲染。
- 当前 `battle_boss_frame` 自动战斗到结算较快，截图落在胜利 overlay 状态；动态 battle_fx 已由 widget test 验证 asset 触发与挂载。

## 仍未接入 / 待下一批处理

- `assets/ui/mj/ceremony_red_seal_01.png`：可作为更独立的胜利 / 首通印章素材。
- `assets/ui/mj/ui_boss_frame_01.png`
- `assets/ui/mj/ui_big_boss_frame_01.png`
- `assets/ui/mj/menu_mountain_gate_01.png`
- `assets/ui/mj/menu_mountain_gate_wide_01.png`
- `assets/ui/mj/menu_splash_pier_02.png`

建议下一批先处理 `ui_boss_frame_*`，替换 / 增强当前 `CharacterAvatar` Boss 边框；再处理 `menu_mountain_gate_*` 做主菜单或章节入口的备用门面图。
