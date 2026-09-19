# 链 → main 合并预检恢复点（派单包 A）

- 目标：在 `codex/p2-player-flow-20260910` 当前 tip 上实测一份 §8.2 合并 Gate 证据单，供用户拍板是否把链快进合并进 `main`。合并动作不在本单。
- 分支：`qoder/a-merge-precheck-20260919`（worktree `/Users/a10506/Qoder/2026-09-19/a-merge-precheck/wt`）。
- 派单基线：`base_sha = 5d9bbdeafbc93361a6f0fa64d7a500c6e6b86b92`；对照 `origin/main = 342d1927529b8306582431be597ef1975bd69deb`。
- 开始时间：2026-09-19 17:09:30 +08:00。
- 写入范围：仅三个白名单路径（本恢复点、`docs/audit/chain_merge_precheck_2026-09-19.md`、`docs/dispatch/reports/2026-09-19_qoder_A_receipt.yaml`）。本单零修复：发现问题只登记。
- 验收：CI 同套命令逐条留命令原文 / 退出码 / 末 3 行 / 墙钟起止；Gate ⓐ–ⓔ 逐项给命中数与 file:line 清单；差异面摘要含红线层文件 commit 列表与 saveVersion 判定；结论只用三种确定口径之一；不 push / merge / rebase / revert；不装软件；不碰真实存档；不 `flutter run`。

## 当前恢复点

- 状态：目标 1–4 的实测与证据单写盘均完成；待提交实质 commit S 与收据包装 commit R。
- 最后完成：CI 同套 7 步全绿 —— pub get / build_runner / format / analyze / 全量测试 `09:14 +6976: All tests passed!` 退出 0、`^\[E\]` 计数 0 / macOS debug build / 覆盖率 `flutter test --no-pub --coverage` 退出 0（`16:46 +6976`）+ `dart run tool/coverage_ratchet.dart` 退出 0 输出 `Line coverage: 50827/58422 (87.00%), minimum=81.25%`。Gate ⓐ–ⓔ 与差异面摘要全部实测取数，结论定为「可合并但需知悉（列条目）」共 6 条知悉项。
- 下一步：提交实质 commit S（证据单 + 本恢复点，消息带 `[READY]`）→ 计算 `git diff --check` 与 patch SHA-256 → 写收据 → 独立包装 commit R 只含收据（`R^ == S`，消息同带 `[READY]`）。
- 已跑验证：见 `docs/audit/chain_merge_precheck_2026-09-19.md` 目标 1 / 目标 2 / 目标 3 三张表，每行都带命令原文、退出码与墙钟起止。
- 阻塞项：无。全量测试一次通过、无非 flaky 失败，故不触发 `[BLOCKED]` 出口；未安装任何软件；CI 另有两项 macOS 原生 shell 测试本单未执行，已在证据单结论第 6 条记为「未能判定 + 原因」。

## 关键实测事实（防漂移锚点）

- `origin/main` 是 HEAD 的祖先（`git merge-base --is-ancestor` 退出 0），`git rev-list --count HEAD..origin/main` = 0 → 纯快进，无分叉。
- `git merge-tree --write-tree origin/main HEAD` 退出 0，输出树 `99de5147efc8e9883c99c75a70809379fc4cb79b` → 无冲突。
- 范围 101 commit / 336 文件 / +82565 −4550；提交日期跨 2026-09-12 至 2026-09-18。
- `_currentSaveVersion`：`origin/main` = `0.49.0`，HEAD = `0.50.0`（`lib/data/isar_setup.dart:252`），迁移段 `if (_compareVersion(fromVersion, '0.50.0') < 0)` 存在（同文件 `:700`）。
- 环境：Flutter 3.41.5 / Dart 3.11.3（stable，与 `.github/workflows/ci.yml` 钉死版本一致）。

## 收据口径备忘

- 本单 `changed_files` 只有 docs，属审计单：`break_red` 留空，必须有且仅有一个 `audit_verification`（`git diff --check` 退出码 + patch SHA-256）。
- 三条 last_line 一律填真实输出，不得写 `NOT_RUN`（本单实跑了 full test / analyze / format）。
- `analyze_last_line` 取 Gate 口径命令 `flutter analyze --no-pub lib test` 的末行；`format_last_line` 取 Gate 口径 `dart format --output=none --set-exit-if-changed .` 的末行；CI 口径（`lib test tool` / `lib test docs`）另在证据单目标 1 表中留档。
- `head_sha` 写实质 commit S，不写包装 commit R。
