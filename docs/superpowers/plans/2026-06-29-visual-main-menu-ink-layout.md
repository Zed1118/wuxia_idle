# 主菜单水墨版式重排

## 目标

- 将主菜单入口从按钮堆叠重排为「江湖行程 / 养成经营 / 档案藏卷 / 设置」四个清晰分区。
- 强化第一屏水墨质感，保留现有入口、门控、导航和状态派生。
- UI 中文文案集中在 `UiStrings`。

## 边界

- 只改主菜单视觉和版式，不新增业务规则、结算、收益、存档 schema、数值或 data 规则。
- 不改 mainline / tower / inventory / taohua / seclusion / shop 等入口门控。
- 不做状态催促、目标追踪、登录/日常/VIP/抽卡/体力/快进等反主流项。
- 不触碰其他 worktree 或 main。

## 实施步骤

1. 读取 `AGENTS.md`、`CLAUDE.md` 与 `docs/spec/rejected_task_registry.md`。
2. 梳理 `MainMenu` 入口数组、门控表达式与现有 widget tests。
3. 在 `UiStrings` 增加分区标题与短说明。
4. 重排入口数组到四个语义分区，保持每个按钮原有 `onTap` / `disabled` / `locked` / `status` 逻辑。
5. 替换 `_MenuSectionsLayout` 为宽窄屏响应式水墨分区面板。
6. 更新 main menu widget tests 覆盖分区标题、入口数量和相对顺序。
7. 运行指定生成、测试、分析与 diff 检查。

## 验收标准

- 主菜单仍显示既有入口，默认 debug 下 `WuxiaInkButton` 数量不变。
- 入口分组清晰：江湖行程、养成经营、档案藏卷、设置均可见。
- 按钮沿用 `WuxiaInkButton`，保留桌面语义、点击、锁定与状态显示。
- 不改变入口解锁/导航逻辑。
- Dart UI 调用点不散写新增中文文案。
- `dart run build_runner build --delete-conflicting-outputs`、相关 main menu widget tests、`flutter analyze`、`git diff --check` 通过。

## 红线自查

- 数值红线：不触及。
- 三系锁死：不触及。
- 在线 = 离线：不触及。
- 反主流不做项：不新增体力、日常、登录、战令、抽卡、VIP、快进或催促式留存。
- 已否任务：不做已否清单中的任务方向。

## 当前恢复点

- 状态：已实现，提交前验证中。
- 最后完成：主菜单四分区水墨版式、`UiStrings` 分区文案、main menu widget 断言与桌面视口 smoke。
- 下一步：运行 `git diff --check` 后提交。
- 已跑验证：
  - `dart run build_runner build --delete-conflicting-outputs` 通过。
  - `flutter test test/features/main_menu/presentation/main_menu_test.dart test/features/main_menu/main_menu_retreat_banner_test.dart test/features/main_menu/main_menu_status_summary_test.dart` 通过，60 tests passed。
  - `flutter analyze` 通过，No issues found。
- 阻塞项：无。
