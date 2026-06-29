# 战斗 UI 术语统一整理计划

## 目标

统一「蓄力、破招、真气、御体、相位、重伤」等战斗术语的显示样式和解释入口,不新增教程弹窗,不改战斗公式、不改数值。

## 分支

`codex/next-combat-term-glossary`

## 边界

- 中文文案只进 `UiStrings` / `EnumL10n` / 合法集中层。
- 不改 `numbers.yaml`、schema、saveVersion、战斗结算、敌人配置。
- “玉体”按 backlog 更正为“御体”,本分支不引入“玉体”。
- 解释入口使用现有气泡 / 战前情报 / 战斗帮助按钮,不做教程弹窗。

## 验收标准

- 战斗技能弹层、危险条、战前情报、状态标签、伤势摘要复用同一术语文案。
- 周目词条说明不重复渲染「御体 · 御体：...」这类双标题。
- targeted tests 通过。
- `flutter analyze` 0 issue。
- 本分支有小切片 commit。

## 任务切片

- [x] 读取启动文档并创建分支。
- [x] 定位术语显示与解释入口。
- [x] 建立集中术语 API。
- [x] 接入战斗 UI / 战前情报 / 伤势入口。
- [x] 补 targeted tests。
- [x] 跑 targeted tests 与 `flutter analyze`。
- [x] 更新恢复点并提交。

## 当前恢复点

- 状态:完成,已提交 `10ba2f55`。
- 最后完成:新增 `CombatTerm` + `UiStrings.combatTermLabel/combatTermGloss`,接入蓄力/破招/真气/御体/相位/重伤相关显示;周目词条详情去掉「御体 · 御体」重复标题;关卡行周目词条 chip 接入 `GlossaryTip`;已提交本分支。
- 下一步:等待主窗口复核/合并,本分支不 push。
- 已跑验证:
  - `dart run build_runner build --delete-conflicting-outputs`（当前 build_runner 提示该参数已忽略,生成成功）
  - `flutter analyze`
  - `flutter test --no-pub -j1 test/features/battle/cycle_trait_intel_test.dart test/features/loot_preview/stage_intel_dialog_test.dart test/features/battle/presentation/battle_skill_info_popup_test.dart test/features/battle/presentation/avatar_status_tags_test.dart test/features/injury/presentation/injury_status_view_test.dart test/features/battle/boss_phase_presentation_test.dart`
- 阻塞项:无。
