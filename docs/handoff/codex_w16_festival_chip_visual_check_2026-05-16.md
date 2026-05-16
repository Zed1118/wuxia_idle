# W16 festival chip visual check closeout

## 1. 结论

本轮 W16 主菜单 `_TodayFestivalChip` 视觉验收 **7 PASS / 0 WARN / 0 FAIL**。

6 个节日通过 Phase2TestMenu「DEBUG · 切今日节日」入口逐一覆盖，主菜单标题下方 chip 均显示为「今日：X」；清除覆盖后 baseline 不显示 chip。7 张截图均为 `1280 x 950`，标题、chip 与 8 个主菜单入口全部可见。

## 2. 环境与启动记录

- 工作目录：`F:\Projects\wuxia_idle`
- `git pull --rebase --autostash`：fast-forward 到 `45de656`
- HEAD：`45de656`
- `flutter clean`：通过
- 首次 `flutter build windows --debug`：失败，原因是 clean 后本机缺少 `*.g.dart` 生成文件
- `dart run build_runner build --delete-conflicting-outputs`：通过；build_runner 提示该参数已移除并忽略
- `flutter build windows --debug`：通过，产物 `build\windows\x64\runner\Debug\wuxia_idle.exe`
- GUI：每张图单独重启 debug exe，窗口固定 `1280 x 950`
- 截图工具：PowerShell + Win32 `MoveWindow` + `System.Drawing.Graphics.CopyFromScreen`
- 截图目录：`docs/screenshots/w16_festival_chip_visual_check/`

## 3. 截图清单与评级

| 编号 | 文件 | 评级 | 说明 |
|---|---|---:|---|
| 01 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_chunJie.png` | PASS | chip 显示「今日：春节」，位置居中，样式与主菜单协调。 |
| 02 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_yuanXiao.png` | PASS | chip 显示「今日：元宵」，中文渲染正常。 |
| 03 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_duanWu.png` | PASS | chip 显示「今日：端午」，背景、描边、圆角一致。 |
| 04 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_qiXi.png` | PASS | chip 显示「今日：七夕」，未挤压按钮列。 |
| 05 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_zhongQiu.png` | PASS | chip 显示「今日：中秋」，视觉规格一致。 |
| 06 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_chongYang.png` | PASS | chip 显示「今日：重阳」，6 节日样式一致。 |
| 07 | `docs/screenshots/w16_festival_chip_visual_check/w16_festival_chip_cleared.png` | PASS | 清除覆盖后主菜单不显示「今日：」chip，baseline 正常。 |

## 4. 视觉层反馈

- chip 位于标题「挂机武侠 · 调试主菜单」下方居中，留白克制。
- chip 为灰墨 panel 背景、细描边、圆角胶囊形，文字为低饱和灰色；整体符合现有水墨克制风格。
- 6 个节日 chip 的尺寸、padding、字号、背景、描边表现一致。
- 中文显示无方框、缺字或异常字体回退。
- 主菜单 8 个入口均可见且保持居中、等距；chip 出现未破坏布局。

## 5. 已知偏差

- 无产品视觉偏差。
- 工具链偏差：`flutter clean` 后直接 build 会因为本机缺少 generated part 文件失败；补跑 `dart run build_runner build --delete-conflicting-outputs` 后可正常 debug build。
- 操作层记录：最初使用 `1280 x 900` 截图时第 8 个按钮底部贴近窗口下沿，最终改用 `1280 x 950`，仍满足派单「每张 >= 1280 x 900」要求，并完整显示 8 个入口。

## 6. 下次推荐

- Windows 视觉验收继续采用 `flutter clean` -> `build_runner` -> `flutter build windows --debug` 的顺序，避免 clean 后 generated 文件缺失。
- 对需要滚到底部触发 debug 入口的验收，建议每张图单独重启 exe 或重置页面滚动状态，减少坐标自动化误点。
