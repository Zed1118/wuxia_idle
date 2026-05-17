# Codex W18-A1 synergy visual check closeout (2026-05-17)

> Executor: Codex Desktop @ Pen Windows
> Scope: run Windows debug build, capture Phase2 VC18-A1 entry, 5 CharacterPanelScreen synergy chips, and stage_01_05 battle HP injection evidence.

## 1. Environment

- HEAD: `9dd5a65`
- Platform: Windows Flutter desktop debug
- Build flow:
  - `git pull --ff-only`
  - `flutter clean`
  - `dart run build_runner build --delete-conflicting-outputs`
  - `flutter build windows --debug`
- Result:
  - git pull PASS, fast-forwarded to `9dd5a65`.
  - build_runner PASS; current build_runner prints `--delete-conflicting-outputs` as ignored/removed option.
  - Windows debug build PASS: `build\windows\x64\runner\Debug\wuxia_idle.exe`
- Screenshot method: Win32 `GetWindowRect` + `System.Drawing.Graphics.CopyFromScreen`, cropped to the Flutter app window.
- Screenshot sizes:
  - Phase2/chip captures: `1280 x 1180`.
  - Battle capture: `2576 x 1416` after the app window was maximized during narrative/battle navigation.

## 2. Screenshots

| # | Screenshot | Result | Notes |
|---|---|---|---|
| 01 | `docs/screenshots/w18/w18_a1_phase2menu_13buttons.png` | PASS | Bottom-scrolled Phase2 menu shows VC18-A1 after VC15-fresh and before DEBUG festival override. |
| 02 | `docs/screenshots/w18/w18_a1_chip_01_yinyang.png` | PASS | A·阴阳 shows 5 tabs and `_SynergyChip`: 阴阳调和. |
| 03 | `docs/screenshots/w18/w18_a1_chip_02_gangrou.png` | PASS | B·刚柔 shows `_SynergyChip`: 刚柔并济. |
| 04 | `docs/screenshots/w18/w18_a1_chip_03_yinying.png` | PASS | C·阴影 shows `_SynergyChip`: 阴影迅捷. |
| 05 | `docs/screenshots/w18/w18_a1_chip_04_tongpai.png` | PASS | D·同流派 shows `_SynergyChip`: 同流派精进. |
| 06 | `docs/screenshots/w18/w18_a1_chip_05_tongbei.png` | PASS | E·同辈 shows `_SynergyChip`: 同辈互补. |
| 07 | `docs/screenshots/w18/w18_a1_battle_stage_01_05_injection.png` | WARN | Battle HP max values are visible and pass ratio check, but capture landed on victory overlay rather than init frame. |

## 3. Chip Summary Actuals

| Tab | Character | Synergy | Actual chip text |
|---|---|---|---|
| 1 | A·阴阳 | 阴阳调和 | `相生 阴阳调和 · 攻 +10% · 速 +10% · 血 +20%` |
| 2 | B·刚柔 | 刚柔并济 | `相生 刚柔并济 · 速 +25%` |
| 3 | C·阴影 | 阴影迅捷 | `相生 阴影迅捷 · 攻 +15% · 速 +15%` |
| 4 | D·同流派 | 同流派精进 | `相生 同流派精进 · 攻 +20%` |
| 5 | E·同辈 | 同辈互补 | `相生 同辈互补 · 内力上限 +25%` |

All 5 chips render Chinese text normally, with no missing glyph boxes, clipping, or Tab label overflow observed at `1280 x 1180`.

## 4. Battle HP Injection

Battle screenshot max HP values observed from the left team:

| Slot | Character | HpBar current/max in screenshot | Max HP |
|---|---|---:|---:|
| 1 | A·阴阳 | `1625 / 7992` | `7992` |
| 2 | B·刚柔 | `0 / 6660` | `6660` |
| 3 | C·阴影 | `0 / 6660` | `6660` |

- A:B ratio = `7992 / 6660 = 1.20`.
- B:C ratio = `6660 / 6660 = 1.00`.
- Verdict: HP injection is visible and within the expected 1.15-1.25 tolerance.

## 5. Notes

- Phase2 VC18-A1 button was visible in the required menu position. During manual GUI navigation, the bottom button cluster was easy to mis-click at `1280 x 1180`; after confirming the exact fixture path, I executed the same `Phase2SeedService.seedVisualCheckW18A1()` against the local Documents Isar via a temporary Flutter test harness. This wrote characters `1:A·阴阳, 2:B·刚柔, 3:C·阴影, 4:D·同流派, 5:E·同辈` and active ids `1,2,3,4,5`, then the GUI was relaunched for screenshots.
- Battle capture missed the requested init timing because the fight resolved quickly while advancing the pre-battle narrative. The final overlay still leaves the three left-side HpBar max values visible enough to verify the injection.
- No `lib/`, `data/`, `GDD.md`, `CLAUDE.md`, `PROGRESS.md`, or `IDS_REGISTRY.md` files were edited.

## 6. Summary

7 screenshots captured. 6 PASS. 1 WARN. 0 FAIL.

