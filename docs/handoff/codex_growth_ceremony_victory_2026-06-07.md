# 胜利弹窗成长仪式 polish

日期：2026-06-07  
分支：`codex/t11-inventory-section-header`

## 范围

本切片推进 `docs/UI_WORK_REMAINING_2026-06-06.md` 的 T6「成长仪式统一模板」：

- 强化 `AdvancementSummary`，把战后升层从普通提示改为“境界精进”宣纸仪式块。
- 强化 `ResonanceUpgradeBanner`，把共鸣晋阶从普通文本列表改为“兵器应手”宣纸仪式块。
- 保留原战斗结算、掉落、升层、共鸣记录与导航逻辑。
- 不新增粒子、金光或高饱和特效，仍保持水墨克制风格。

## 结论

总判：通过。1280x720 下胜利弹窗无 overflow；首胜封签、掉落、境界精进、兵器应手四段层级清楚，关键成长事件与普通掉落能明显区分。

| 验收点 | 结果 | 说明 |
|---|---|---|
| 升层仪式 | 通过 | 显示“境界精进”标题、宣纸底、图标印记与升层文案。 |
| 共鸣仪式 | 通过 | 显示“兵器应手”标题、共鸣晋阶标签与装备晋阶文案。 |
| 原文案保留 | 通过 | `甲 · 突破至...`、`「装备」共鸣度晋至...` 等断言仍通过。 |
| 逻辑不变 | 通过 | 只改 presentation 层；未改 battle resolution / event / drop 逻辑。 |
| 视觉验收 | 通过 | `VISUAL_ROUTE=battle_victory_first_clear` 截图检查无溢出。 |

## 截图

- `docs/handoff/codex_growth_ceremony_victory_2026-06-07/01_victory_growth_ceremony_1280x720.png`

## 验证

```bash
flutter test test/features/mainline/presentation/stage_victory_dialog_test.dart
flutter analyze lib/features/cultivation/presentation/advancement_summary.dart lib/features/mainline/presentation/stage_victory_dialog.dart lib/features/debug/application/visual_route.dart lib/features/debug/presentation/visual_route_host.dart lib/shared/strings.dart test/features/mainline/presentation/stage_victory_dialog_test.dart
flutter build macos --debug --dart-define=VISUAL_ROUTE=battle_victory_first_clear
```

以上均通过。
