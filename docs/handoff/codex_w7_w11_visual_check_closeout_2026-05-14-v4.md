# W7-W11 视觉验收第四轮 closeout

日期：2026-05-14
项目：`F:\Projects\wuxia_idle`
分支：`main`
验收基线：`0551a1a`

## 1. 开工状态

- Git 同步：OK，`HEAD = 0551a1a`。
- `git show 0551a1a --stat` 已确认本轮 Mac 端修复包含：
  - `data/stages.yaml` 为 `stage_01_01` 增加 100% `armor_xunchang_bu_yi` 与 100% `item_mojianshi`。
  - `lib/ui/mainline/stage_entry_flow.dart` / `lib/ui/tower/tower_entry_flow.dart` 在战斗结算写 Isar 后 invalidate 相关 family provider。
- `flutter analyze`：通过，`No issues found!`。
- `flutter pub run build_runner build --delete-conflicting-outputs`：完成，写入 0 个文件。
- `flutter test`：未全绿，`550 passed / 1 failed`。
  - 失败点：`test/data/game_repository_test.dart:295`。
  - 失败原因：旧测试仍期待 `stage_01_01` 缺失 `dropTable` 时抛 `StateError`，但 `0551a1a` 已补上 `dropTable`，测试预期与新配置冲突。
  - 本轮按纪律未改 `lib/` 或 `test/`。

## 2. 本轮执行说明

- 未 push。
- 未修改 `lib/`、`test/`、`data/narratives/`、`data/lore/`、`data/events/`。
- 实际存档路径不是旧 spec 里的 `%APPDATA%\wuxia_idle`，而是 Flutter `path_provider` Documents 路径：`C:\Users\Administrator\Documents\wuxia_save_slot1.isar` 及同名前缀文件。
- 因 1280x900 Flutter 窗口在当前 RDP 高度下底部会离屏，且 Windows UIA 只暴露 `FLUTTERVIEW`，本轮使用坐标点击 + `PrintWindow` 截图。
- P5/VC 种子为了保证 Isar 落在实际 Documents 存档路径，使用了 `%TEMP%` 下临时 Flutter test 启动 `Phase2SeedService.seedMasterDisciple()` 与 `seedVisualCheckW7W11()`。临时文件不在仓库内，未产生仓库源码改动。

## 3. 截图清单

目录：`docs/screenshots/phase4_w7_w11/`

- `03_w9_tower_floor_list_top.png`
- `04_w9_tower_boss_outline.png`
- `06_w11_before_stage_eq_battlecount.png`
- `07_w11_before_stage_tech_progress.png`
- `08_w11_after_stage_eq_battlecount.png`
- `09_w11_after_stage_tech_progress.png`
- `11_w11_tower_floor1_firstclear_rewards.png`
- `12_w11_tower_floor1_replay_no_rewards.png`
- `13_w11_tower_replay_battlecount_still_inc.png`
- `14_w10_defeat_banner_title.png`
- `15_w10_defeat_internalforce_halved.png`

未补齐：

- `01_w7_inventory_35items.png`：本轮未取得完整 35 件库存视觉入口。
- `02_w8_techniques_panel.png`：本轮未取得完整心法面板总览；仅在 07/09 捕获祖师主修心法进度。
- `05_w9_tower_floor_30.png`：本轮未滚动取得 30 层视觉证据。
- `10_w11_stage_drop_inventory.png`：本轮未取得背包页中「寻常布衣」与磨剑石增加的硬截图，见 §4。

## 4. 7 个必收硬证据结论

| # | 验收点 | 结论 | 证据 |
|---|---|---|---|
| 08 | 战后 `battleCount #0 -> #1` | 通过 | `06_w11_before_stage_eq_battlecount.png` 显示 `#0`，`08_w11_after_stage_eq_battlecount.png` 显示 `#1`。 |
| 09 | 战后心法 `0/100 -> 1/100` | 通过 | `07_w11_before_stage_tech_progress.png` 显示 `0/100`，`09_w11_after_stage_tech_progress.png` 显示 `1/100`。 |
| 10 | `stage_01_01` drop 入背包：寻常布衣 + 磨剑石 | 未取得硬截图 | GUI 已跑完 `stage_01_01` victory，但当前 1280x900/RDP 环境下主菜单底部入口与滚动操作不稳定，未成功进入库存页拍到新增装备和道具。不可标通过。 |
| 12 | 重打 victory dialog 无 reward | 通过 | `12_w11_tower_floor1_replay_no_rewards.png` 显示「已重打通关，重打不发奖」。 |
| 13 | 重打后 `battleCount` 仍递增 | 通过 | `13_w11_tower_replay_battlecount_still_inc.png` 显示装备战斗计数已到 `#3`。该存档顺序包含 G 战败、塔 1 首通、塔 1 重打，能证明重打路径仍写入战斗次数。 |
| 14 | 战败 banner | 通过 | `14_w10_defeat_banner_title.png` 显示「战败 · 散功代价」，并列出祖师/大弟子/二弟子内力减半。 |
| 15 | 战败后角色面板内力真减半 `1900 / 4180` | 通过 | `15_w10_defeat_internalforce_halved.png` 显示祖师 Tab 内力 `1900 / 4180`。 |

## 5. 本轮关键观察

- #15 修复有效：按 G 场景流程，战败 banner 后继续返回 stage list，再回主菜单重新进角色面板，祖师内力字段已经从战前 `3800 / 4180` 刷新为 `1900 / 4180`。
- #08/#09 沿用通过且本轮重跑有效：`stage_01_01` victory 后角色面板显示装备计数 `#1`，主修心法修炼度 `1/100`。
- #12/#13 沿用通过且本轮重跑有效：塔 1 重打弹窗不发奖，战斗计数仍递增。
- #10 仍缺视觉闭环：`0551a1a` 配置修复已经存在，但本轮没有库存页硬截图，不能把代码配置事实替代为视觉验收通过。

## 6. 建议

- 更新视觉验收清档步骤：清理 `C:\Users\Administrator\Documents\wuxia_save_slot1*`，不要只清 `%APPDATA%\wuxia_idle`。
- 给视觉验收模式增加直接入口或快捷键：库存页、心法页、塔 30 层、指定 stage victory 后状态页。当前坐标点击在 RDP 高度不足时成本很高。
- 如果继续要求 1280x900 硬规格，建议验收机屏幕高度实际大于 900；否则 `PrintWindow` 截图底部会出现离屏空白区，普通截图也会被遮挡。
