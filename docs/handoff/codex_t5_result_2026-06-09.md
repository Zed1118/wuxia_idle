# T5 闭关地图化 closeout

分支: codex/t5-seclusion-map  改后 commit: 6931607

改了哪几屏:
- [x] list: 地图卡片增加统一装帧、地点产出符号和锁定态保留山水底图。
- [x] setup: 地点 hero 与每小时产出预估接入同一套地点图标/色调。
- [x] active: 入定面板增加地点印记与产出符号，行功进度跟随地点主色。
- [x] result: 收功 hero 保留仪式素材，并补上地点印记与产出偏向。

截图: `docs/handoff/visual_capture_981085a_20260609_115936/`（4 屏；本机窗口 id 获取失败，脚本输出 5120x2880 全屏兜底 PNG，未生成 1280x720 + 1920x1080 双分辨率文件）

本地闸门: `flutter test test/features/seclusion/` PASS · `flutter analyze` 0

踩坑: 截图脚本在当前 macOS 桌面环境取不到窗口 id，只能走全屏兜底；图片文件被 gitignore 忽略，目录内 manifest 已入库，PNG 留在本地 `docs/handoff/visual_capture_981085a_20260609_115936/`。

待 Claude 过闸: 全量测试 + 硬编码/红线扫 + 行为 diff -> ff 合 main
