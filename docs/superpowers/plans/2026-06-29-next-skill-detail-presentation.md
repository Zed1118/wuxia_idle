# 技能详情页表现层升级计划

## 目标

在现有武学图鉴 / 藏经阁技能详情入口中，为每个招式详情补齐统一的“秘籍式”展示版式：流派、破招属性、熟练收益、典型用途。仅做表现层，不改技能数值、不改熟练度公式。

## 分支

`codex/next-skill-detail-presentation`

## 边界

- 复用 `SkillProficiencyFormatter`、`UiStrings`、现有武学图鉴详情入口。
- 不改 `data/skills.yaml`、`numbers.yaml`、熟练度公式、战斗结算。
- 不新增存档字段、不改 Isar schema / saveVersion。
- Dart 中文 UI 文案集中进 `UiStrings` / `EnumL10n` 合法 sink，不在 presentation 散写。

## 验收标准

- 技能详情页呈现统一信息组：流派、破招、熟练收益、典型用途。
- 心法自带招若没有独立 `style`，能从所属心法推导流派；独立招式使用自身 `style`。
- 熟练收益复用 `SkillProficiencyFormatter` 的当前/下阶收益文本。
- 典型用途由现有字段派生，不引入新数值或新配置。
- Targeted widget / formatter tests 通过，`flutter analyze` 通过。

## 任务切片

- [x] 启动文档读取与分支创建。
- [x] 摸排现有技能详情、熟练度 formatter、字符串层和测试入口。
- [x] 新增技能详情展示模型 / UI 小组件与 `UiStrings` 文案。
- [x] 补 targeted widget / formatter 测试。
- [x] 跑 targeted tests 与 `flutter analyze`。
- [x] 更新恢复点并提交本分支。

## 当前恢复点

- 状态：实现与验证已完成，提交本分支。
- 最后完成：技能详情页新增“秘本纲要”四项版式，集中字符串已补，widget 覆盖已补。
- 下一步：交由主窗口复核 / 合并。
- 已跑验证：`flutter test test/features/baike/presentation/skill_codex_detail_screen_test.dart test/features/cultivation/skill_proficiency_formatter_test.dart`；`flutter analyze`。
- 阻塞项：CodeGraph 未初始化，本切片改用 `rg` 与源码阅读定位。
