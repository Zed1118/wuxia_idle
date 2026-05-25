#!/bin/bash
# Nightshift dispatcher · 通用模板 v2(2026-05-24)
#
# 从 wuxia_idle/.nightshift/dispatcher.sh 抽通用版本:
#   - PROJECT_ROOT / WORKTREE_BASE / TASKS / 模型 / 预算 等抽到 nightshift.conf
#   - 新增 prerun hook(项目类型特化,如 Flutter build_runner)
#   - 新增 morning.sh 自动调用(dispatcher 收尾时跑)
#   - 状态码细分: completed / skipped / fail_scope(verify exit=30) / fail_verify / fail_timeout
#
# 用法:
#   bash .nightshift/dispatcher.sh            # real run
#   bash .nightshift/dispatcher.sh --dry-run  # show plan, don't run
#
# 推荐启动: bash .nightshift/launch.sh

set -uo pipefail

# === Load config(必须先读) ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/nightshift.conf"
if [ ! -f "$CONF" ]; then
  echo "FATAL: $CONF not found. Run nightshift-init.sh first." >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$CONF"

# === 必需变量校验 ===
: "${PROJECT_ROOT:?nightshift.conf 缺 PROJECT_ROOT}"
: "${PROJECT_TYPE:?nightshift.conf 缺 PROJECT_TYPE(flutter|node|generic)}"
: "${WORKTREE_BASE:?nightshift.conf 缺 WORKTREE_BASE}"
: "${TASKS:?nightshift.conf 缺 TASKS}"
: "${MAIN_BRANCH:=main}"
: "${TASK_TIMEOUT_MIN:=75}"
: "${TASK_BUDGET_USD:=8}"
: "${INTER_TASK_BUFFER_SEC:=30}"
: "${CLAUDE_MODEL:=opus}"
: "${CLAUDE_PERMISSION_MODE:=bypassPermissions}"
: "${WORKTREE_PREFIX:=$(basename "$PROJECT_ROOT")}"

# === A8 sanity: BUDGET 与 TIMEOUT 联动校验 ===
# memory feedback-nightshift-v2-first-run-lessons A8
# opus --print 实测 ~$0.1/min,TIMEOUT 升而 BUDGET 不升 → 大 spec 被 budget 截断
SANITY_MIN_BUDGET=$(( TASK_TIMEOUT_MIN / 10 ))
if [ "$TASK_BUDGET_USD" -lt "$SANITY_MIN_BUDGET" ]; then
  echo "FATAL: TASK_BUDGET_USD=\$$TASK_BUDGET_USD 不满足 sanity TIMEOUT/10=\$$SANITY_MIN_BUDGET" >&2
  echo "  TIMEOUT=${TASK_TIMEOUT_MIN}min × \$0.1/min ≈ \$$SANITY_MIN_BUDGET 起跳(opus --print 锚点)" >&2
  echo "  改 nightshift.conf 升 TASK_BUDGET_USD 后重启" >&2
  exit 2
fi

NIGHTSHIFT="$SCRIPT_DIR"
mkdir -p "$NIGHTSHIFT/logs" "$NIGHTSHIFT/status"
DISPATCHER_LOG="$NIGHTSHIFT/logs/dispatcher.log"

