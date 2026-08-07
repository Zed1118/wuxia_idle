# REPORT_P1 · 资源总览折叠区接 MaterialSourceSheet

> 池单 P1(kimi · 2026-08-07)· 分支 `kimi/p1-resource-overview` · worktree `.claude/worktrees/kimi-p1-overview`
> 出处：2026-06-30 审计「可直接推进的小项：资源总览折叠区复用既有 MaterialSourceSheet，只补入口，不重做材料来源模型」(docs/spec/playability_phase2_backlog.md §建议执行顺序#1;docs/audit/direction_candidates_2026-08-07.md E1)

## 改动（2 文件，+90/−8)

- `lib/features/resource_overview/presentation/resource_overview_screen.dart`
  - 资源总览卡片**名称行**包 `InkWell` → `MaterialSourceSheet.show(context, itemId: item.defId, quantity: item.quantity)`
  - 体例照背包 `inventory_screen.dart:1876` 名称行入口（InkWell + borderRadius 3，注释标明「只补入口」)
  - 零新模型、零 sheet 本体改动；`ResourceOverviewItem.defId/quantity` 为既有字段，直接透传
- `test/features/resource_overview/resource_overview_screen_test.dart`
  - 新增 `tapping material name opens MaterialSourceSheet`：断言名称行在 InkWell 内（入口存在）+ 点击后 sheet 弹出（`materialSourceSheetSourcesTitle` 与 `materialSourceSheetOwned(7)` 出现）

## 禁区遵守

- `material_source_sheet.dart` 本体：未动（git diff 零命中）
- 其他 5 个消费方（inventory/equipment_detail/shop/forging_panel/enhance_dialog)：未动
- `numbers.yaml` / `strings.dart`：未动（未新增文案，复用既有 UiStrings)
- dart format 已跑（2 files,1 changed)

## 验收四证据（全会话实测）

### 1. `flutter analyze --no-pub` 全项目 0

```
Analyzing kimi-p1-overview...
No issues found! (ran in 3.0s)
```

### 2. targeted 逐文件全绿（resource_overview 既有测 + 新增测）

- `resource_overview_screen_test.dart`(2 既有 + 1 新增）:`00:00 +3: All tests passed!`
- `resource_overview_service_test.dart`:`00:00 +2: All tests passed!`
- `resource_overview_providers_test.dart`:`00:00 +1: All tests passed!`

### 3. 破坏证红记录

- 破坏：将名称行 `onTap` 断开为 `onTap: null`（移除 MaterialSourceSheet 接线）
- 结果：恰新增测红，其余 2 条既有测仍绿——
  ```
  00:00 +1 -1: tapping material name opens MaterialSourceSheet [E]
  Test failed. See exception logs above.
  00:00 +2 -1: Some tests failed.
  ```
  （红在 `materialSourceSheetSourcesTitle` 断言，test line 169)
- 还原接线后复跑：`00:00 +3: All tests passed!` 复绿

### 4. commit

`[READY] P1 资源总览接 MaterialSourceSheet`（本分支 tip，含本报告）

## 备注

- 折叠区（`_SourceDetails` ExpansionTile）保留不动：既有测钉死其展开行为，本单只补入口不替换。
- sheet 在 Isar/GameRepository 未初始化的轻量测试下防御式渲染空来源/空用途占位，不 crash（本体既有行为，非本单新增）。
