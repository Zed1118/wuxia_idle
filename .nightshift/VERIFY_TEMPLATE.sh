#!/bin/bash
# Nightshift VERIFY_TEMPLATE · 下次 nightshift 写 verify.sh 必须套此模板
#
# 修补 2026-05-20 wuxia_idle nightshift 暴露的 4 个 verify bug:
#   1. count 写死期望(T05 events 45 vs 46 → 49 ≠ 50 误报)→ 用 BASELINE + DELTA 算式
#   2. git show --name-only 中文 commit msg body 误抓(2026-05-19 教训)→ 用 git diff-tree
#   3. build_runner 静默失败(T04/T06 analyze 727 误报)→ fail-fast + tee log
#   4. flutter analyze --fatal-errors 非法 flag → 用 --fatal-warnings
#
# memory 锚点:
#   - feedback_nightshift_verify_count_baseline
#   - feedback_nightshift_build_runner_silent_fail
#   - feedback_nightshift_verify_changedoutside_bug
#   - feedback_flutter_analyze_fatal_errors_invalid
#   - feedback_wuxia_pen_build_runner(*.g.dart gitignored)
#
# 用法:每个 T0X.verify.sh 顶部 source 本文件,然后调下面的 helper:
#   #!/bin/bash
#   source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"
#   verify_init "T01"
#   verify_file_exists "data/synergies.yaml"
#   verify_count_delta "data/synergies.yaml" "^  - id: synergy_" 3 "synergies"
#   verify_blacklist_words "data/synergies.yaml"
#   verify_build_runner_strict
#   verify_analyze_clean
#   verify_local_tests "test/balance/synergy_hot_loop_upgrade_test.dart"
#   verify_commit_message "nightshift T01"
#   verify_changed_files_only "data/synergies\.yaml|test/balance/synergy_hot_loop_upgrade_test\.dart"
#   verify_done

set -uo pipefail

# === Init ===
verify_init() {
  TASK="$1"
  TASK_LOG="/tmp/nightshift_verify_${TASK}.log"
  echo "=== VERIFY $TASK init ===" > "$TASK_LOG"
}

verify_fail() {
  echo "VERIFY FAIL [$TASK]: $1"
  tail -30 "$TASK_LOG" 2>/dev/null || true
  exit 1
}

# === File / count helpers ===
verify_file_exists() {
  test -f "$1" || verify_fail "$1 missing"
}

# count + delta(替代写死期望值)
# 用法:verify_count_delta <file> <grep_pattern> <expected_delta> <human_label>
# 算法:期望值 = baseline(git show main:<file> 实测) + delta
verify_count_delta() {
  local file="$1"; local pat="$2"; local delta="$3"; local label="$4"
  local baseline
  # 从 main HEAD 实测 baseline(若 main 没该文件,baseline=0)
  if git show "main:$file" >/dev/null 2>&1; then
    baseline=$(git show "main:$file" 2>/dev/null | grep -c "$pat" || echo 0)
  else
    baseline=0
  fi
  local actual
  actual=$(grep -c "$pat" "$file" || echo 0)
  local expected=$((baseline + delta))
  echo "  $label: baseline=$baseline + delta=$delta → expected=$expected (actual=$actual)" | tee -a "$TASK_LOG"
  if [ "$actual" -ne "$expected" ]; then
    verify_fail "$label count $actual != baseline $baseline + $delta = $expected"
  fi
}

# 目录文件数 delta(events / narratives 等)
verify_dir_file_count_delta() {
  local dir="$1"; local glob="$2"; local delta="$3"; local label="$4"
  local baseline_files actual
  # baseline 来自 main 分支的目录(简化:从主 worktree 读)
  local main_wt
  main_wt=$(git worktree list | head -1 | awk '{print $1}')
  baseline_files=$(cd "$main_wt" && ls $dir/$glob 2>/dev/null | wc -l | tr -d ' ')
  actual=$(ls "$dir"/$glob 2>/dev/null | wc -l | tr -d ' ')
  local expected=$((baseline_files + delta))
  echo "  $label: baseline=$baseline_files + delta=$delta → expected=$expected (actual=$actual)" | tee -a "$TASK_LOG"
  if [ "$actual" -ne "$expected" ]; then
    verify_fail "$label dir count $actual != baseline $baseline_files + $delta = $expected"
  fi
}

# === Blacklist words(文案 yaml/md 通用) ===
verify_blacklist_words() {
  local file="$1"
  local words=(legendary epic 史诗 神器 传说级 无敌 最强 究极 霸气 逆天 刀光剑影 血溅)
  for w in "${words[@]}"; do
    if grep -q "$w" "$file"; then
      verify_fail "$file 含黑名单词 '$w'"
    fi
  done
}

# === Build runner FAIL-FAST(不静默) ===
# memory feedback_nightshift_build_runner_silent_fail
verify_build_runner_strict() {
  local br_log="/tmp/nightshift_build_runner_${TASK}.log"
  echo "  Running build_runner (fail-fast, log: $br_log)" | tee -a "$TASK_LOG"
  if ! flutter pub get >> "$br_log" 2>&1; then
    verify_fail "pub get failed, see $br_log"
  fi
  if ! dart run build_runner build --delete-conflicting-outputs >> "$br_log" 2>&1; then
    echo "  build_runner exit non-zero, last 30 lines:"
    tail -30 "$br_log"
    verify_fail "build_runner failed"
  fi
  # 抽 1 个代表性 .g.dart 验证生成产物
  if [ -f lib/core/application/battle_providers.dart ]; then
    test -f lib/core/application/battle_providers.g.dart || \
      verify_fail "battle_providers.g.dart missing after build_runner"
  fi
}

# === Analyze(--fatal-warnings 不 --fatal-infos) ===
# memory feedback_flutter_analyze_fatal_errors_invalid
verify_analyze_clean() {
  local a_log="/tmp/nightshift_analyze_${TASK}.log"
  if ! flutter analyze --fatal-warnings > "$a_log" 2>&1; then
    echo "  analyze fail, last 20 lines:"
    tail -20 "$a_log"
    verify_fail "flutter analyze --fatal-warnings non-zero"
  fi
}

# === Local tests(只跑相关 test 文件,memory feedback_workflow_speed_levers Lever 1) ===
verify_local_tests() {
  for f in "$@"; do
    if [ -f "$f" ]; then
      if ! flutter test "$f" >> "$TASK_LOG" 2>&1; then
        verify_fail "$f 不通过"
      fi
    fi
  done
}

# === Commit message check ===
verify_commit_message() {
  local needle="$1"
  git log -1 --pretty=%s | grep -q "$needle" || verify_fail "commit message 不含 '$needle'"
}

# === Changed files only(改动越界检查) ===
# memory feedback_nightshift_verify_changedoutside_bug:用 git diff-tree 不 git show --name-only
verify_changed_files_only() {
  local allow_pattern="$1"
  local changed
  changed=$(git diff-tree --no-commit-id --name-only -r HEAD)
  local outside
  outside=$(echo "$changed" | grep -vE "^($allow_pattern)$|^$" || true)
  if [ -n "$outside" ]; then
    echo "  改动越界:"
    echo "$outside"
    verify_fail "改动越界"
  fi
}

# === Done ===
verify_done() {
  echo "VERIFY PASS: $TASK"
}
