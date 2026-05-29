# H1 batch123 Pen visual verify

Date: 2026-05-30
Machine: Pen Windows, `F:\Projects\wuxia_idle`
HEAD: `ae17e74`

## Build

- `git fetch origin && git reset --hard origin/main`: PASS, HEAD = `ae17e74`
- `dart run build_runner build --delete-conflicting-outputs`: PASS, wrote 6 outputs
- `flutter build windows --debug`: PASS, built `build\windows\x64\runner\Debug\wuxia_idle.exe`

## Results

| ID | Status | Screenshot | Note |
|---|---|---|---|
| 1.1 main menu no crash | PASS | `docs/handoff/h1_visual_check_screenshots/h1_01_main_menu.png` | Title shows `挂机武侠`, no `调试主菜单`. |
| 1.2 late-game locked | PASS | `docs/handoff/h1_visual_check_screenshots/h1_02_lategame_locked.png` | `心魔境` / `轻功试炼` / `守城试炼` are grey with Ch6 hint. |
| 1.3 PVP locked | PASS | `docs/handoff/h1_visual_check_screenshots/h1_03_pvp_locked.png` | `论剑对决` is grey with Ch5 hint. |
| 1.4 social locked | PASS | `docs/handoff/h1_visual_check_screenshots/h1_04_social_locked.png` | `江湖恩怨` / `门派事务` / `排行榜` are grey with Ch1 hint. |
| 2.1 equip picker opens | PASS / ISSUE | `docs/handoff/h1_visual_check_screenshots/h1_05_equip_picker_open.png` | Slot opens bottom sheet, but VC18-A1 weapon slot has no available equipment and the empty sheet could not be dismissed by ESC / barrier / app back. |
| 2.2 equip applies | PASS | `docs/handoff/h1_visual_check_screenshots/h1_06_equipped.png` | Using VC15-r2 inventory state, selecting a usable weapon equipped it and changed stats. |
| 2.3 realm lock grey | PASS | `docs/handoff/h1_visual_check_screenshots/h1_07_realm_locked.png` | Higher-tier weapons show lock icons and are not selectable. |
| 2.4 unequip | PASS | `docs/handoff/h1_visual_check_screenshots/h1_08_unequip.png` | `卸下当前装备` closes sheet and returns weapon slot to `未装备`. |
| 2.5 refinement button state | SKIP | n/a | Main-menu `心法面板` remained locked (`通达第三关后开放`) in the available seeded routes, so I could not reach the requested panel state without changing data/code. |
| 2.6 transition button color | FAIL | `docs/handoff/h1_visual_check_screenshots/h1_10_chapter_transition_button.png` | After restart, clicking `主线` led to a blank white window instead of chapter/transition UI. |
| 3.1 battle starts | FAIL | `docs/handoff/h1_visual_check_screenshots/h1_11_battle.png` | Blocked by the same `主线` white screen. |
| 3.2 drop dialog | SKIP | n/a | Could not reach battle victory. |
| 3.3 turn terminology | SKIP | n/a | Could not reach battle/log/settlement. |
| 4.1 seclusion equip name | SKIP | n/a | Heavy/optional path not attempted after mainline blocker. |
| 4.2 drop tier color contrast | SKIP | n/a | Could not reach drop dialog. |

## Findings

- VC18-A1 does not provide available equipment for the character-panel weapon picker; opening an empty picker leaves a bottom sheet with no visible close affordance, and ESC / outside click / appbar back did not dismiss it.
- Equipment picker itself works under a state with inventory: high-tier items lock correctly; usable item selection and unequip both apply to stats/slots.
- Main-menu `心法面板` was still gated during this run, so the requested refinement button visual state could not be verified.
- Mainline entry regressed/blocked on Pen: after restart and `直入江湖`, clicking `主线` produced a blank white app surface. This blocked transition color, battle, drop dialog, and turn-term checks.

Summary: Round 1 passes; equipment picker core behavior passes with a picker-empty dismiss issue; Round 3 is blocked by mainline white screen.
