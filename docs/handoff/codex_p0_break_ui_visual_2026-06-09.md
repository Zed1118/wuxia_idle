# P0 破招战斗 UI 视觉验收 · 2026-06-09

项目：挂机武侠  
HEAD：`main @ 05adb81`，`git pull --rebase --autostash` 结果：Already up to date  
范围：只做视觉验收，不改代码。

## 截图包

- 静态批量截图：`docs/handoff/visual_capture_05adb81_20260609_212740/`
- 补抓角色面板 720p：`docs/handoff/visual_capture_05adb81_20260609_214413/character_panel_1280x720.png`
- 动态尝试截图：`docs/handoff/codex_p0_break_ui_visual_2026-06-09_assets/`

## 逐项结果

| 项 | 结果 | 结论 | 截图 |
|---|---|---|---|
| A1 main_menu 去红印 | PASS | 每个菜单 tile 右上角未见遗留小红印方块，卡片角落干净。 | `main_menu_1280x720.png` |
| A2-3a character_panel 装备名 | PASS | 1080p 装备槽可见 `龙泉剑 利器`、`锦袍 好家伙`、`古玉佩 好家伙`，装备名在品阶前且未挤叠。 | `character_panel_1920x1080.png` |
| A2-3b character_panel 师承字号 | PASS | 顶部 `祖师 / 大弟子 / 二弟子` 与祖师身份文字清晰，深底不发虚；未见明显字号过小问题。 | `character_panel_1280x720.png`, `character_panel_1920x1080.png` |
| A3 technique_panel_tier_all 卷轴叠阶名 | FAIL | 可见卷轴中央有阶名且无下方重复 label，但 720p/1080p 静态截图只露出部分卷轴，未能同屏验证 7 张卷轴全部叠当前阶名。 | `technique_panel_tier_all_1280x720.png`, `technique_panel_tier_all_1920x1080.png` |
| B1 battle_charge_break 蓄力条 | PASS | 青衫剑客头像下方有黄色蓄力进度条，并显示闪电“可破招”图标。 | `battle_charge_break_1280x720.png` |
| B2 battle_charge_break 破招按钮高亮 | PASS | 底栏主控「破招」按钮为金色高亮并带白边框，状态明确。 | `battle_charge_break_1280x720.png` |
| B4 battle_charge_break 底栏布局 720p | PASS | 720p 下 6 个角色按钮与快进按钮均在屏内，未溢出、未挤叠。 | `battle_charge_break_1280x720.png` |
| B3 实玩 stage_02_05 破招交互 | FAIL | 未完成生产 `stage_02_05` 实玩：当前正常存档/视觉种子均显示第二章锁定，无法从 UI 进入「巷中夜雨」。另用 `battle_charge_break` 冻结帧尝试点击破招时，扩展屏窗口无法可靠接收程序化点击，未捕获到“破！”转场。 | `runtime_normal_start.png`, `runtime_break_after_double_click.png` |
| B5 败北页失败提示 | FAIL | 未能进入生产 `stage_02_05` 并打出败北页，因此未验到 `保留内力，看准蓄力时机破招` 提示。 | `runtime_normal_start.png` |
| C 飞升渡劫文案 | FAIL | 本轮未完成可视路径验证；未取得群英谱/师徒名单底部「飞升渡劫」截图，不能判 PASS。 | 无 |

## 总判

需返修/复验。

返修或复验项：

- A3：`technique_panel_tier_all` 静态截图需能同屏验证 7 张卷轴，或提供可验收的全量截图路径。
- B3：需要在可进入 `stage_02_05` 的存档/直达入口下复验真实破招交互。
- B5：需要在同一真实关卡流程中复验败北页提示。
- C：可选项未验；若纳入上线闸，需要提供可直达群英谱飞升条件不足状态的截图入口。

## 备注

- `character_panel_1280x720` 首次批量捕获超时，单独重跑成功。
- 本机游戏窗口位于扩展屏，后续已按 CGWindow bounds 定位；静态窗口截图正常，动态点击受当前桌面辅助访问/焦点限制影响，未作为 PASS 依据。
