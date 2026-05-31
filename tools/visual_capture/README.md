# visual_capture

出版美术视觉验收批量截图。对每个 `VISUAL_ROUTE` 启动 macOS debug app,
等就绪信号截 Flutter 窗口,产图到 `docs/handoff/visual_capture_<sha>_<ts>/`。

## 用法

    tools/visual_capture/visual_capture.sh              # 截全部 route
    tools/visual_capture/visual_capture.sh main_menu    # 只截指定 route id
    tools/visual_capture/visual_capture.sh --dry-run    # 打印计划不启 app

route id 见 `lib/features/debug/application/visual_route.dart` 的 `VisualRoute`。
新增验收屏:加 VisualRoute 枚举值 + VisualRouteHost 映射 + 本脚本 ALL_ROUTES。

## 依赖

macOS `screencapture` / `osascript`;Flutter macOS desktop 已 enable。
窗口 id 取失败时回退交互式全屏(需手动框选)。

## 产物

`<out>/<route>.png` + `manifest.txt`(route→文件→就绪状态),供 Codex / 读图对照。
截图不入 git(随项目惯例留本地),仅脚本与 README 入库。
