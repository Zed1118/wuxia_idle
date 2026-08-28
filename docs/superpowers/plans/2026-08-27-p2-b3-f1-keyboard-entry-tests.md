# P2 批三 F1 键盘入口测试计划

## 目标

仅补强 Phase 0A 真实战斗屏的 `E` / `F` / `Z` 键盘入口守卫，不改生产行为。

## 分支

`codex/p2-b3-f1-keyboard-entry-tests-20260827`，基线 `37e5379293a5e551c2c8effc38de5d967fa8f3e9`。

## 验收标准

- 三条 `testWidgets` 均向真实 `Phase0aBattleScreen` 发送 `LogicalKeyboardKey.keyE/keyF/keyZ`。
- 分别验证 `shield/parry/dodge` 的 `Phase0aDefenseStarted`、权威 state/result 与对应可见反馈。
- 临时吞掉三键入口时新测试必须变红，实验后完整恢复。
- 新增测试、相关 Phase 0A presentation 测试、`flutter analyze --no-pub lib test`、`git diff --check` 通过。
- 不修改禁区文件，tip 以 `[READY]` 开头且工作树干净。

## 当前恢复点

- 状态：完成，待主会话独立核验。
- 已完成：新增三条真实 screen 键盘入口测试；临时吞键时 `+0 -3` 破坏证红，反向补丁恢复后生产文件零 diff。
- 已跑验证：新增文件 `+3`；Phase 0A presentation 目录 `+156`；`flutter analyze --no-pub lib test` 零问题；格式与 `git diff --check` 通过。
- 下一步：提交 `[READY]` tip 后等待独立核验，不 merge/push。
- 阻塞项：无。
