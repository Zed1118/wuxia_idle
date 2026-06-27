# visual_capture

出版美术视觉验收批量截图。对每个 `VISUAL_ROUTE` 启动 macOS debug app,
等就绪信号截 Flutter 窗口,产图到 `docs/handoff/visual_capture_<sha>_<ts>/`。

## 用法

    tools/visual_capture/visual_capture.sh              # 截 smoke 固定 route
    tools/visual_capture/visual_capture.sh --suite full # 截全量 route(耗时长)
    tools/visual_capture/visual_capture.sh main_menu    # 只截指定 route id
    tools/visual_capture/visual_capture.sh --dry-run    # 打印 route/seed/检查清单,不启 app
    flutter pub run tool/visual_acceptance.dart checklist --suite smoke

route id 见 `lib/features/debug/application/visual_route.dart` 的 `VisualRoute`。
固定验收计划由 `lib/features/debug/application/visual_acceptance_plan.dart`
生成:

- `smoke`:默认快验入口,覆盖主菜单、心法面板、战斗破招/败北等高频视觉面。
- `full`:全部 `VisualRoute.values`(排除 `hub`),用于大改 UI 后完整回收。

新增验收屏:加 `VisualRoute` 枚举值 + `VisualRouteHost` 映射。若需纳入快验,
再把 route 加进 `visual_acceptance_plan.dart` 的 `smoke` 清单。

## 固定 seed

清单中的 seed 为 `visual-route-host-fixture-20260627`。它表示 route 由
`VisualRouteHost` 里的固定 seed service / fixture 构造,同一 route 在同一代码版本下
应稳定复现。需检查具体截图点时,先跑:

    flutter pub run tool/visual_acceptance.dart dry-run --suite smoke

再按清单读取 route label 与 checks。

## 依赖

- macOS `screencapture`(需 Screen Recording 权限,首次会弹授权)
- `python3` + PyObjC `Quartz`(**可选**,`pip3 install pyobjc-framework-Quartz`)
  —— `window_id.py` 用 CGWindowList 按 app 进程名取窗口 id 截**干净窗口**,
  需 Screen Recording 权限。**缺 Quartz 或缺权限时自动退化为非交互全屏兜底**
- Flutter macOS desktop 已 enable

> 注:在 Claude Code CLI / 无头后台会话里通常**既无 PyObjC 也无屏录权限** →
> 走全屏兜底(图含桌面杂物)。需要像素级干净窗口图时,在装了 PyObjC + 授了
> Screen Recording 的环境跑(如 Codex 桌面),或直接派 Codex 做视觉验收。

取窗 id 失败时回退**非交互全屏**(`screencapture -x`,零权限不卡,图含桌面杂物,
读图看 app 窗口区域即可)。每个 route 启动前会先清残留 app 窗口,防截到旧窗。

## 产物

`<out>/<route>.png` + `manifest.txt`(route→文件→就绪状态),供 Codex / 读图对照。
截图不入 git(随项目惯例留本地),仅脚本与 README 入库。
