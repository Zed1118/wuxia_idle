# 2026-06-29 问鼎九霄进度条美化

## 目标

在问鼎九霄/爬塔页增强进度展示：让当前可挑战层、最高已通层、下一阶段节点（小 Boss / 大 Boss / 登顶）更清楚，并让九霄塔势节点更有段落感。只做展示层与只读派生，不改战斗、推进、奖励、解锁或数值结算。

## 分支

`codex/fourth-tower-progress-polish`

## 验收标准

- 顶部进度卡显示当前进度比例、当前可挑战层、最高已通层与下一节点/阶段目标。
- 30 层塔势中，小 Boss、大 Boss、当前最高进度/当前可挑战层有清晰但克制的视觉标记。
- 文案新增到 `lib/shared/strings.dart`，presentation 不散写中文。
- 不修改 `docs/spec/playability_phase2_backlog.md`，不触碰已否方向（装备目标追踪、部位缺口提醒、材料替代路径、碎片来源聚合等）。
- 不改 `TowerProgressService.recordClear/recordDefeat/advanceCycle` 的推进、奖励或数值语义。
- 补充/更新 tower widget 或 unit tests，覆盖新进度摘要。
- 运行 tower targeted tests 与 `flutter analyze`。

## 任务切片

1. 读 CLAUDE/GDD/backlog/已否清单，确认红线与范围。
2. 定位 tower presentation/application 现状。
3. 新增只读进度摘要派生模型。
4. 美化顶部进度卡和塔势节点。
5. 补充 `UiStrings` 文案与 widget tests。
6. 跑 targeted tests、`flutter analyze`，自查范围。
7. 提交 commit 并标记 ready。

## 当前恢复点

- 状态：已完成，待提交。
- 最后完成：新增 `TowerProgressSummary` 只读派生；顶部进度卡改为进度条 + 当前可挑战层 + 最高进度 + 下一节点；九霄塔势增强当前层、最高层与 Boss 节点标记；补充 tower widget/application tests。
- 下一步：提交 commit。
- 已跑验证：
  - `dart run build_runner build --delete-conflicting-outputs`
  - `flutter test test/features/tower/application/tower_progress_summary_test.dart test/features/tower/presentation/tower_floor_list_screen_test.dart`
  - `flutter test test/features/tower`
  - `flutter analyze`
- 阻塞项：无。
