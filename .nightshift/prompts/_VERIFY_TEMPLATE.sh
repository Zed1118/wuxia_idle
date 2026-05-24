#!/bin/bash
# T?? verify · 通用模板 v2 体例
# 复制到 prompts/T??.verify.sh,改 task id + 白名单 + 验证逻辑

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T??"

# === 1. diff guard 越界检查(v2 必跑) ===
# allow_regex 形如 "data/.*\\.yaml|test/.*\\.dart"
# 越界 → exit 30 → dispatcher 标 fail_scope
verify_path_guard "data/.*\\.yaml|test/.*\\.dart"

# === 2. 文件存在性 ===
verify_file_exists "data/foo.yaml"

# === 3. count/delta(用 main baseline 算式,不写死期望) ===
# verify_count_delta <file> <grep_pat> <delta> <label>
verify_count_delta "data/foo.yaml" "^  - id: " 3 "items"

# === 4. 黑名单词(文案 yaml 通用) ===
verify_blacklist_words "data/foo.yaml"

# === 5. Flutter 专属(Node/Generic 项目删) ===
verify_build_runner_strict
verify_analyze_clean
verify_local_tests "test/foo_test.dart"

# === 6. commit message ===
verify_commit_message "nightshift T??"

verify_done
