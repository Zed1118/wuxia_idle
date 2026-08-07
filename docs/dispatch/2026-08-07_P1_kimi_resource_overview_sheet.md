# 池单 P1 · 资源总览折叠区接 MaterialSourceSheet(kimi·2026-08-07)

## 背景与基线
- 仓库:/Users/a10506/Desktop/Projects/挂机武侠;工作树(已建+即将预热):`.claude/worktrees/kimi-p1-overview`,分支 `kimi/p1-resource-overview`
- 出处:2026-06-30 审计「可直接推进的小项:资源总览折叠区复用既有 MaterialSourceSheet,只补入口,不重做材料来源模型」;实测 `lib/features/resource_overview/` 现零引用该 sheet
- 必读:项目 CLAUDE.md §9.1

## 任务
1. Phase 0:读 `lib/features/resource_overview/` 现状(折叠区结构)+ `lib/features/inventory/presentation/material_source_sheet.dart` 签名 + 既有 5 个消费点任选 2 个作接线体例参考(grep MaterialSourceSheet)
2. 实装:资源总览折叠区的材料条目点击 → 弹既有 `MaterialSourceSheet`(只补入口,零新模型/零 sheet 本体改动)
3. 测试:新增 widget 测(入口存在+点击弹 sheet);破坏证红一轮(移除入口接线 → 测必红 → 还原复绿,记录输出)

## 验收四证据
全项目 `flutter analyze --no-pub` 0(贴输出)/ targeted 逐文件绿(resource_overview 既有测+新增测)/ 破坏证红记录 / commit `[READY] P1 资源总览接 MaterialSourceSheet`,报告 REPORT_P1.md 落 worktree 根

## 禁区
material_source_sheet.dart 本体/其他 5 个消费方/numbers.yaml/strings.dart 不动;写完 dart 必 `dart format`;拿不准 [BLOCKED]。
