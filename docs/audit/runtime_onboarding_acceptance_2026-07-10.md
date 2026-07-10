# macOS 生命周期与新手前 30 分钟验收（2026-07-10）

## 范围

本轮只做运行验收，不做发布准备，不改业务代码、数值、schema 或存档。

- 新档祖师塑形、开局首战与单人主线推进曲线。
- 离线结算 gate、前后台生命周期接线和离线回顾界面。
- 真实 macOS 原生窗口渲染与 Finder 失焦/重新聚焦冒烟。

## 自动化结果

执行：

```bash
flutter test --no-pub \
  test/features/onboarding/onboarding_first_30min_battle_test.dart \
  test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart \
  test/features/seclusion/application/online_presence_controller_test.dart \
  test/features/seclusion/presentation/online_presence_lifecycle_hook_test.dart \
  test/features/seclusion/presentation/offline_passive_gate_test.dart \
  test/features/seclusion/presentation/offline_recap_gate_test.dart \
  test/features/seclusion/application/offline_recap_service_test.dart
```

结果：27 passed / 0 failed。

- 生产配置下三种祖师开局首关均不应失败。
- 单人队伍从第 1 章到第 6 章的连续整备路径无 1v3 硬卡死。
- 首启去重、失焦 touch、聚焦静默结算、active 闭关互斥与离线回顾 gate 均通过。

## macOS 真机结果

用 `tools/visual_capture/visual_capture.sh` 在 macOS debug app 中逐路由冷启动，窗口逻辑尺寸 1440x900，Retina 截图均为 2880x1800：

| 路由 | 结果 |
|---|---|
| `founder_creation` | READY，原生 window-id 截图成功 |
| `main_menu` | READY，离线回顾在主菜单正常展示 |
| `mainline_first_clear_battle_auto` | READY，首通真战斗正常渲染 |
| `offline_recap_passive` | READY，被动离线收益明细正常渲染 |

四份日志均未发现 `Exception`、`Error`、`RenderFlex` 或 overflow；截图非空，文字、按钮和主要内容未重叠。

另单独启动 `main_menu`，切 Finder 前台 3 秒后重新聚焦游戏并保持 5 秒。应用进程保持存活，日志无 `OnlinePresence touchOnlineNow skipped` 或其他生命周期错误。

本机证据保存在 `/tmp/wuxia_runtime_acceptance_20260710/`，不纳入 git。

## 结论与边界

本轮未发现阻断新手前 30 分钟或在线/离线切换的回归问题，可以维持当前实现。

“前 30 分钟”由生产配置确定性战斗轨迹和六章连续整备回归覆盖，并非人工按秒游玩 30 分钟；真实桌面部分负责验证关键页面和前后台切换。长时间睡眠、强杀进程和系统重启仍属于后续耐久验收，不在本轮结论内。
