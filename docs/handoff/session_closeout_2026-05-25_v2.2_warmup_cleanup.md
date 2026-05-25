# 会话 closeout · 2026-05-25 v2.2 暖场清理(A11 verify lint + 噪声治理)

> 体量 ≤80 行 · 本会话 ~35min 暖场 · 上批 v2.1 + T23/T24 后的工具收尾
> 范围:`2751326`(本会话 1 commit 推 origin/main)
> 0 analyze · 0 测试回归(无代码改 · 只动 nightshift 工具 + PROGRESS)

## TL;DR

接续上 closeout(`e553d4c`)reality check 全过后做 3+2 暖场:① 清 10 nightshift worktree + 10 分支(T17/T17b/T18/T19/T19b/T20/T21/T22/T23/T24)② dispatcher.sh 加 A11 verify lint(`lint_verify_script` fail-fast 拦 `grep .dart` 源码语义 · A6/A7/A10 同根防扩散)③ PROGRESS 顶段 v2.1 → v2.1+v2.2 + inline 销账。模板源 ~/scripts/nightshift-tpl/ 同步。1 commit `2751326` 推 origin/main。

## 1. 改动一览

| 文件 | 改动 |
|---|---|
| `.nightshift/dispatcher.sh` | +32 行:`lint_verify_script` 函数 + `run_task` 内 prompt 检查后 / claude launch 前 fail-fast 调用 |
| `PROGRESS.md` | 标题加 v2.2 + line 10 末尾 inline v2.2 暖场销账(行数 +0) |
| `~/scripts/nightshift-tpl/dispatcher.tpl.sh` | cp 同步(项目外 · 不在 git) |
| git/worktree | 10 worktree + 10 branch 清(T17/T19 force · retry 已覆盖入 main 验证) |

## 2. A11 拦截器实装细节

**拦截模式**:扫 verify.sh 行内任何 `.dart` 出现(grep -nE `\.dart(\b|$)`)。

**白名单**(grep -vE 排除):
- 注释行(`^[[:space:]]*[0-9]+:[[:space:]]*#`)
- `verify_local_tests` · `flutter test` · `dart test|run|format|analyze`

**触发动作**:命中 → log A11 FAIL + 该行 + memory 指引 → `lint_verify_script` 返 1 → run_task 标 status=skipped + reason=verify_lint_grep_dart_source(不烧 cost)。

**fixture 单元测**(本会话内 /tmp 验证 + 已清):
- 反例:`grep -E "class X" lib/foo.dart` + `verify_grep_safe "lib/foo.dart" ...` → 命中 2 行 exit=1 ✅
- 正例:`verify_local_tests` / `flutter test test/foo_test.dart` / `dart format lib/foo.dart` / `# 注释` → exit=0 ✅

**部署位置**:dispatcher.sh `run_task` 内 `if [ ! -f "$prompt" ]` 之后 / `if [ "$DRY_RUN" ]` 之前 — claude 启动前 fail-fast 节 cost。

## 3. PROGRESS 体量挂账

PROGRESS 当前 101 行(超上限 1)。本批 inline 改动 0 增长 — 上批就已 102。下次顺手 task 时压(候选:line 14-22 三段 2026-05-24 nightshift v2 历史归档,可净减 6-7 行)。

## 4. 不变量沿用

- §5.4 红线 / §5.3 七阶锁 / §5.5 在线=离线 全不动(本批 0 代码改)
- doc 体量 ≤80/50/60/150/100
- nightshift conf TASK_BUDGET_USD=15 / TIMEOUT=120 不动
- **A11 拦截器上线后,新 verify.sh 起草约束**:Dart 源码语义只能用 `verify_local_tests` / `verify_analyze_clean`(让 test/analyzer 说话),不可用 `grep .dart` 字符串验证
- launch 后台任务后默认报「launch 成功」非「task 成功」(memory `feedback_premature_completion_report`)

## 5. memory 影响(无新增,3 条扩展)

- `feedback_nightshift_v2_first_run_lessons` A6/A7/A10:本批 A11 工具层防扩散即闭环,后续 task 若仍写 grep .dart 会被 dispatcher 拦
- 无新 memory 写入(本批是工具补丁,非教训沉淀)

## 6. 下波(用户选)

| # | 候选 | 模型 | 时长 |
|---|---|---|---|
| 1 | P4.1 §12.2 帮派门派实装 Batch 1 schema | xhigh | ~2-3h(首验 A11 拦截器真生产) |
| 4 | P5+ 多代飞升 polish | high | ~1-2h |
| 5 | nightshift Tier 2/3 改进(B2 keep-alive / memory recall) | high/xhigh | ~1-2h / ~3-4h |
| — | PROGRESS 压行(line 14-22 归档) | high | ~10min(顺手) |

**建议**:本会话清理后启 P4.1 Batch 1 — schema-only 体量适中、A11 拦截器急需真生产首验、speed 锚点 ×0.08-0.12 可在新会话 2-3h 内闭环。
