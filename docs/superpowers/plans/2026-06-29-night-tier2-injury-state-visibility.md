# 2026-06-29 晚间第二梯队：角色伤势状态表现增强

## 目标

让伤势不只停留在战斗数值影响中，而是在角色卡、战斗前信息、战后摘要里有明确状态文案，并复用已合入的疗伤丹入口提供恢复行动。

## 分支

- `codex/night-tier2-injury-state-visibility`
- Worktree: `/Users/a10506/.codex/worktrees/night-tier2-injury-state-visibility/挂机武侠`

## 范围

- 复用既有伤势模型、疗伤丹使用服务、战后疗伤丹面板。
- UI 文案集中到 `UiStrings` 或既有集中格式化层。
- 不新增治疗经济、道具、掉落、在线 buff、快进或新存档 schema。
- 不依赖暂缓的爬塔/Boss 分支改动。

## 验收标准

1. 角色卡能直接看出角色无伤、轻伤或重伤状态，并在可恢复时给出恢复入口。
2. 主线战斗前信息能提示出战成员伤势状态与影响，不做强制教程弹窗。
3. 战后摘要对本场后仍有伤势的角色给出明确状态文案，并保留/复用疗伤丹恢复入口。
4. 所有新增中文 UI 文案进入集中层，不在 presentation 调用点散写。
5. targeted widget/unit tests 覆盖新增展示逻辑；跑 touched-file analyze。

## 任务切片

1. 盘点伤势模型、疗伤丹入口、角色卡、战前信息与战后摘要现有代码。
2. 设计一个轻量的伤势状态展示格式化/组件复用点。
3. 接入角色卡伤势文案与恢复入口。
4. 接入战斗前信息伤势提示。
5. 接入战后摘要伤势文案，复用疗伤丹面板。
6. 补 targeted tests 与 touched-file analyze。
7. 更新恢复点、提交小切片。

## 当前恢复点

- 状态：实现完成，待提交。
- 最后完成：新增伤势状态 formatter/widget；角色卡显示无伤/带伤/重伤状态与疗伤丹入口；战前情报显示受伤出战角色；主线战后摘要显示伤势状态；既有战后疗伤丹面板追加当前伤势行，覆盖普通 overlay / 主线 / 爬塔已接入口。
- 下一步：提交实现切片，最终复核 git 状态。
- 已跑验证：
  - `dart run build_runner build --delete-conflicting-outputs`（当前 build_runner 版本忽略该参数，写出 112 个 gitignored outputs）
  - `flutter test --no-pub test/features/injury/presentation/injury_status_view_test.dart test/features/loot_preview/stage_intel_dialog_test.dart test/features/mainline/presentation/stage_list_screen_test.dart test/features/loot_preview/stage_row_loot_wiring_test.dart test/features/character_panel/presentation/character_panel_screen_test.dart test/features/mainline/presentation/stage_victory_dialog_test.dart`（70/70 passed）
  - `dart analyze lib/features/injury/presentation/injury_status_view.dart lib/features/inventory/presentation/post_battle_healing_panel.dart lib/features/character_panel/presentation/character_panel_screen.dart lib/features/loot_preview/presentation/stage_intel_dialog.dart lib/features/mainline/presentation/stage_list_screen.dart lib/features/mainline/presentation/stage_entry_flow.dart lib/features/mainline/presentation/stage_victory_dialog.dart lib/shared/strings.dart test/features/injury/presentation/injury_status_view_test.dart test/features/loot_preview/stage_intel_dialog_test.dart test/features/character_panel/presentation/character_panel_screen_test.dart test/features/mainline/presentation/stage_victory_dialog_test.dart`（No issues found）
- 阻塞项：无。
