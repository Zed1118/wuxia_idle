# 资源总览页计划

## 目标

在 `codex/next-resource-overview` 分支实现一个只读资源经营面板，汇总银两、磨剑石、心血结晶、桃花岛产物、丹药、秘籍等库存，并展示主要用途与主要来源。

## 边界

- 只读展示，不新增资源、不改经济、不改结算。
- 复用现有 `InventoryItem` 库存、`ItemUsageLookupService`、`MaterialSourceLookupService`、商店需求提示相关格式化、桃花岛配置与产物能力。
- UI 文案走 `UiStrings` 集中层，不在 presentation/domain 散写中文。
- 不改 `numbers.yaml`、schema、saveVersion。

## 验收标准

- 主菜单可进入资源总览页。
- 页面按类别显示核心资源库存、主要用途、主要来源。
- 零库存但属于核心经营资源的项目仍可展示，避免玩家不知道资源体系。
- 只读，无使用、购买、领取、结算、升级等动作。
- targeted tests 与 `flutter analyze` 通过。

## 任务切片

- [x] 梳理现有资源 defId 与用途/来源服务。
- [x] 新增资源总览 view model / provider。
- [x] 新增资源总览 presentation 页面。
- [x] 主菜单接入口与集中 UI 文案。
- [x] 增加 targeted tests。
- [x] 跑 targeted tests 与 `flutter analyze`。
- [x] 提交分支 commit。

## 当前恢复点

- 状态：实现、验证与提交准备完成。
- 最后完成：新增 `resource_overview` 只读聚合服务/provider/页面，主菜单入口接入，补资源总览与主菜单 targeted tests；本线程自审修正 `UiStrings` 反向依赖 feature domain 的结构问题。
- 下一步：提交本分支。
- 已跑验证：
  - `flutter pub run build_runner build --delete-conflicting-outputs`（补齐当前 worktree 缺失的生成文件；无生成文件进入 git diff）。
  - `flutter test --no-pub -j1 test/features/resource_overview/resource_overview_service_test.dart test/features/resource_overview/resource_overview_screen_test.dart test/features/main_menu/presentation/main_menu_test.dart`：55/55 passed。
  - `flutter analyze`：No issues found。
- 审查：外部只读审查子代理因用量限制未返回；本线程完成自审，确认无写存档/结算/经济变更，UI 文案集中于 `UiStrings`。
- 阻塞项：无。备注：首次 `flutter test` 在生成文件缺失时触发 Flutter tool native-assets crash，产生 `flutter_01.log`/`flutter_02.log`，两者为 ignored 文件，未进入 git diff。
