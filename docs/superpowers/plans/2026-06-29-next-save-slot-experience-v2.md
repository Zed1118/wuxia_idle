# 多存档体验二期计划

## 目标

让多存档从“技术可切槽”升级为玩家可辨认、可安心操作的入口：显示存档名称、进度摘要、最近游玩标识，并降低误删风险。

## 分支

`codex/next-save-slot-experience-v2`

## 风险与迁移方案

- 优先使用既有字段派生，不新增 Isar schema，不 bump `saveVersion`。
- `SaveData.slotName` 已存在，可直接作为玩家自定义存档名；空值时回退到“第 N 卷”。
- 进度摘要从 `SaveData`、祖师 `Character`、`MainlineProgress`、`TowerProgress` 派生。
- 最近游玩从各槽 `SaveData.lastOnlineAt` 横向比较派生，只做选择屏展示。
- 删除保护先做交互层：删除前必须输入当前显示的存档名/卷名；不新增持久化锁定字段。
- 若后续需要“永久锁定不可删”语义，再另开 schema 方案：`SaveData.deleteProtected bool`，旧档默认 `false`，迁移只回填默认值。本切片不采用该方案。

## 验收标准

- 存档选择屏有档槽显示名称、祖师、境界、主线进度、最近游玩时间。
- 最近游玩的非空槽显示明确标识。
- 有档槽可重命名，重命名写入既有 `SaveData.slotName`。
- 删除前必须输入当前显示名才启用确认按钮。
- 空槽仍可新开江湖，旧有切槽/删槽生命周期不回退。
- targeted tests 与 `flutter analyze` 通过。

## 任务切片

- [x] 扩展 `SlotSummary` 与 `IsarSetup.listSlots` 派生显示名、最近标识、塔进度。
- [x] 增加 `IsarSetup.renameSlot`，复用既有 `SaveData.slotName`。
- [x] 重做存档选择卡片 UI：摘要、最近标识、重命名入口、删除保护确认。
- [x] 补充/更新 targeted tests。
- [x] 跑 targeted tests 与 `flutter analyze`。
- [x] 更新恢复点并提交。

## 当前恢复点

- 状态：完成，已提交。
- 最后完成：`SlotSummary`/`IsarSetup`/`SaveSelectScreen`/`UiStrings` 与 targeted tests 已更新；无 schema/saveVersion 改动。
- 下一步：等待主窗口复核/合并；本分支不 push。
- 已跑验证：`flutter test --no-pub -j1 test/data/isar_setup_slots_test.dart test/features/save_slot/save_select_screen_test.dart` 11/11 passed；`flutter analyze` 0 issue。
- 阻塞项：无。