# bash 3.2(macOS default)不支持 ${TASKS[-1]},手算 last
LAST_TASK_IDX=$(( ${#TASKS[@]} - 1 ))
LAST_TASK="${TASKS[$LAST_TASK_IDX]}"

# Output token cap(memory feedback_nightshift_max_output_token)
export CLAUDE_CODE_MAX_OUTPUT_TOKENS="${CLAUDE_CODE_MAX_OUTPUT_TOKENS:-64000}"

log() {
  local ts
  ts=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$ts] $*" | tee -a "$DISPATCHER_LOG"
}

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

# === prerun hook(项目类型特化) ===
run_prerun() {
  local worktree="$1"
  local prerun_script="$NIGHTSHIFT/prerun.sh"
  if [ ! -f "$prerun_script" ]; then
    log "  No prerun.sh (skipped)"
    return 0
  fi
  log "  Running prerun.sh (type=$PROJECT_TYPE)"
  (cd "$worktree" && bash "$prerun_script") >> "$DISPATCHER_LOG" 2>&1
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    log "  prerun.sh exit=$rc(warn,不阻塞 task)"
  fi
  return 0
}

# === A11 verify lint(memory A6/A7/A10 同根防扩散) ===
# 拦截 verify.sh 内 grep 验源代码语义(Dart 多行/格式让 grep 假阳/假阴)
# 命中 → fail-fast 不烧 cost · 改 verify_local_tests / verify_analyze_clean(让 analyzer 说话)
# 白名单:test/analyze/run/format/dart 命令、注释行
lint_verify_script() {
  local verify="$1"
  [ ! -f "$verify" ] && return 0
  local hits
  hits=$(grep -nE '\.dart(\b|$)' "$verify" 2>/dev/null \
    | grep -vE '^[[:space:]]*[0-9]+:[[:space:]]*#' \
    | grep -vE 'verify_local_tests|flutter[[:space:]]+test|dart[[:space:]]+(test|run|format|analyze)' \
    || true)
  if [ -n "$hits" ]; then
    log "  LINT FAIL [A11]: verify.sh 内 grep/helper 操作 .dart 源文件"
    log "    memory feedback-nightshift-v2-first-run-lessons A6/A7/A10 同根:Dart 源码语义不能 grep"
    log "    改用 verify_local_tests(跑测) / verify_analyze_clean(让 analyzer 说话)"
    echo "$hits" | sed 's/^/      /' | tee -a "$DISPATCHER_LOG"
    return 1
  fi
  return 0
}

# === Run one task ===
run_task() {
  local task=$1

  # Per-task override(B3,v2 P1):nightshift.conf 可设 TASKS_<task>_BRANCH / TASKS_<task>_WORKTREE
  # 用途:T01 类需切外部已有分支(如 feat/p1_2_spec)跑 task,避开 dispatcher 默认 nightshift/T0X 隔离
  local branch_var="TASKS_${task}_BRANCH"
  local worktree_var="TASKS_${task}_WORKTREE"
  local override_branch="${!branch_var:-}"
  local override_worktree="${!worktree_var:-}"

  local branch="${override_branch:-nightshift/$task}"
  local worktree
  if [ -n "$override_worktree" ]; then
    worktree="$override_worktree"
  else
    worktree="$WORKTREE_BASE/${WORKTREE_PREFIX}-$task"
  fi

  local prompt="$NIGHTSHIFT/prompts/$task.md"
  local verify="$NIGHTSHIFT/prompts/$task.verify.sh"
  local task_log="$NIGHTSHIFT/logs/$task.log"
  local status_file="$NIGHTSHIFT/status/$task.status"

  log "=== START $task ==="
  log "  worktree: $worktree$([ -n "$override_worktree" ] && echo ' (override)')"
  log "  branch:   $branch$([ -n "$override_branch" ] && echo ' (override)')"
  log "  prompt:   $prompt"
  log "  verify:   $verify"

  {
    echo "task=$task"
    echo "started=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "status=running"
  } > "$status_file"

  if [ ! -f "$prompt" ]; then
    log "  FAIL: prompt missing → status=skipped"
    {
      echo "status=skipped"
      echo "reason=prompt_missing"
    } >> "$status_file"
    return 0
  fi

  # A11 verify lint(fail-fast 不烧 cost · memory A6/A7/A10 同根)
  if ! lint_verify_script "$verify"; then
    log "  FAIL: verify lint A11 → status=skipped"
    {
      echo "status=skipped"
      echo "reason=verify_lint_grep_dart_source"
    } >> "$status_file"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log "  DRY RUN: would auto-create worktree $worktree + claude --print < $prompt"
    echo "status=dry_run" >> "$status_file"
    return 0
  fi

  # Auto-create worktree if missing
  # override_branch 走 fetch + 切现有分支(不带 -B,避免覆盖远端分支)
  # 默认 nightshift/$task 走 -B(从 MAIN_BRANCH 起新建 / 复用)
  if [ ! -d "$worktree" ]; then
    if [ -n "$override_branch" ]; then
      log "  Auto-creating worktree $worktree on branch $branch (override,fetch + checkout existing)"
      if ! (cd "$PROJECT_ROOT" && git fetch origin "$branch" && git worktree add -f "$worktree" "$branch") >> "$DISPATCHER_LOG" 2>&1; then
        log "  FAIL: worktree create (override branch $branch) → status=skipped"
        {
          echo "status=skipped"
          echo "reason=worktree_create_failed_override_branch"
        } >> "$status_file"
        return 0
      fi
    else
      log "  Auto-creating worktree $worktree from $MAIN_BRANCH (branch $branch)"
      if ! (cd "$PROJECT_ROOT" && git worktree add -f "$worktree" -B "$branch" "$MAIN_BRANCH") >> "$DISPATCHER_LOG" 2>&1; then
        log "  FAIL: worktree create → status=skipped"
        {
          echo "status=skipped"
          echo "reason=worktree_create_failed"
        } >> "$status_file"
        return 0
      fi
    fi
  fi

  # prerun(项目类型特化,如 build_runner / npm ci)
  run_prerun "$worktree"

  # Idempotency: 若 worktree 已有 commit "nightshift $task",跳 claude 直跑 verify
  local claude_exit=0
  local task_json="$NIGHTSHIFT/logs/$task.json"
  if (cd "$worktree" && git log -1 --pretty=%s 2>/dev/null | grep -q "nightshift $task"); then
    log "  IDEMPOTENT: worktree already has nightshift $task commit, skip claude (verify only)"
    echo "claude_exit=skipped_idempotent" >> "$status_file"
  else
    log "  Running claude --print (model $CLAUDE_MODEL, timeout ${TASK_TIMEOUT_MIN}m, budget \$${TASK_BUDGET_USD})"
    # C2 cost 追踪(memory feedback-nightshift-v2-first-run-lessons C2):
    # --output-format json 把 stdout 写成单 JSON · 拆 .result 到 task_log + .total_cost_usd 到 status
    (
      cd "$worktree" || exit 99
      perl -e 'alarm shift; exec @ARGV' "$((TASK_TIMEOUT_MIN * 60))" \
        claude \
          --print \
          --output-format json \
          --model "$CLAUDE_MODEL" \
          --permission-mode "$CLAUDE_PERMISSION_MODE" \
          --max-budget-usd "$TASK_BUDGET_USD" \
          --no-session-persistence \
          --add-dir "$worktree" \
        < "$prompt" \
        > "$task_json" 2>>"$task_log"
    )
    claude_exit=$?
    log "  claude exit=$claude_exit"
    echo "claude_exit=$claude_exit" >> "$status_file"

    # 拆 JSON 到 task_log + status_file cost_usd
    if [ -s "$task_json" ] && head -c 1 "$task_json" 2>/dev/null | grep -q '{' && command -v jq >/dev/null 2>&1; then
      jq -r '.result // "(no .result field)"' "$task_json" >> "$task_log" 2>/dev/null || cat "$task_json" >> "$task_log"
      local cost
      cost=$(jq -r '.total_cost_usd // .cost_usd // empty' "$task_json" 2>/dev/null)
      if [ -n "$cost" ]; then
        echo "cost_usd=$cost" >> "$status_file"
        log "  cost: \$$cost"
      fi
    else
      # 非 JSON(超时 truncate / jq 缺) → 原样 append
      [ -s "$task_json" ] && cat "$task_json" >> "$task_log"
    fi
  fi

  # Run verify
  local verify_exit=0
  if [ -f "$verify" ]; then
    log "  Running verify"
    (
      cd "$worktree" || exit 99
      bash "$verify"
    ) >> "$task_log" 2>&1
    verify_exit=$?
    log "  verify exit=$verify_exit"
    echo "verify_exit=$verify_exit" >> "$status_file"
  else
    log "  No verify.sh (skipped)"
    echo "verify_exit=no_script" >> "$status_file"
  fi

  # 状态码细分(v2):
  #   verify_exit=30 → fail_scope(verify_path_guard 越界)
  #   claude_exit=142 → fail_timeout(perl alarm SIGALRM)
  #   claude=0 + verify=0 → completed
  #   else → skipped
  local final_status="skipped"
  local reason=""
  # 全用字符串比较,避免 claude_exit="skipped_idempotent" 混入整数比较时 bash 报错
  if [ "$claude_exit" = "skipped_idempotent" ] && [ "$verify_exit" = "0" ]; then
    final_status="completed"
  elif [ "$claude_exit" = "0" ] && [ "$verify_exit" = "0" ]; then
    final_status="completed"
  elif [ "$verify_exit" = "30" ]; then
    final_status="fail_scope"
    reason="path_guard_violation"
  elif [ "$claude_exit" = "142" ] || [ "$claude_exit" = "124" ]; then
    final_status="fail_timeout"
    reason="claude_exit_${claude_exit}"
  elif [ "$verify_exit" != "0" ]; then
    final_status="fail_verify"
    reason="verify_exit_${verify_exit}"
  else
    final_status="skipped"
    reason="claude_exit_${claude_exit}_verify_exit_${verify_exit}"
  fi

  echo "status=$final_status" >> "$status_file"
  [ -n "$reason" ] && echo "reason=$reason" >> "$status_file"
  echo "finished=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$status_file"

  case "$final_status" in
    completed)  log "  === $task: COMPLETED ===" ;;
    fail_scope) log "  === $task: FAIL_SCOPE(越界,不回滚,早晨人工) ===" ;;
    fail_timeout) log "  === $task: FAIL_TIMEOUT(${TASK_TIMEOUT_MIN}m hit) ===" ;;
    fail_verify) log "  === $task: FAIL_VERIFY(claude=$claude_exit verify=$verify_exit) ===" ;;
    *) log "  === $task: SKIPPED ($reason) ===" ;;
  esac

  if [ "$task" != "$LAST_TASK" ]; then
    log "  Sleeping ${INTER_TASK_BUFFER_SEC}s before next task"
    sleep "$INTER_TASK_BUFFER_SEC"
  fi
}

