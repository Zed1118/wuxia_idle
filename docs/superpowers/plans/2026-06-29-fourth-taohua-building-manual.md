# Fourth Tier: Taohua Building Manual Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to execute this plan step by step. Keep the checklist updated as work progresses.

**Goal:** 给桃花岛选中建筑补轻量「建筑志」说明层,汇总产什么、消耗什么、受哪些协同影响、产物去哪里用,但不改变生产、升级、配方、收益或离线结算。

**Architecture:** 手册作为 `TaohuaIslandScreen` 选中建筑卡的只读 UI 块,直接读取 `TaohuaIslandConfig.buildings`、`RecipeDef`、`synergies.rulesForTarget` 和 `ItemUsageLookupService`。不新增 provider、不新增存档字段、不改 `IslandSettleService` / `IslandProductionService` / `IslandActionService`。

**Tech Stack:** Flutter Desktop, Riverpod override widget tests, existing Wuxia UI.

## CLAUDE.md §8.2 Checklist

- [x] 开工前读取 `docs/spec/rejected_task_registry.md`。
- [x] 确认未重复已否任务:不是“桃花岛生产队列可读化”、不是“开锋辅材定向用途”、不是新增消费入口。
- [x] 独立分支 / worktree:`codex/fourth-taohua-building-manual`。
- [x] 小切片实现,保持可恢复。
- [x] Targeted tests 通过。
- [x] `flutter analyze` 通过。
- [x] 提交前说明红线影响。

## Scope

- [x] 在选中建筑卡中加入 `_BuildingManualPanel`。
- [x] source 建筑展示:
  - 采集产物。
  - 升级消耗材料。
  - 该建筑作为协同来源影响哪些加工建筑。
  - 产物去向。
- [x] processor 建筑展示:
  - 配方产物列表。
  - 主/次原料消耗。
  - 受哪些 source 建筑协同影响。
  - 产物去向。
- [x] `UiStrings` 集中文案,widget 不散写中文。

## Tests

- [x] `taohua_island_screen_test.dart`:默认 source 建筑显示建筑志、采集产物、协同影响和产物去向。
- [x] `taohua_island_screen_test.dart`:选择 processor 建筑后显示配方产物、原料消耗、协同来源。

## Verification

- [x] `flutter test test/features/taohua_island/taohua_island_screen_test.dart test/features/inventory/item_usage_lookup_service_test.dart`
- [x] `flutter analyze`

## Red Lines

- 不改产量、配方、升级成本、协同倍率、收益或离线=在线结算。
- 不新增消费按钮、跳转、自动用药或材料替代路径。
- 不把说明层做成任务/催促/每日压力。
