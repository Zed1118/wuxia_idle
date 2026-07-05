# Plan — BattleScreen 拆分（策略 B：叶子 widget 去私有化搬独立文件）

**日期**：2026-07-05
**分支**：`worktree-battle-screen-split-b`
**目标**：把 `lib/features/battle/presentation/battle_screen.dart`（3312 行）里的 26 个私有叶子 widget + 3 个私有数据类搬到独立文件，去私有化为 public，主文件降到 ~1400 行。**纯移动重构，零行为变更**。C（State 的 VFX/controller 抽离）留后续独立批次，本批不做。

## 验收标准（oracle）
1. `flutter analyze lib/ test/` → **0 issues**。
2. `flutter test test/features/battle/ --no-pub` → **569 全过**（基线，零回归）。
3. 批末全量 `flutter test --no-pub` 零回归。
4. `battle_screen.dart` 显著变短（叶子 widget 全部移出）；无 `part/part of`（策略 B = 真独立 library）。
5. 无行为改动：私有 widget 只经 `BattleScreen` 被测，测试对本重构透明。

## 必须公有化的 4 符号
| 原 | 新 | 去处 |
|---|---|---|
| `_PopupEntry`(67) | `PopupEntry` | `presentation/battle_vfx_entries.dart` |
| `_TrailEntry`(81) | `TrailEntry` | 同上 |
| `_EffectEntry`(100) | `EffectEntry` | 同上 |
| `_BattleScreenState._isSkillReady`(1080, static 纯函数) | 顶层 `isSkillReady()` | `domain/battle_skill_utils.dart` |

`_isSkillReady` 调用点：State 内 930 / 969 / 1071 + `_SkillCommandButton`(2672)，全部改调 `isSkillReady(...)`。

**架构修正**（覆盖 recon 建议）：`battle_vfx_entries.dart` 放 **presentation/**（持有 AnimationController/Color/DamagePopupData，属表现层，不入 domain 免反向依赖）；`battle_skill_utils.dart` 放 **domain/**（纯函数无 Flutter 依赖）。

## 文件分组（8 新文件）
| 文件 | 类 |
|---|---|
| `presentation/battle_vfx_entries.dart` | PopupEntry / TrailEntry / EffectEntry |
| `domain/battle_skill_utils.dart` | 顶层 `isSkillReady()` |
| `presentation/widgets/battle_banners.dart` | HintBanner / CycleHintBanner / CoopBurstPromptBar / DangerBar / BattleReportStrip |
| `presentation/widgets/battle_header.dart` | Header / BattleHeaderIconButton / PauseOverlay / LogDrawer |
| `presentation/widgets/battle_field.dart` | BattleField / TeamColumn / CharacterSlot / EnemyTargetHint / GlowAura(+State) |
| `presentation/widgets/battle_bottom_bar.dart` | BottomBar / FocusSelector / FocusChip / SkillCommandButton / PendingStamp / SkillInfoBody / FastForwardButton |
| `presentation/widgets/battle_vfx_layers.dart` | ProjectileLayer / EffectLayer |
| `presentation/widgets/battle_target_chips.dart` | TargetChipStrip / TargetChip |

保留在 battle_screen.dart：`playbackHoldMs`(public) / `slotVerticalFraction`(public) / `BattleScreen` / `_BattleScreenState`（含 private `_backgroundStyleForTrack` / `_findKeySkillOf` / `_slotKey` / `_slotFrac`），新增对上述 8 文件的 import；State 内 3 数据类引用改 public 名、3 处 `_isSkillReady` 改 `isSkillReady`。

## 任务切片（串行 —— 全程改 battle_screen.dart，不可并行）
1. `battle_vfx_entries.dart` + `battle_skill_utils.dart`（底层依赖先落）。
2. 无子依赖叶子：banners / vfx_layers / target_chips / header。
3. 强链叶子：field 组（field→team→slot→hint→glow）。
4. bottom_bar 组（bottom→selector/chip + skill_button→stamp + info + fastforward）。
5. battle_screen.dart：删除已移出的类、加 8 import、改引用（3 数据类 + isSkillReady）。
6. analyze 0 → battle 569 → 全量。

## 恢复点
- 状态：环境预热完成（pub get / dylib / 112 .g.dart / battle 569 基线绿）。plan 已落。
- 下一步：实现子代理执行切片 1–6。
- 已跑验证：`flutter test test/features/battle/` 569 pass（重构前基线）。
- 阻塞：无。
