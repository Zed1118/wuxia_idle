# L1 全屏 / 分辨率显示设置 — 设计 + 实装 spec

> 2026-06-15 · **已实装并合 main**（commit `130b40ac`，10 测 TDD）。
> 引入 window_manager 0.5.1。窗口实际效果待真机/Codex 验收（见 §4）。

## §1 设计决策（用户拍板 2026-06-15）

1. **持久化走 SharedPreferences，不进 Isar 存档** — 窗口模式/分辨率是端机本地偏好，不该跨设备同步，绕开 saveVer 迁移。
2. **三档分辨率预设** — 1280×720 / 1600×900（默认）/ 1920×1080 + 全屏；不做任意拖拽档（桌面本就能拖窗口边）。
3. **F11 全局快捷键** 切全屏 + 设置面板开关双入口。
4. **macOS 原生零改动** — `MainFlutterWindow.swift` 的 `minSize==maxSize` 锁**只在 `VISUAL_WINDOW_W/H`（视觉验收模式）生效**，production 不锁；window_manager 经 `RegisterGeneratedPlugins` 自动注册，Dart 侧调用即可。

## §2 架构（platform channel 隔离 → 可测）

```
DisplaySettings (domain, 值对象)            ← 5 测
  └ WindowSizePreset enum + size 映射
DisplaySettingsService (SharedPreferences)  ← 3 测
WindowController (abstract)                  ← fake 注入隔离 platform channel
  └ WindowManagerController (真 window_manager 薄封装,不测)
DisplaySettingsController (save + apply 编排) ← 2 测（fake window）
display_settings_providers (裸 provider,免 build_runner)
```

可测逻辑（domain/service/controller 编排）全 TDD；platform channel 副作用（`windowManager.setFullScreen/setSize`）由 fake 隔离，真实现薄封装不测。

## §3 实装落点（commit `130b40ac`）

| 触点 | 文件 |
|---|---|
| domain | `settings/domain/display_settings.dart` |
| 持久化 | `settings/application/display_settings_service.dart` |
| 窗口副作用 | `settings/application/window_controller.dart` |
| 编排 | `settings/application/display_settings_controller.dart` |
| providers | `settings/application/display_settings_providers.dart` |
| 设置 UI | `settings/presentation/settings_panel.dart`（`_DisplaySettingsSection`） |
| 启动应用 | `main.dart`（window init，visual-route 短路之后） |
| F11 | `main.dart`（`WuxiaApp` Shortcuts/Actions） |
| 文案 | `shared/strings.dart`（`settingsFullscreen*` / `settingsResolution*`） |
| 依赖 + 平台 | `pubspec.yaml` + macos/windows plugin 注册 |

- 全屏时分辨率下拉禁用（全屏忽略尺寸）。
- 0 改 Isar schema / numbers.yaml / 红线。

## §4 待验收（bg 会话无法做，需真机/Codex）

platform channel + GUI 效果代码层全绿（analyze 0 / 全量 2213 测零回归），但以下需 macOS 真机或 Codex 验收：

1. 全屏开关 / 退出全屏实际生效。
2. 三档分辨率切换窗口真 resize + 居中。
3. **F11 全局快捷键**实际触发（Shortcuts 在 MaterialApp 之上的焦点冒泡需实测；若不灵，设置面板开关是可靠主入口，F11 留 backlog）。
4. 启动应用上次保存的窗口设置。
5. Windows 发布目标平台的 window_manager 行为（windows plugin 注册已同步）。
