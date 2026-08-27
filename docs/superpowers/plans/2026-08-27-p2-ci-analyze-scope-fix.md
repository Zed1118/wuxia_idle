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

1. 实现 commit：待填。
2. 两向破坏证红：待填。
3. targeted：待填。
4. analyze：待填。
5. format：待填。
6. 带锁全量：待填。
7. diff/patch：待填。
8. 外置 receipt + `[READY]` tip：待填。

## 当前恢复点

- 状态：WIP；workflow exact scope、直接合同与计划已落地但未提交。
- 下一步：开发期 targeted 通过后提交，再按八步完成 mutation 与正式门禁。
- 阻塞项：无；未碰 `tools/`、exclude、`analysis_options.yaml` 或 `lib/`。
