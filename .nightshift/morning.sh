#!/bin/bash
# Nightshift morning · 通用复盘脚本 v2
#
# 输出 closeout 草稿(stdout + SUMMARY.md):
#   - 任务状态概览(completed/fail_*/skipped 计数)
#   - 各 task 状态详情(claude/verify exit + reason)
#   - 失败/越界/超时摘要(grep 关键字 tail)
#   - 各 worktree git diff stat
#   - cherry-pick 建议清单(只列 completed)
#
# 由 dispatcher.sh 收尾自动调用,也可手动:
#   bash .nightshift/morning.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/nightshift.conf"

SUMMARY="$SCRIPT_DIR/SUMMARY.md"
NOW=$(date "+%Y-%m-%d %H:%M:%S")

# 用 tee 同时输出 stdout 和 SUMMARY.md
exec > >(tee "$SUMMARY") 2>&1

cat <<EOF
# Nightshift 战报 · $NOW

> 项目: \`$PROJECT_ROOT\` (type=$PROJECT_TYPE)
> 任务清单: ${TASKS[*]}
> 模型: $CLAUDE_MODEL · timeout=${TASK_TIMEOUT_MIN}m · budget=\$${TASK_BUDGET_USD}/task

## 1. 状态概览

EOF

# 计数
TOTAL=${#TASKS[@]}
COMPLETED=0
FAIL_SCOPE=0
FAIL_VERIFY=0
FAIL_TIMEOUT=0
SKIPPED=0
NO_STATUS=0

for task in "${TASKS[@]}"; do
  sf="$SCRIPT_DIR/status/$task.status"
  if [ ! -f "$sf" ]; then
    NO_STATUS=$((NO_STATUS + 1))
    continue
  fi
  s=$(grep '^status=' "$sf" | tail -1 | cut -d= -f2)
  case "$s" in
    completed) COMPLETED=$((COMPLETED + 1)) ;;
    fail_scope) FAIL_SCOPE=$((FAIL_SCOPE + 1)) ;;
    fail_verify) FAIL_VERIFY=$((FAIL_VERIFY + 1)) ;;
    fail_timeout) FAIL_TIMEOUT=$((FAIL_TIMEOUT + 1)) ;;
    *) SKIPPED=$((SKIPPED + 1)) ;;
  esac
done

cat <<EOF
| 状态 | 计数 |
|---|---|
| 完成 (completed) | $COMPLETED / $TOTAL |
| 越界 (fail_scope) | $FAIL_SCOPE |
| 验证失败 (fail_verify) | $FAIL_VERIFY |
| 超时 (fail_timeout) | $FAIL_TIMEOUT |
| 跳过 (skipped) | $SKIPPED |
| 无状态文件 | $NO_STATUS |

## 2. 各 task 详情

EOF

for task in "${TASKS[@]}"; do
  sf="$SCRIPT_DIR/status/$task.status"
  echo "### $task"
  echo ""
  if [ ! -f "$sf" ]; then
    echo "  (无状态文件,未启动?)"
    echo ""
    continue
  fi
  echo '```'
  cat "$sf"
  echo '```'
  echo ""
done

cat <<EOF

## 3. 失败/越界/超时摘要

EOF

HAS_FAIL=false
for task in "${TASKS[@]}"; do
  log_file="$SCRIPT_DIR/logs/$task.log"
  sf="$SCRIPT_DIR/status/$task.status"
  [ ! -f "$sf" ] && continue
  s=$(grep '^status=' "$sf" | tail -1 | cut -d= -f2)
  case "$s" in
    fail_scope|fail_verify|fail_timeout)
      HAS_FAIL=true
      echo "### $task ($s)"
      echo ""
      echo '```'
      if [ -f "$log_file" ]; then
        # 抓 VERIFY FAIL / 越界 / TIMEOUT / Error 等行,带前后 2 行
        grep -E "VERIFY (FAIL|WARN)|越界|TIMEOUT|FAIL_|Error:|error:" "$log_file" | tail -30 || echo "  (无显式失败行)"
      else
        echo "  (无 log 文件)"
      fi
      echo '```'
      echo ""
      ;;
  esac
done
if [ "$HAS_FAIL" = "false" ]; then
  echo "无失败 task。"
  echo ""
fi

cat <<EOF
## 4. Worktree git diff stat

EOF

