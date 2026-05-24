#!/bin/bash
# Nightshift VERIFY_TEMPLATE · 跨项目通用 verify helper 库
#
# 修补的历史 bug(memory 锚点):
#   - verify_count_delta: feedback_nightshift_verify_count_baseline(写死期望误报)
#   - verify_changed_files_only: feedback_nightshift_verify_changedoutside_bug(git show 中文 msg 误抓)
#   - verify_build_runner_strict: feedback_nightshift_build_runner_silent_fail(静默 fail)
#   - verify_analyze_clean: feedback_flutter_analyze_fatal_errors_invalid(--fatal-errors 非法)
#   - verify_path_guard: nightshift-v2 新增(diff guard 越界检查,Scheme D 标 FAIL_SCOPE 不回滚)
#
# 用法:每个 T0X.verify.sh 顶部 source 本文件,再按需调 helper:
#   #!/bin/bash
#   source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"
#   verify_init "T01"
#   verify_path_guard "data/**|test/**"     # 越界检查(v2 新增)
#   verify_file_exists "data/foo.yaml"
#   verify_count_delta "data/foo.yaml" "^  - id: " 3 "items"
#   verify_blacklist_words "data/foo.yaml"
#   verify_build_runner_strict              # flutter 专属
#   verify_analyze_clean                    # flutter 专属
#   verify_local_tests "test/foo_test.dart" # flutter 专属
#   verify_commit_message "nightshift T01"
#   verify_done
#
# 项目类型适配:
#   - Flutter: 调全部 helper
#   - Node: 跳 verify_build_runner_strict / verify_analyze_clean / verify_local_tests,
#           自定义 npm/jest 命令(本 helper 暂不内置)
#   - Generic: 只调 verify_path_guard / verify_file_exists / verify_commit_message / verify_changed_files_only

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

verify_warn() {
  echo "VERIFY WARN [$TASK]: $1"
  echo "WARN: $1" >> "$TASK_LOG"
}

# === Path guard(v2 新增,越界文件检查,Scheme D 标 FAIL_SCOPE) ===
# 用法: verify_path_guard "<allow_regex>" [<deny_regex>]
# allow_regex 形如 "data/.*\.yaml|test/.*\.dart"
# deny_regex 缺省时只用全局禁区(env GLOBAL_FORBIDDEN_RE)
# 行为: 越界文件输出到 stderr + 退 exit 30(FAIL_SCOPE),不回滚 worktree
verify_path_guard() {
  local allow="$1"
  local deny="${2:-}"
  local global_deny="${GLOBAL_FORBIDDEN_RE:-(^|/)(\\.env($|\\.)|.*\\.pem$|.*\\.key$|.*\\.p12$|key\\.properties$|keystore$|secrets?\\.(json|ya?ml|toml)$|\\.mcp\\.json$|\\.claude\\.json$)}"

  local changed
  changed=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || echo "")

  if [ -z "$changed" ]; then
    echo "  path_guard: no changes in HEAD commit(可能 Claude 没改动 / 没 commit)" | tee -a "$TASK_LOG"
    return 0
  fi

  local violations=""
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    # 全局禁区先查
    if echo "$f" | grep -Eq "$global_deny"; then
      violations="${violations}  [GLOBAL_DENY] $f"$'\n'
      continue
    fi
    # task 禁区查
    if [ -n "$deny" ] && echo "$f" | grep -Eq "$deny"; then
      violations="${violations}  [TASK_DENY] $f"$'\n'
      continue
    fi
    # 白名单查(只在 allow 非空时启用)
    if [ -n "$allow" ] && ! echo "$f" | grep -Eq "^($allow)$"; then
      violations="${violations}  [SCOPE_OUT] $f"$'\n'
    fi
  done <<< "$changed"

  if [ -n "$violations" ]; then
    echo "VERIFY FAIL [$TASK] path_guard 越界,本 task 标 FAIL_SCOPE(早晨人工 review,不自动回滚):"
    echo "$violations"
    echo "$violations" >> "$TASK_LOG"
    exit 30
  fi
  echo "  path_guard: OK ($(echo "$changed" | wc -l | tr -d ' ') files in scope)" | tee -a "$TASK_LOG"
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

