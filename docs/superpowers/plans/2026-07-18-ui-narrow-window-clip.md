# 窄窗 UI 左裁与头像占位统一修复计划

## 目标

- 修复 1055pt 左右窄窗下 11 个视觉路由的内容整体左移与左裁。
- 追踪 `VISUAL_WINDOW_W` 到 macOS 原生窗口的消费链路，解释请求 1280 而实测约 1055pt 的原因。
- 将候选行和编成卡无立绘态统一为“首字文字占位 + 稀有度描边”，保留真立绘路径。
- 将 `chapter_list` 副标题移出横向滚动区，固定显示。

## 分支

- 基点：`feat/baicao-duanhun-phase-b` (`93b5fcb3`)
- 工作分支：`codex/ui-narrow-window-clip`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/ui-narrow-window-clip`

## 验收标准

- [x] 生产接线证据：记录共享组件/屏文件、入口与消费方。
- [x] 11 个问题/附带屏分别于 1280×720、1440×900、1055×720 截图，左缘完整且无右侧异常空带。
- [x] 4 个对照组中抽 `gauntlet_interlude` / `main_menu` 视觉回归。
- [x] 截图仅放 `/tmp/wuxia-ui-narrow-after`，不入库且不放 `docs/reviews/`。
- [x] `dart format` 覆盖全部改动 Dart 文件。
- [x] `flutter analyze --no-pub` 为 0 issues。
- [x] 改动屏的既有 widget/visual_route targeted 测试全绿，命令与通过数见下。
- [x] 未改交互组件；`InkWell` / `PlaqueButton` 等消费方未动，semantics/键盘/focus/mouse cursor 路径不变。
- [x] 纯表现层：不改 `numbers.yaml`、schema、`saveVersion`、provider/service、业务逻辑、`GDD.md`、`CLAUDE.md`、data yaml。
- [x] 列清未覆盖屏、分辨率、未目检项和其他残留风险。
- [x] 工作区全 commit 干净，tip commit 以 `[READY]` 开头。

## 任务切片

1. 按指定顺序完成 fresh worktree 依赖、生成、analyze 和 debug build 基线。
2. 稳定复现并比对坏屏/好屏外壳，追踪窗口尺寸数据流。
3. 先添加能捕捉左裁/占位回归的最小失败测试，再实装根因修复。
4. 完成 `chapter_list` 副标题固定与头像占位统一。
5. 格式化、定向测试、analyze、debug build 及三档视觉验收。
6. 核对红线/生产接线/残留风险，小切片提交后补 `[READY]` tip。

## 当前恢复点

- 状态：已完成，分支冻结待 Claude 终判合并。
- 最后完成：根修 `MainFlutterWindow` 首 run loop 恢复覆盖居中 frame；`PortraitFrame` 统一 null/加载失败首字占位；远行/断魂庄候选行传入角色名；章节副标题基点已在横滚外，补结构回归测。
- 下一步：Claude 按本计划证据终判合并。
- 已跑验证：18 个相关测试文件 `180/180` 通过；39 张截图 `READY/window_id=39/39`、0 fallback/warn；`flutter analyze --no-pub` 0 issues；`flutter build macos --debug --no-pub` 成功；修复前原生窗口 `x=-1695`（副屏可见左缘 `-1470`，固定裁 225pt），修复后 1280 档 `x=640`。
- 阻塞项：无。

## 生产接线与根因证据

- 入口：`main.dart` 在 visual route 模式短路 `window_manager`，原生 `macos/Runner/MainFlutterWindow.swift` 直接消费 `VISUAL_WINDOW_W/H`。
- 根因：`awakeFromNib` 内已正确算出 1280 档居中 frame `x=640`，但 Flutter/macOS 窗口恢复在下一 run loop 将原点覆盖为 `x=-1695`，尺寸仍为 1280；所在副屏左缘为 `-1470`，故物理裁去 225pt，可见宽约 1055pt。
- 根修：仅 visual env 生效时，在下一 main queue run loop 重申已算好的 forced frame；production 无 env 路径不变。所有问题页都消费这一原生窗口，因此不逐屏加 padding。
- 头像路径：`expedition_overview_screen.dart` / `gauntlet_loadout_screen.dart` 候选行 → 共享 `PortraitFrame`；null 或资产加载失败显角色首字，原有描边不变，真立绘仍优先。
- `chapter_list` 在基点中的 `mainlineRouteMapSubtitle` 已位于横向 `SingleChildScrollView` 之外；本批不重复改布局，只加祖先结构测防回退。

## 验证证据

- targeted：`flutter test --no-pub` 后跟 18 个相关 widget/visual-route 文件，`180/180` 通过。
- 截图：`/tmp/wuxia-ui-narrow-after`，13 route × 3 档 = 39 张；问题屏 10 + `chapter_list` + 对照 `gauntlet_interlude` / `main_menu`。
- 尺寸：1280 档 PNG `2560×1440`，1440 档 `2880×1800`，1055 档 `2110×1440`（Retina 2×）。

## 残留风险

- 未穷举全部 visual route；本批覆盖用户点名屏、章节附带屏与 2 个对照屏。
- 未验收低于 1055pt 的生产布局；修复前的 225pt 裁切不是 Flutter 响应式阈值，而是窗口原点错位，对任意请求宽度都会固定裁 225pt。
- macOS 多屏坐标排列与本机不同时，仍依赖 `self.screen ?? NSScreen.main` 选定目标屏；修复只保证已计算居中 frame 不再被首帧恢复覆盖。