# === Main ===
log "=========================================="
log "Nightshift dispatcher start: $(date)"
log "Project: $PROJECT_ROOT (type=$PROJECT_TYPE)"
log "Tasks: ${TASKS[*]}"
log "Model: $CLAUDE_MODEL · timeout=${TASK_TIMEOUT_MIN}m · budget=\$${TASK_BUDGET_USD}/task"
log "Mode: $([ "$DRY_RUN" = "true" ] && echo "DRY RUN" || echo "REAL")"
log "=========================================="

for task in "${TASKS[@]}"; do
  run_task "$task"
done

log "=========================================="
log "Nightshift dispatcher end: $(date)"
log "Status summary:"
for task in "${TASKS[@]}"; do
  if [ -f "$NIGHTSHIFT/status/$task.status" ]; then
    log "  $task: $(grep '^status=' "$NIGHTSHIFT/status/$task.status" | tail -1)"
  else
    log "  $task: (no status file)"
  fi
done
log "=========================================="

# 自动调 morning.sh 生成 closeout 草稿(v2 新增,失败不影响主流程)
if [ "$DRY_RUN" != "true" ] && [ -f "$NIGHTSHIFT/morning.sh" ]; then
  log "Running morning.sh"
  bash "$NIGHTSHIFT/morning.sh" >> "$DISPATCHER_LOG" 2>&1 || log "morning.sh exit non-zero(忽略)"
fi
