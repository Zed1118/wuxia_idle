# W17 festival chip extend visual check closeout

## 1. 结论

本轮 W17 `_TodayFestivalChip` 扩展视觉验收 **3 PASS / 0 WARN / 0 FAIL**。

2 个新增节日通过 Phase2TestMenu「DEBUG · 切今日节日」入口覆盖，主菜单标题下方 chip 分别显示为「今日：除夕」与「今日：清明」；SimpleDialog 显示 8 个节日 + 清除覆盖，共 9 个选项。3 张截图均为 `1280 x 950`，标题、chip、dialog 与 8 个主菜单入口均正常可见。

## 2. 环境与启动记录

- 工作目录：`F:\Projects\wuxia_idle`
- `git pull --rebase --autostash`：Already up to date
- 验收基准 HEAD：`e390cf2`
- 历史确认：`e390cf2` W17 Codex 派单在 HEAD；`9b795a0` W17 framework 在当前历史中
- `flutter clean`：通过
- `dart run build_runner build`：通过；写出 54 个 generated outputs
- `flutter build windows --debug`：通过，产物 `build\windows\x64\runner\Debug\wuxia_idle.exe`
- GUI：窗口固定为 `1280 x 950` 捕获区域，应用窗口略放大避免系统边缘阴影混入截图
- 截图工具：PowerShell + Win32 `MoveWindow` / `mouse_event` + `System.Drawing.Graphics.CopyFromScreen`
- 截图目录：`docs/screenshots/w17/`

## 3. 截图清单与评级

| 编号 | 文件 | 评级 | 说明 |
|---|---|---:|---|
| 01 | `docs/screenshots/w17/w17_festival_chip_chuXi.png` | PASS | chip 显示「今日：除夕」，位置居中，背景、描边、圆角与 W16 chip 体例一致。 |
| 02 | `docs/screenshots/w17/w17_festival_chip_qingMingJie.png` | PASS | chip 显示「今日：清明」，中文渲染正常，未挤压 8 个主菜单入口。 |
| 03 | `docs/screenshots/w17/w17_festival_dialog_9_options.png` | PASS | SimpleDialog 显示除夕 / 春节 / 元宵 / 清明 / 端午 / 七夕 / 中秋 / 重阳 / 清除覆盖 9 项，顺序符合 enum 声明顺序。 |

## 4. 视觉层反馈

- chip 位于标题「挂机武侠 · 调试主菜单」下方居中，留白与 W16 6 chip 一致。
- chip 为灰墨 panel 背景、细描边、圆角胶囊形，文字为低饱和灰色，字号约 12px。
- 除夕 / 清明 2 个新增 chip 的尺寸、padding、背景、描边表现一致。
- 主菜单 8 个入口均可见且保持居中、等距；chip 出现未破坏布局。
- SimpleDialog 9 个选项全部可见，无溢出屏幕。
- 中文显示无方框、缺字或异常字体回退。

## 5. 已知偏差

- 无产品视觉偏差。
- 文本体例说明：截图中 chip 延续 W16 与当前实现的中文冒号体例「今日：X」。本轮按 W16 视觉一致性判定 PASS。
- 工具链偏差：`flutter build windows --debug` 会触碰平台 generated plugin registrant 文件，本轮已恢复这些构建副产物，未纳入提交。

## 6. 下次推荐

- Windows 视觉验收继续采用 `flutter clean` -> `dart run build_runner build` -> `flutter build windows --debug` 的顺序，避免 clean 后 generated 文件缺失。
- 对 Phase2TestMenu 底部 debug 入口，继续使用固定窗口 + 滚到底部 + 逐项覆盖的路径，截图前等待 SnackBar 消失，保证主菜单 8 个入口完整露出。
