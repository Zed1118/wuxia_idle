# Codex W15 stage drop 视觉验收 closeout(#34 闭环)

## 1. 一句话结论
3 张主截图完成，0/3 PASS，3 WARN，0 FAIL。#34 可按 WARN 闭环：A 真 GUI 链路跑通，stage_01_01 胜利后新增装备与磨剑石均已落库；但 victory 屏没有 drop banner / 列表，InventoryScreen 当前没有物料 Tab。

## 2. 环境与启动记录
- HEAD: `5d751a1`
- 入场：`git pull --rebase --autostash` 成功快进到 `5d751a1`；该提交为 Mac 端确认的 docs-only closeout，不影响 F 派单。
- 入场测试：首次 `flutter test test/data/game_repository_test.dart` 因缺少 `lib/core/domain/*.g.dart` 编译失败；按派单 §3.1 执行 `dart run build_runner build --delete-conflicting-outputs` 后重跑，`All tests passed!`，T64 已通过。
- 构建：`flutter build windows --debug` 成功，产物 `build\windows\x64\runner\Debug\wuxia_idle.exe`。
- 启动：清理 `$env:APPDATA\wuxia_idle` 后 `Start-Process build\windows\x64\runner\Debug\wuxia_idle.exe`，`MainWindowHandle=1115888`，GUI 可见。
- 路径：走 A 真 GUI 路径。窗口固定 1280 x 900。
- 实际行为：1280 x 900 下主菜单第 7 个「装备仓库」已可见且可点，不需要滚轮；未复现 2026-05-14 的底部按钮点不准问题。

## 3. 截图清单与 PASS/FAIL 评级
| # | 场景 | 截图路径 | 评级 | 备注 |
|---|---|---|---|---|
| 1 | stage_01_01 victory | `docs/screenshots/w15_stage_drop/01_stage_01_01_victory.png` | WARN | 真 GUI 重打 stage_01_01 成功，胜利弹层可见；但只显示总伤害 / 暴击 / 用时，没有 drop banner / drop 列表。 |
| 2 | InventoryScreen 装备列表 | `docs/screenshots/w15_stage_drop/02_inventory_after_drop.png` | WARN | `寻常货 (3)` 中可见两件「粗布衣」；`armor_xunchang_bu_yi` 显示名即「粗布衣」，P5 起手 1 件 + stage_01_01 drop 1 件的落库结果成立。 |
| 3 | 磨剑石数量侧证 | `docs/screenshots/w15_stage_drop/03_materials_mojianshi.png` | WARN | InventoryScreen 无物料 Tab；通过装备详情 -> 强化弹层拍到「磨剑石 2001 / 1」，P5 起手 2000 + stage_01_01 drop 1 成立。 |

## 4. 视觉层问题反馈(给 Mac)
- victory 胜利弹层没有掉落 banner / 列表，玩家无法在战后第一屏确认 `粗布衣` 与 `磨剑石 x1`。
- InventoryScreen 当前仅装备列表，无装备 / 物料 Tab；材料数量需要绕到装备详情的强化弹层才能看到。
- InventoryScreen ExpansionTile 展开行为正常，`寻常货 (3)` 数量和两件「粗布衣」均清晰可见。

## 5. 节奏层问题反馈(给 Mac)
- P5 种子后自动进入角色面板；Back 两次回主菜单正常。
- P5 种子后第一章前 4 关已经显示「已通关」，但点击 `stage_01_01 山门之外` 可以重走叙事和战斗，未阻断验收。
- `stage_01_01` 战斗 7 tick 结束，节奏很快；victory -> 终章叙事 -> 主菜单 -> InventoryScreen 切屏顺畅。

## 6. 工程教训(本会话产)
- 1280 x 900 在本 Pen Windows/RDP 环境下主菜单可直接看到「装备仓库」，未必需要滚轮；按钮坐标中心约为窗口内 `(640, 750)`。
- `CopyFromScreen` 截 Flutter Windows 窗口稳定；过程截图清理后仅保留 3 张主截图。
- `dart run build_runner build --delete-conflicting-outputs` 在当前 build_runner 版本提示该参数已移除并忽略，但仍成功写出生成文件，随后测试通过。

## 7. 下次推荐
- #34 建议按 WARN 闭环：stage drop -> InventoryScreen 的真实 GUI 链路已打通，装备和磨剑石均有硬截图；剩余是 victory 掉落展示和材料 Tab 的视觉缺口。
- 后续如要升级到 PASS，建议 Mac 端补 victory drop banner / list，并在 InventoryScreen 增加物料 Tab 或材料摘要区。
- 高 tier drop 验收可复用本轮 A 路径；建议先加明确的战后掉落展示，避免只能从库存反推。
