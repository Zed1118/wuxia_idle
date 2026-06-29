# 2026-06-29 今晚挂机任务 13：闭关溢出保护

## 目标

闭关达到收益上限后，主界面和回归卡明确提示已满，并提供一键收功入口；只改善状态可读性和入口，不提高收益上限，不引入加速、在线 buff 或收益分流。

## 分支

`codex/night-tier2-seclusion-cap-protection`

## 验收标准

- 主界面 active 闭关横幅在达到有效结算上限后显示“已满/可收功”状态，并点击直达既有 `ActiveRetreatScreen`。
- 主菜单闭关入口状态在闭关达到收益上限后显示已满，不只显示普通完成。
- 回归卡在 `OfflineRecapLimitReason.systemCap` 时显示已达封顶提示，并保留“前去收功”入口。
- 不修改 `numbers.yaml` 的 `retreat.cap_hours` 或任何收益公式。
- 不新增快进、加速、在线 buff、闭关收功选择分流或闭关归来事件小结。
- targeted tests 与 touched-file analyze 通过。

## 任务切片

1. 计划文件与现状定位。
2. 增加闭关 cap 状态展示 helper/文案，并接主菜单横幅与入口状态。
3. 强化回归卡已满提示与测试。
4. 跑 targeted tests/analyze，修复问题。
5. 小切片 commit，更新恢复点。

## 当前恢复点

- 状态：实现完成，待提交。
- 最后完成：主菜单闭关入口、主菜单 active 闭关横幅、离线回归卡均已区分 `retreat.capHours` 系统封顶状态；回归卡保留收功入口并在封顶时显示“一键收功”；未改收益公式与上限。
- 下一步：提交小切片并汇报。
- 已跑验证：`dart run build_runner build --delete-conflicting-outputs`（当前 build_runner 版本提示该参数已忽略，生成 112 个 gitignored outputs）；`flutter test --no-pub test/features/seclusion/application/offline_recap_service_test.dart test/features/seclusion/presentation/offline_recap_card_test.dart test/features/main_menu/main_menu_retreat_banner_test.dart`（17 passed）；`flutter analyze`（0 issue）。
- 阻塞项：无。