# 目录文件数 delta
verify_dir_file_count_delta() {
  local dir="$1"; local glob="$2"; local delta="$3"; local label="$4"
  local baseline_files actual
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

# === Blacklist words(文案 yaml/md 通用,默认套用 wuxia_idle 体例,可覆盖) ===
# 用法: verify_blacklist_words <file> [<word1> <word2> ...]
# 缺省词表见 BLACKLIST_WORDS env,可在 nightshift.conf 自定义
# v2 修补(2026-05-24 wuxia_idle T03 教训): 跳过 `--no <word>` / `-- <word>` 负面声明体例
#   memory feedback_nightshift_v2_first_run_lessons A3
verify_blacklist_words() {
  local file="$1"; shift || true
  local words=("$@")
  if [ "${#words[@]}" -eq 0 ]; then
    if [ -n "${BLACKLIST_WORDS:-}" ]; then
      IFS=' ' read -ra words <<< "$BLACKLIST_WORDS"
    else
      words=(legendary epic 史诗 神器 传说级 无敌 最强 究极 霸气 逆天 刀光剑影 血溅)
    fi
  fi
  for w in "${words[@]}"; do
    # 抓 word 出现 + 不在 `--no <...word...>` / `-- <...word...>` 负面声明段
    # 算法: grep -n 出每行,再过滤含 `--no ` / `--neg ` 前置 + word 的行(MJ prompt 防护体例)
    local hits
    hits=$(grep -n "$w" "$file" 2>/dev/null | grep -vE "^[0-9]+:.*--no [^|]*\b$w\b" | grep -vE "^[0-9]+:.*-- [^|]*\b$w\b" || true)
    if [ -n "$hits" ]; then
      # 还要检是否在「黑名单词」声明段(grep 出现 `黑名单|blacklist` 同行)
      local real_hits
      real_hits=$(echo "$hits" | grep -vE "黑名单|blacklist|禁用|禁词|negative prompt" || true)
      if [ -n "$real_hits" ]; then
        echo "$file 含黑名单词 '$w':"
        echo "$real_hits" | head -3
        verify_fail "$file 含黑名单词 '$w'(非 --no 防护段)"
      fi
    fi
  done
}

# === 章节标记容错 grep(v2 新增,A4/A5 修补) ===
# 用法: verify_section_titles <file> <title1> <title2> ...
# 不查符号(§/##/###),只查节标题文字,容忍多种 markdown 体例
#   memory feedback_nightshift_v2_first_run_lessons A4
verify_section_titles() {
  local file="$1"; shift || true
  if [ "$#" -eq 0 ]; then
    verify_warn "verify_section_titles 调用无 title 参数"
    return 0
  fi
  for title in "$@"; do
    # grep 节标题文字,要求在 markdown heading 行(以 # 开头)
    if ! grep -E "^#{1,4}.*$title" "$file" >/dev/null 2>&1; then
      verify_fail "节标题 '$title' missing(查 ^#{1,4}.*$title)"
    fi
  done
  echo "  section_titles: $* OK" | tee -a "$TASK_LOG"
}

# === Diff 内容验证(v2 新增,A2 修补) ===
# 不写死文件路径,改查 git diff 命中 keyword
# 用法: verify_diff_contains <keyword1> <keyword2> ...
#   memory feedback_nightshift_v2_first_run_lessons A2
verify_diff_contains() {
  local diff_files
  diff_files=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null)
  if [ -z "$diff_files" ]; then
    verify_fail "diff 为空(无 commit 文件)"
  fi
  for kw in "$@"; do
    if ! echo "$diff_files" | grep -qE "$kw"; then
      echo "  diff 文件清单:"
      echo "$diff_files" | head -5 | sed 's/^/    /'
      verify_fail "diff 未含 keyword '$kw'"
    fi
  done
  echo "  diff_contains: $* OK ($(echo "$diff_files" | wc -l | tr -d ' ') files)" | tee -a "$TASK_LOG"
}

# === Flutter 专属 helper(Node/Generic 项目跳过) ===

# Build runner FAIL-FAST(不静默)
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
}

# Analyze(--fatal-warnings 不 --fatal-infos)
# memory feedback_flutter_analyze_fatal_errors_invalid
verify_analyze_clean() {
  local a_log="/tmp/nightshift_analyze_${TASK}.log"
  if ! flutter analyze --fatal-warnings > "$a_log" 2>&1; then
    echo "  analyze fail, last 20 lines:"
    tail -20 "$a_log"
    verify_fail "flutter analyze --fatal-warnings non-zero"
  fi
}

# Local tests(只跑相关 test 文件,memory feedback_workflow_speed_levers Lever 1)
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

# === Changed files only(改动越界检查,老 API 保留兼容) ===
# memory feedback_nightshift_verify_changedoutside_bug:用 git diff-tree 不 git show --name-only
# 注: v2 推荐用 verify_path_guard,本函数保留向后兼容
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
