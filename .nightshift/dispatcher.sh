#!/bin/bash
# Nightshift dispatcher · 挂机武侠 · 2026-05-17
#
# Sequentially runs 6 atomic Claude tasks, each in its own git worktree.
# Each task: claude --print < prompt → run verify.sh → log status.
# All tasks skippable: true, no blocking chain.
#
# Usage:
#   bash .nightshift/dispatcher.sh            # real run
#   bash .nightshift/dispatcher.sh --dry-run  # show plan, don't run
#
# Recommended launch (defeats macOS sleep + background):
#   caffeinate -dimsu nohup bash .nightshift/dispatcher.sh > /dev/null 2>&1 &

set -uo pipefail

# === Config ===
PROJECT_ROOT="/Users/a10506/Desktop/挂机武侠"
NIGHTSHIFT="$PROJECT_ROOT/.nightshift"
WORKTREE_BASE="/Users/a10506/Desktop"
TASK_TIMEOUT_MIN=50
TASK_BUDGET_USD=5
INTER_TASK_BUFFER_SEC=30
TASKS=(T01 T02 T03 T04 T05 T06)

# === Setup ===
mkdir -p "$NIGHTSHIFT/logs" "$NIGHTSHIFT/status"
DISPATCHER_LOG="$NIGHTSHIFT/logs/dispatcher.log"

log() {
  local ts
  ts=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$ts] $*" | tee -a "$DISPATCHER_LOG"
}

# === Dry-run flag ===
DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

# === Run one task ===
run_task() {
  local task=$1
  local worktree="$WORKTREE_BASE/wuxia-idle-$task"
  local prompt="$NIGHTSHIFT/prompts/$task.md"
  local verify="$NIGHTSHIFT/prompts/$task.verify.sh"
  local task_log="$NIGHTSHIFT/logs/$task.log"
  local status_file="$NIGHTSHIFT/status/$task.status"

  log "=== START $task ==="
  log "  worktree: $worktree"
  log "  prompt:   $prompt"
  log "  verify:   $verify"

  # Init status file (overwrite per task)
  {
    echo "task=$task"
    echo "started=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "status=running"
  } > "$status_file"

  # Pre-checks
  if [ ! -d "$worktree" ]; then
    log "  FAIL: worktree missing → status=skipped"
    echo "status=skipped" >> "$status_file"
    echo "reason=worktree_missing" >> "$status_file"
    return 0
  fi
  if [ ! -f "$prompt" ]; then
    log "  FAIL: prompt missing → status=skipped"
    echo "status=skipped" >> "$status_file"
    echo "reason=prompt_missing" >> "$status_file"
    return 0
  fi

  # Dry-run early exit
  if [ "$DRY_RUN" = "true" ]; then
    log "  DRY RUN: would claude --print < $prompt in $worktree"
    echo "status=dry_run" >> "$status_file"
    return 0
  fi

  # Run claude with timeout + budget (perl alarm = cross-platform timeout)
  log "  Running claude --print (timeout ${TASK_TIMEOUT_MIN}m, budget \$${TASK_BUDGET_USD})"
  (
    cd "$worktree" || exit 99
    perl -e 'alarm shift; exec @ARGV' "$((TASK_TIMEOUT_MIN * 60))" \
      claude \
        --print \
        --model sonnet \
        --permission-mode bypassPermissions \
        --max-budget-usd "$TASK_BUDGET_USD" \
        --no-session-persistence \
        --add-dir "$worktree" \
      < "$prompt" \
      >> "$task_log" 2>&1
  )
  local claude_exit=$?
  log "  claude exit=$claude_exit"
  echo "claude_exit=$claude_exit" >> "$status_file"

  # Run verify.sh (in worktree)
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

  # Final status (all tasks skippable: true — failure → skipped, not failed)
  if [ "$claude_exit" -eq 0 ] && [ "$verify_exit" -eq 0 ]; then
    echo "status=completed" >> "$status_file"
    log "  === $task: COMPLETED ==="
  else
    echo "status=skipped" >> "$status_file"
    echo "reason=claude_exit_${claude_exit}_verify_exit_${verify_exit}" >> "$status_file"
    log "  === $task: SKIPPED (claude=$claude_exit verify=$verify_exit) ==="
  fi
  echo "finished=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$status_file"

  # Inter-task buffer
  if [ "$task" != "${TASKS[-1]}" ]; then
    log "  Sleeping ${INTER_TASK_BUFFER_SEC}s before next task"
    sleep "$INTER_TASK_BUFFER_SEC"
  fi
}

# === Main ===
log "=========================================="
log "Nightshift dispatcher start: $(date)"
log "Project: $PROJECT_ROOT"
log "Tasks: ${TASKS[*]}"
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