for task in "${TASKS[@]}"; do
  wt="$WORKTREE_BASE/${WORKTREE_PREFIX:-$(basename "$PROJECT_ROOT")}-$task"
  if [ -d "$wt" ]; then
    echo "### $task ($wt)"
    echo ""
    echo '```'
    if (cd "$wt" 2>/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
      (cd "$wt" && git log -1 --oneline 2>/dev/null) || echo "  (无 commit)"
      (cd "$wt" && git diff "$MAIN_BRANCH..HEAD" --stat 2>/dev/null) || echo "  (无 diff)"
    else
      echo "  (worktree 不可用)"
    fi
    echo '```'
    echo ""
  fi
done

cat <<EOF
## 5. cherry-pick 建议

\`\`\`bash
cd "$PROJECT_ROOT"
git checkout $MAIN_BRANCH
EOF

PICK_LIST=""
for task in "${TASKS[@]}"; do
  sf="$SCRIPT_DIR/status/$task.status"
  [ ! -f "$sf" ] && continue
  s=$(grep '^status=' "$sf" | tail -1 | cut -d= -f2)
  if [ "$s" = "completed" ]; then
    PICK_LIST="$PICK_LIST nightshift/$task"
  fi
done

if [ -n "$PICK_LIST" ]; then
  echo "git cherry-pick$PICK_LIST"
else
  echo "# (无 completed task 可 cherry-pick)"
fi

cat <<EOF
\`\`\`

## 6. 失败但有产出 — 人工 review 候选(C1,v2 P1)

> verify 严苛度 vs 产出质量是两件事:fail_verify 的 task 若已 commit,产出可能仍有价值,人工过一眼别漏掉。
> 触发条件:status ∈ {fail_verify, fail_scope, fail_timeout} 且 worktree 有超 \$MAIN_BRANCH 的 commit。

EOF

HAS_REVIEW=false
for task in "${TASKS[@]}"; do
  sf="$SCRIPT_DIR/status/$task.status"
  [ ! -f "$sf" ] && continue
  s=$(grep '^status=' "$sf" | tail -1 | cut -d= -f2)
  case "$s" in
    fail_verify|fail_scope|fail_timeout) ;;
    *) continue ;;
  esac

  # 重算 worktree 路径(可能被 TASKS_<task>_WORKTREE override)
  worktree_var="TASKS_${task}_WORKTREE"
  override_worktree="${!worktree_var:-}"
  if [ -n "$override_worktree" ]; then
    wt="$override_worktree"
  else
    wt="$WORKTREE_BASE/${WORKTREE_PREFIX:-$(basename "$PROJECT_ROOT")}-$task"
  fi
  [ ! -d "$wt" ] && continue
  (cd "$wt" 2>/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1) || continue

  # 算 base..HEAD commit 数(若 override branch 用该分支远端 head 作 base 估算更准,简化先用 MAIN_BRANCH)
  branch_var="TASKS_${task}_BRANCH"
  override_branch="${!branch_var:-}"
  current_branch=$(cd "$wt" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$override_branch" ]; then
    base_ref="origin/$override_branch"
  else
    base_ref="$MAIN_BRANCH"
  fi
  commit_count=$(cd "$wt" && git rev-list --count "$base_ref..HEAD" 2>/dev/null || echo 0)
  [ "$commit_count" = "0" ] && continue

  HAS_REVIEW=true
  reason=$(grep '^reason=' "$sf" | tail -1 | cut -d= -f2-)
  echo "### $task ($s,$commit_count commit 超 $base_ref)"
  echo ""
  echo "- worktree: \`$wt\`"
  echo "- branch:   \`$current_branch\`$([ -n "$override_branch" ] && echo ' (override)')"
  echo "- fail 原因: \`$reason\`"
  echo "- commit:"
  echo '```'
  (cd "$wt" && git log --oneline "$base_ref..HEAD" 2>/dev/null | head -10)
  echo '```'
  echo "- review 动作:cd worktree 跑 verify 手动查 / 决定 cherry-pick / amend / drop"
  echo ""
done
if [ "$HAS_REVIEW" = "false" ]; then
  echo "无候选(failed task 均无产出 commit)。"
  echo ""
fi

cat <<EOF
## 7. 清理 worktree

\`\`\`bash
for t in ${TASKS[*]}; do
  git worktree remove "$WORKTREE_BASE/${WORKTREE_PREFIX:-$(basename "$PROJECT_ROOT")}-\$t" 2>/dev/null
  git branch -D "nightshift/\$t" 2>/dev/null
done
\`\`\`

> 注:override branch(TASKS_T0X_BRANCH)对应 worktree 不在上述清理列表,需手动 \`git worktree remove\` + 决定是否保留分支。

---

(自动生成 by .nightshift/morning.sh @ $NOW)
EOF
