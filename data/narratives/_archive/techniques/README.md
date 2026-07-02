# 归档：武学领悟文案（2026-07-03 · batch-123）

本目录 66 篇文案（直下 `*.yaml` 26 篇拼音命名 + `insights/` 40 篇）于 2026-07-03
从 `data/narratives/techniques/` 归档至此。

## 归档原因：无加载管线的孤儿文案

Phase 0 复核（batch-123）确认为真孤儿：

- `NarrativeLoader._scanPaths` 不含 `techniques/`（仅扫 `narratives/` + `stages/` +
  `ascension/` + `chapters/`），26 篇拼音命名文案无 loader 读取。
- `skill_def.narrativeInsightId` 字段仅在 `skill_def.dart:44/128` 定义+解析，
  `lib/` **零消费**（无 loader 用它去读 `insights/<id>.yaml`），40 篇 insight 文案无加载。

处置＝移 `_archive`（用户 2026-07-03 拍板），保留内容、移出 asset 打包。
pubspec 原 `data/narratives/techniques/` + `.../insights/` 两行声明已删。
路径含 `_archive` 段，`pubspec_asset_declaration_test` 守卫自动豁免。

## Phase 5 武学领悟 UI 接线时迁回指引

1. `git mv data/narratives/_archive/techniques data/narratives/techniques`
2. `pubspec.yaml` assets 段补回 `data/narratives/techniques/` +
   `data/narratives/techniques/insights/` 两行声明
3. 实装 loader：encounter skill 的 `narrativeInsightId` → 读 `insights/<id>.yaml`
4. `encounter_skills_yaml_test` 的 `knownInsights` 硬编码白名单（36 项）只校验字段
   值自洽、不依赖文件物理位置，迁回不影响该测试。
