# Codex W17 LineagePanelScreen visual check closeout (2026-05-17)

> Executor: Codex Desktop @ Pen Windows
> Scope: run Windows debug build, capture LineagePanelScreen entry / empty / P5 full states, self-check visual acceptance points.

## 1. Environment

- HEAD: `cbb2352`
- Platform: Windows Flutter desktop debug
- Build flow:
  - `flutter clean`
  - `flutter pub get`
  - `dart run build_runner build --delete-conflicting-outputs`
  - `flutter build windows --debug`
- Result:
  - build_runner PASS; current build_runner prints `--delete-conflicting-outputs` as ignored/removed option.
  - Windows debug build PASS: `build\windows\x64\runner\Debug\wuxia_idle.exe`
- Screenshot method: Win32 `GetWindowRect` + `System.Drawing.Graphics.CopyFromScreen`, cropped to the Flutter app window.
- Screenshot size: `1280 x 1180`.

## 2. Screenshots

| # | Screenshot | Result | Notes |
|---|---|---|---|
| 01 | `docs/screenshots/w17_lineage_panel/w17_lineage_main_menu_9buttons.png` | PASS | Main menu shows 9 buttons, including `师徒名单`. |
| 02 | `docs/screenshots/w17_lineage_panel/w17_lineage_panel_empty.png` | PASS | Fresh save empty state shows all 3 empty copy lines. |
| 03 | `docs/screenshots/w17_lineage_panel/w17_lineage_panel_full_after_p5.png` | PASS | P5 state shows founder, 2 disciples, and 2 heritage rows. |

## 3. Acceptance Checklist

### 3.1 Button Order

PASS.

- Order visible in 01: `主线 / 问鼎九霄 / 闭关修炼 / Phase 1 战斗测试 / Phase 2 调试场景 / 角色面板 / 师徒名单 / 装备仓库 / 心法面板`.
- `师徒名单` sits after `角色面板` and before `装备仓库`.
- Label and hint are correct: `师徒名单` / `查看祖师与弟子的传承链路`.
- Button shape, panel color, border, typography, and spacing match the other menu entries.

### 3.2 Empty State Copy

PASS.

- AppBar title `师徒名单` and BackButton are visible.
- Three sections are visible: `祖师`, `弟子`, `师承遗物`.
- Empty copy matches expected text:
  - `祖师未定`
  - `尚无弟子`
  - `尚未拥有师承遗物`
- Empty heritage section has no `N 件` counter.
- Chinese text renders normally, no missing glyph boxes.

### 3.3 Full State Chip + Heritage

PASS.

- Founder section shows 1 character chip: `祖师 / 一流后羿`.
- Disciple section shows 2 chips: `大弟子 / 二流后羿`, `二弟子 / 三流后羿`.
- All 3 chips share consistent background, border, typography, and left style color bars.
- Heritage section shows `2 件`.
- Heritage rows resolve to Chinese equipment names: `龙泉剑`, `锦袍`.
- Tier color dots render at row left. No raw `defId` fallback observed.
- No enhance `+N` label appears because these P5 heritage items are unenhanced; treated as N/A, not a failure.

### 3.4 Style Consistency

PASS.

- Panel cards align with the existing dark wuxia UI language: restrained panel fill, thin border, compact radius.
- Section title size/weight/color matches the character panel family.
- Layout is stable at `1280 x 1180`: no overflow, clipping, overlap, or forced scrolling needed.

## 4. Summary

3 screenshots captured. 4 acceptance categories PASS. 0 WARN. 0 FAIL.

Small environment note: the first empty-state attempt saw old local Isar data from `C:\Users\Administrator\Documents\wuxia_save_slot1.isar`. I temporarily moved that save into `C:\Users\Administrator\Documents\wuxia_visual_check_backup_20260517_021008`, captured the fresh empty state, then restored the original save and removed the backup folder.
