# P2 批三 B3 Windows Analyze 口径修复计划

## 目标与边界

- 目标：只把 `.github/workflows/windows-release.yml` 的 Analyze 命令从裸 `flutter analyze --no-pub` 收窄为与主 CI 一致的 `flutter analyze --no-pub lib test tool`。
- 分支：`codex/p2-ci-analyze-scope-fix-20260827`；基线：B2 `[READY]` tip `2d690d60f250460b6e63254eef0e7fb6bbf1d855`。
- 事实基线：冻结派单记录裸 Analyze 的 1943 issues / exit 1 全来自归档 `tools/phase0minus_probe`；主 CI 已使用 `lib test tool` 口径。
- 只修改该 workflow 的 Analyze 命令、直接相关的既有 CI 合同测试与本计划；不改 `tools/`、exclude、`analysis_options.yaml`、任何 `lib/`、UI 文案、数值、schema、存档语义，不 push/merge/main/revert。
- 直接相关测试只追加 Windows exact-scope 与 bare-command 否定断言；不删除任何 `test/` 原行，`test_deletions` 明示例外为 0。

## 固定八步验收

1. 实现 workflow scope 与 CI 合同并 commit（中文动宾）。
2. commit 后按序两向破坏证红并精确反向补丁恢复：
   - `remove_implementation`：临时把 Windows Analyze 恢复为裸 `flutter analyze --no-pub`；`ci_workflow_contract_test.dart` 必须红。
   - `force_degenerate_value`：临时把作用域退化为错误复数目录 `lib test tools`；同一 targeted 必须红。
3. targeted：`flutter test --no-pub test/tools/ci_workflow_contract_test.dart`。
4. `flutter analyze --no-pub lib test`。
5. `dart format --output=none --set-exit-if-changed .`。
6. 独占 `/Users/a10506/.claude/locks/wuxia_full_test.lock` 跑一次 `flutter test --no-pub`，读取 reporter 末行和 `[E]` 计数并精确删除锁。
7. `git diff --check 2d690d60f250460b6e63254eef0e7fb6bbf1d855..HEAD` 与固定 patch SHA-256。
8. plan 证据 commit 后创建空 `[READY]` 最终 tip；生成不提交的 `build/phase2_wiring_receipts/B3/receipt.yaml`，head/patch 对最终 tip；S5 由 Claude 独立复核。

## 收工记录

1. 实现 commit：`474bbad658db2f0559c243aa227912a8ed2fb950 收窄发布分析目录口径`；精确合同补强 commit：`30b1b10128dcc31b861a78eeee16649037e9e72f 强化发布分析精确合同`。
2. 两向破坏证红：
   - 首轮在 `474bbad6` 后，`remove_implementation`（scope 恢复为裸命令）→ exit 1，末行 `00:00 +3 -1: Some tests failed.`，`[E]` 1，失败 1；但首次 `force_degenerate_value`（`tool` → `tools`）→ exit 0，末行 `00:00 +4: All tests passed!`，`[E]` 0，失败 0。原因是 `contains(... tool)` 把 `tools` 前缀误判为命中；该次不作为证红通过，完整保留为发现的测试漏洞。
   - 修复：追加按整行锚定且要求恰好一次命中的 RegExp 合同，提交 `30b1b101`；没有改 workflow、`tools/`、exclude、analysis options 或产品代码。
   - 从新 commit 重新开始完整两向流程。最终 `remove_implementation`：scope 精确恢复为裸命令，运行 `flutter test --no-pub test/tools/ci_workflow_contract_test.dart` → exit 1，末行 `00:00 +3 -1: Some tests failed.`，`[E]` 1，失败 1。精确反向补丁恢复后 `git diff --quiet` exit 0，HEAD `30b1b10128dcc31b861a78eeee16649037e9e72f`。
   - 最终 `force_degenerate_value`：scope 精确退化为 `lib test tools`，运行同一 targeted → exit 1，末行 `00:00 +3 -1: Some tests failed.`，`[E]` 1，失败 1。精确反向补丁恢复后 `git diff --quiet` exit 0，HEAD 不变。
3. targeted：`flutter test --no-pub test/tools/ci_workflow_contract_test.dart` → exit 0，末行 `00:00 +4: All tests passed!`，`[E]` 0，失败 0。
4. analyze：`flutter analyze --no-pub lib test` → exit 0，末行 `No issues found! (ran in 2.1s)`。
5. format：`dart format --output=none --set-exit-if-changed .` → exit 0，末行 `Formatted 1625 files (0 changed) in 2.75 seconds.`。
6. 带锁全量：独占 `/Users/a10506/.claude/locks/wuxia_full_test.lock`；`flutter test --no-pub` → exit 0，末行 `05:15 +5634: All tests passed!`，`[E]` 0，失败 0；命令退出时精确 `unlink` 并确认锁不存在。
7. diff/patch：`git diff --check 2d690d60f250460b6e63254eef0e7fb6bbf1d855..HEAD` → exit 0；最终 `[READY]` tip 的固定 patch SHA-256 写入外置 receipt。
8. 外置 receipt + `[READY]` tip：本记录提交后创建空 `[READY]` 最终 tip，再生成不提交的 `build/phase2_wiring_receipts/B3/receipt.yaml`；receipt 的 head/changed_files/patch 对最终 tip，S5 由 Claude 独立复核。

## 当前恢复点

- 状态：READY 待证据/状态 commit；workflow exact scope 已提交，首次 mutation 假绿已补强合同并从新 commit 重新完成两向证红；正式 targeted/analyze/整仓 format/带锁全量/diff check 全部通过。
- 下一步：提交本收工记录，创建合规 `[READY]` 最终 tip，并按该 tip 生成 B3 外置 receipt。
- 阻塞项：无；未碰 `tools/`、exclude、`analysis_options.yaml` 或 `lib/`。

## 总控 tip 结构纠偏（2026-08-28）

- 原 `[READY]` `be670476d807cea7fc5be6cabd7289659241c238` 是证据 commit 之后的
  空提交，与后续冻结的“plan 证据 commit 本身即最终 tip”不一致。
- 按纠偏禁止 reset/revert 的要求，不改写旧历史；本节所在非空
  `[READY]` commit 作为新的最终 tip，外置 receipt 按新 tip 重算。
- B3 实现在当时的 B2 交付 tip `2d690d60f250460b6e63254eef0e7fb6bbf1d855`
  上串行建立。B2 后续追加合规证据 tip 不反向改写 B3 已有祖先；
  本记录如实披露，不 merge/rebase。
- 实现、最终两向破坏证红和首次退化假绿的原始命令/末行/失败数
  保持上文原样；新 tip 只增加本条合规证据，`lib/` 仍零改动。
- 新 tip 重跑 targeted、analyze、整仓 format、带锁全量、diff/patch 审计；
  实测末行和新 receipt SHA 以本节之后的外置 receipt 为准。
