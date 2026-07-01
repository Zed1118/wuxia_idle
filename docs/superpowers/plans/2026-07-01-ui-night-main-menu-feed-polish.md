# 夜间 UI polish A：主菜单 / 主页信息流

## 目标

- 优化 `MainMenu` 入口信息层级、宽屏最大宽度、双列间距与按钮可扫描性。
- 优化 `HomeFeedScreen` 宽屏阅读宽度与底部快速领取按钮风格。
- 只做视觉与布局 polish，不新增业务逻辑、教程弹窗或营销式 landing。

## 分支

- worktree: `/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/ui-night-main-menu-feed-polish`
- branch: `codex/ui-night-main-menu-feed-polish`
- base: `e16e337b`

## 验收标准

- 主菜单入口仍沿用既有门控、导航和 `WuxiaInkButton`。
- HomeFeed 快速领取仍执行原 mark-read + `pushReplacement` 流程。
- 不改 `data/`、save/schema、战斗结算、离线收益或门控逻辑。
- 新增/调整测试覆盖布局约束和按钮风格。
- `flutter analyze`、指定 widget tests、`git diff --check` 通过。

## 任务切片

1. 检查 worktree git 状态。
2. 阅读主菜单、HomeFeed、现有按钮组件和相关测试。
3. 调整主菜单宽屏内容宽度、行程优先分区和双列间距。
4. 调整顶部状态摘要/闭关 banner 与主内容列对齐。
5. 调整 HomeFeed 列表最大阅读宽度、feed item 层级和快速领取按钮风格。
6. 更新相关 widget tests。
7. 运行指定验证并提交 `[READY]` commit。

## 当前恢复点

- 状态：已完成，等待复审/合并。
- 最后完成：主菜单宽屏入口层级、HomeFeed 信息流与快速领取按钮 polish，相关 widget tests 已更新。
- 下一步：由主窗口复审 `[READY]` commit。
- 已跑验证：
  - `git status --short --branch`
  - `dart format ...`
  - `flutter pub get`
  - `dart run build_runner build --delete-conflicting-outputs`
  - `flutter test --no-pub test/features/main_menu/presentation/main_menu_test.dart test/features/home_feed/presentation/home_feed_screen_test.dart test/features/home_feed/presentation/home_feed_screen_quick_claim_test.dart`
  - `flutter analyze`
  - `git diff --check`
- 阻塞项：无。
