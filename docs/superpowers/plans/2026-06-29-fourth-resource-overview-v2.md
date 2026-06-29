# Fourth Tier: Resource Overview V2 Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to execute this plan step by step. Keep the checklist updated as work progresses.

**Goal:** 升级现有资源总览页,在只读库存面板中补充用途分组、近期消耗方向、主要来源折叠说明,让玩家能判断资源去向,但不在此处消费、购买、跳转或改变结算。

**Architecture:** 在 `ResourceOverviewService` 中基于既有 `ItemUsageLookupService` / `MaterialSourceLookupService` 派生展示字段,UI 只读取 `ResourceOverviewItem`。不新增存档字段、不新增 schema、不触碰掉落/产出/消耗逻辑。

**Tech Stack:** Flutter Desktop, Riverpod, existing Wuxia UI, focused service/widget tests.

## CLAUDE.md §8.2 Checklist

- [x] 开工前读取 `docs/spec/rejected_task_registry.md`。
- [x] 确认未重复已否任务:本任务不是“材料来源反查 / 武学残页来源聚合 / 消费入口新增”。
- [x] 独立分支 / worktree:`codex/fourth-resource-overview-v2`。
- [x] 小切片实现,保持可恢复。
- [x] Targeted tests 通过。
- [x] `flutter analyze` 通过。
- [x] 提交前说明红线影响。

## Scope

- [x] `ResourceOverviewItem` 增加只读展示派生:
  - 用途分组标签,例如修炼、炼器、桃花岛、疗伤、采买。
  - 近期消耗方向文案,从用途组派生,不追踪个人缺口。
  - 来源详情标签列表,由现有来源枚举去重生成。
- [x] `ResourceOverviewService` 负责派生字段,保持 UI 无业务判断。
- [x] `ResourceOverviewScreen` 展示:
  - 库存数量下方的近期去向。
  - 用途分组 tag。
  - 来源摘要仍保留。
  - 非秘籍残卷项显示可展开的来源详情;秘籍残卷只保留摘要,避免落入“武学残页来源聚合”。
- [x] `UiStrings` 集中文案。

## Tests

- [x] `resource_overview_service_test.dart`:验证炼器材料 / 银两 / 丹药等用途分组与近期去向派生。
- [x] `resource_overview_screen_test.dart`:验证 tag、近期去向、来源折叠可见。
- [x] `resource_overview_screen_test.dart`:验证秘籍残卷不显示来源详情展开入口。

## Verification

- [x] `flutter test test/features/resource_overview/resource_overview_service_test.dart test/features/resource_overview/resource_overview_screen_test.dart`
- [x] `flutter analyze`

## Red Lines

- 不新增消费按钮、购买按钮、跳转入口。
- 不改资源库存、掉落概率、来源、收益、离线结算。
- 不做“武学残页来源聚合”;秘籍残卷维持摘要展示。
- 不新增每日/限时/催促/任务式压力。
