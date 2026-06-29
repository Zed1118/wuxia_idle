# 藏卷阁与奇遇札记视觉二期计划

## 目标

升级藏卷阁机制/背景列表与奇遇录记录卡片的视觉呈现,让机制百科更像书架/卷宗/器物谱,让已触发奇遇更像江湖札记。仅做 presentation 层视觉结构,不改奇遇记录数据、解锁规则、存档、事件或 provider 业务逻辑。

## 分支

`codex/visual-codex-encounter-cards`

## 边界

- 不触碰 main 或其他 worktree,不 revert 非本任务改动。
- 已否项不做:不新增「江湖见闻录收藏百科」、奇遇后续回访、后续事件、选择代价可见、触发条件泄露。
- 未触发奇遇仍只显示剪影/未际遇,不展示标题、条件、来源或代价。
- codex locked/unlocked 状态保留,不新增数据源。
- 中文 UI 文案集中放 `UiStrings`。

## 验收标准

- 生产接线证据:`BaikeScreen` 的 `CodexTab` / `EncounterTab` 真实入口渲染新列表与札记卡,非 demo/fixture。
- 藏卷阁机制与背景条目形成统一的书架/卷宗/器物谱视觉结构,保留点击详情与 locked 灰显。
- 奇遇录已触发记录分层展示标题、组别与状态;未触发记录仍显示剪影/未际遇且点击只提示未际遇。
- 红线影响:不改数值、三系锁死、在线离线、反主流系统;不新增收藏/回访/条件提示;不在 presentation 散写中文。
- targeted tests 覆盖 codex locked/unlocked 与奇遇札记/剪影契约。
- 跑 `dart run build_runner build --delete-conflicting-outputs`、相关 baike/codex tests、`flutter analyze`、`git diff --check`。

## 任务切片

- [x] 读取 `AGENTS.md`、`CLAUDE.md`、`docs/spec/rejected_task_registry.md`。
- [x] 定位 `CodexTab` / `EncounterTab` / `UiStrings` / 相关 widget tests。
- [x] 写本计划文件。
- [x] 改造藏卷阁列表视觉。
- [x] 改造奇遇录札记卡片视觉。
- [x] 补充必要 widget 断言。
- [x] 跑生成、测试、analyze、diff check。
- [x] 更新恢复点并提交。

## 当前恢复点

- 状态:完成,已提交实现 commit `da76ff32`,当前 tip 为 `[READY]` 交付标记。
- 最后完成:`CodexTab` 改成机制卷宗/江湖背景分段卡片;`EncounterTab` 改成江湖札记卡,已触发显示标题/组别/状态,未触发仍只显示剪影与未际遇。
- 下一步:等待主窗口复核/合并。
- 已跑验证:
  - `dart run build_runner build --delete-conflicting-outputs`(成功;当前 build_runner 提示该参数已忽略;无生成文件 diff)。
  - `flutter test --no-pub -j1 test/features/baike test/features/codex`(91/91 passed,含 1280×720 / 1440×900 widget smoke)。
  - `flutter analyze`(No issues found)。
  - `git diff --check`(通过)。
- 阻塞项:无。
