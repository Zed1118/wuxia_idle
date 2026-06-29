# 设置页二期计划

## 目标

集中整理舒适性选项：音量分组、战斗速度、文字密度、窗口/全屏、减少闪烁。设置均为本机偏好，走 `SharedPreferences`，不进 Isar 存档，不改战斗结算。

## 分支

`codex/next-settings-v2`

## 验收标准

- 设置页按音频、战斗舒适性、显示、存档/系统信息分段。
- 音频仍保留总音量、BGM、音效、静音并即时生效。
- 新增战斗速度、文字密度、减少闪烁偏好并可持久化。
- 窗口/全屏设置复用既有 `DisplaySettings` 和窗口控制器。
- 战斗速度只影响战斗屏播放节拍，不改变 `BattleNotifier` / 结算结果。
- 减少闪烁只降低/跳过屏幕闪白与受击闪，不改伤害、命中、日志。
- 跑 targeted tests 与 `flutter analyze`。

## 任务切片

- [x] 读取启动文档并定位现有设置存储/设置页/战斗表现接线。
- [x] 扩展 `GameplaySettings`：战斗速度、文字密度、减少闪烁。
- [x] 重排设置面板，新增分段标题与控件。
- [x] 接入战斗屏表现层：速度倍率、减少闪烁。
- [x] 补 targeted tests。
- [x] 跑 targeted tests 与 `flutter analyze`。
- [ ] 更新恢复点并提交。

## 当前恢复点

- 状态：实现完成，验证通过，待提交。
- 最后完成：设置页按音频/战斗舒适性/窗口与显示/存档与系统分段；新增战斗速度、文字密度、减少闪烁偏好；战斗速度接入 `BattleScreen` Timer，减少闪烁跳过战斗闪白与受击闪。
- 下一步：提交 `codex/next-settings-v2`。
- 已跑验证：`flutter analyze`；`flutter test --no-pub -j1 test/features/settings/gameplay_settings_service_test.dart test/features/settings/settings_panel_autoplay_test.dart test/features/settings/settings_panel_overflow_test.dart test/features/settings/application/display_settings_service_test.dart test/features/settings/application/display_settings_controller_test.dart test/features/settings/audio_settings_service_test.dart`；`flutter test --no-pub -j1 test/features/battle/presentation/battle_screen_pause_test.dart test/features/battle/presentation/battle_screen_log_test.dart test/features/battle/presentation/playback_hold_test.dart`。
- 阻塞项：无。备注：CodeGraph 未初始化，已回退本地检索。
