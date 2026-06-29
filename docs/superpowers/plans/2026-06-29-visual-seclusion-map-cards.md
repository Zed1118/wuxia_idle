# 2026-06-29 · visual-seclusion-map-cards

## 目标

在 `codex/visual-seclusion-map-cards` 分支中，将闭关地图列表改成更清晰的地点画片式卡片。仅调整 presentation 视觉层级：地点名、境界门槛、预期产出、当前状态。不得新增地图风味玩法、地域事件、新收益或改变闭关业务逻辑。

## 分支

- Worktree: `/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/visual-seclusion-map-cards`
- Branch: `codex/visual-seclusion-map-cards`

## 验收标准

- locked / available / active 三态在地图卡中清晰可见。
- 境界门槛使用真实 `requiredRealm` 文案；不引入章节、材料等假门槛。
- 预期产出只展示现有闭关收益维度，不接入新地域化产出。
- 入口行为不变：active 进入查看，available 进入 setup，locked 仍按既有 SnackBar 提示。
- 中文 UI 文案集中在 `UiStrings`。
- 运行 `build_runner`、相关 seclusion widget tests、`flutter analyze`、`git diff --check`。

## 任务切片

1. 读取 `AGENTS.md`、`CLAUDE.md`、`docs/spec/rejected_task_registry.md` 并确认已否边界。
2. 梳理闭关地图列表 UI、视觉 helper、现有 widget tests。
3. 新增少量 `UiStrings` 标签与视觉输出 helper。
4. 重排地图卡为画片图片区 + 宣纸信息栏。
5. 补 widget 断言覆盖门槛、产出、状态标签。
6. 格式化并运行验收命令。
7. 提交 `feat(seclusion): polish retreat map cards`。

## 当前恢复点

- 状态：已实现，待提交。
- 最后完成：闭关地图卡已改为地点画片式版式，新增 `UiStrings` 标签与地图列表 widget 断言；未改闭关收益、解锁、cap、结算、save/schema/numbers。
- 下一步：提交 `feat(seclusion): polish retreat map cards`。
- 已跑验证：
  - `dart format lib/features/seclusion/presentation/seclusion_map_list_screen.dart lib/features/seclusion/presentation/seclusion_map_visuals.dart lib/shared/strings.dart test/features/seclusion/presentation/seclusion_map_list_screen_test.dart`
  - `flutter pub run build_runner build --delete-conflicting-outputs`（退出码 0；该参数已被当前 build_runner 忽略但构建成功）
  - `flutter test test/features/seclusion/presentation`（退出码 1；`offline_passive_gate_test` 在 `setUpAll` 下载 IsarCore 被 widget test HTTP 400 拦截，非本分支 UI 断言失败）
  - `flutter test test/features/seclusion/presentation/seclusion_map_list_screen_test.dart`（7/7 passed）
  - `flutter analyze`（No issues found）
  - `git diff --check`（退出码 0）
- 阻塞项：无。
