# 2026-06-15 L1 显示设置 Codex 本机验收

## 环境

- 项目：`/Users/a10506/Desktop/Projects/挂机武侠`
- 分支：`main`
- 启动：`git pull --rebase --autostash` 后 `flutter run -d macos`
- 截图目录：`docs/reviews/l1_acceptance/`

## 结果

### L1-1 全屏开关：✅ pass

设置面板「全屏」开关 ON 后窗口立即进入 macOS 全屏，CGWindow bounds 变为 `2560×1440`；再 OFF 后退出全屏并回到窗口模式，bounds 回到 `1600×900`。

- 截图：`docs/reviews/l1_acceptance/fullscreen_on.png`
- 截图：`docs/reviews/l1_acceptance/fullscreen_off.png`

### L1-2 三档分辨率：❌ fail

主行为通过：窗口模式下三档都能真实 resize 且居中，实测 bounds 分别为 `1280×720 (X=640 Y=328)`、`1600×900 (X=480 Y=238)`、`1920×1080 (X=320 Y=148)`；全屏 ON 时分辨率下拉显示为灰禁用态。

失败点：切到 `1280×720` 后设置面板底部出现 Flutter 黄色黑条，控制台报 `A RenderFlex overflowed by 4.0 pixels on the bottom.`，视觉上「退出游戏」区域被挤压。

- 截图：`docs/reviews/l1_acceptance/res_720.png`
- 截图：`docs/reviews/l1_acceptance/res_900.png`
- 截图：`docs/reviews/l1_acceptance/res_1080.png`
- 截图：`docs/reviews/l1_acceptance/res_dropdown_disabled_in_fullscreen.png`

### L1-3 F11 全局快捷键：❌ fail

实际现象：在主菜单/设置面板态按 F11 没有切换全屏；窗口仍保持 `1920×1080`，且 macOS 触发了类似“显示桌面/移开窗口”的系统行为。控制台没有对应 app 报错。

预期：F11 应等价于设置面板「全屏」开关，在全屏与窗口模式间切换。

- 截图：`docs/reviews/l1_acceptance/f11_before.png`
- 截图：`docs/reviews/l1_acceptance/f11_after.png`

### L1-4 启动恢复设置：✅ pass

把分辨率改为非默认 `1920×1080` 后 Cmd+Q 完全退出，再重新 `flutter run -d macos`，窗口恢复为 `1920×1080` 且居中（bounds `X=320 Y=148 W=1920 H=1080`）。

- 截图：`docs/reviews/l1_acceptance/restart_restored.png`

### L1-5 M2「归来」卡：✅ pass（视觉项）

本机存档启动后直接出现「归来」卡：标题、离线约 60 小时、地图闭关已圆满、预计磨剑石/经验、两个按钮均显示；宣纸底、墨字和按钮配色协调。为继续 L1 主流程，本轮点击了「稍后再说」，未继续验证「前去收功」跳转。

- 截图：`docs/reviews/l1_acceptance/m2_recap_card.png`

## 总评

L1 主入口达到可用标准：设置面板开关、三档实际 resize、全屏禁用下拉、重启恢复均可用；无阻塞问题。需回修两个非阻塞问题：`1280×720` 设置面板底部 overflow，以及 F11 被 macOS 系统行为吞掉/未触发 app 全屏切换。
