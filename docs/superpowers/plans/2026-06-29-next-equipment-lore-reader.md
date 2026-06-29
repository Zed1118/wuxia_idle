# Equipment Lore Reader Plan

## Goal

把装备详情里的典故升级为更像「器物志」的阅读层:同装备多段预设典故可展开阅读,动态延续典故以「持有人记忆」呈现,并把装备来源作为同一阅读层的背景信息。

## Branch

`codex/next-equipment-lore-reader`

## Boundaries

- 文案继续走 `data/lore/` 或集中式 `UiStrings`,不在 presentation 散写中文。
- 不改 lore yaml schema,不改 Isar schema/saveVersion。
- 现有 `Lore` 持久层没有持有人字段,本切片只做兼容展示:把 `Equipment.lores` 中非 preset 的延续典故组织为「持有人记忆」。
- 不改装备数值、掉落、来源反查或战斗事件结算。

## Acceptance

- 装备详情典故区标题升级为「器物志」阅读层。
- 多段 preset 典故显示段序,并默认折叠长段,可逐段展开。
- 来源信息可在典故阅读层内显示,无来源时不渲染来源行。
- 延续典故以「持有人记忆」分组展示,保持按 `addedAt` 升序。
- targeted widget tests 覆盖多段展开、来源行、持有人记忆兼容展示。
- `flutter analyze` 通过。

## Slices

- [x] 读现有 lore loader / equipment detail / tests。
- [x] 写本计划文件。
- [x] 局部重构 `_LoreSection`,加入来源参数、段落卡片、展开交互。
- [x] 补充/更新 `equipment_detail_screen_lore_section_test.dart`。
- [x] 跑 targeted tests 与 `flutter analyze`。
- [x] 更新恢复点并提交。

## Current Recovery Point

- 状态:实现与验证完成,待提交。
- 最后完成:装备详情典故区升级为「器物志」阅读层;来源并入阅读层;预设典故按「旧闻 N」可展开;动态延续典故以「持有人记忆」分组兼容展示。
- 下一步:提交 `codex/next-equipment-lore-reader`。
- 已跑验证:`flutter test --no-pub -j1 test/features/inventory/presentation/equipment_detail_screen_lore_section_test.dart test/features/inventory/presentation/equipment_detail_screen_test.dart`(24/24 passed);`flutter analyze`(No issues found)。
- 阻塞项:CodeGraph 未初始化,本任务用 `rg` 定向读文件继续。
