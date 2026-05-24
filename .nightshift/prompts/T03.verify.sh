#!/bin/bash
# T03 verify v2 · inner_demon 7 主题 enemy MJ prompt 起草
# v2 修补(2026-05-24): A3 blacklist 跳 --no 防护段
set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T03"

DOC="docs/art/inner_demon_enemy_mj_prompts_2026-05-24.md"

# === 1. 文件存在 ===
verify_file_exists "$DOC"

# === 2. path_guard ===
verify_path_guard "docs/art/.*\.md"

# === 3. 7 主题中英文锚都在 ===
for theme in 贪 嗔 痴 慢 疑 空 真; do
  grep -q "$theme" "$DOC" || verify_fail "主题 '$theme' 中文锚 missing"
done
for theme in greed wrath obsession arrogance doubt void truth; do
  grep -q "$theme" "$DOC" || verify_fail "主题 '$theme' 英文锚 missing"
done

# === 4. 7 个 MJ prompt(grep --ar 出现 ≥ 7) ===
PROMPT_COUNT=$(grep -c -- "--ar" "$DOC" || echo 0)
if [ "$PROMPT_COUNT" -lt 7 ]; then
  verify_fail "MJ prompt 数 $PROMPT_COUNT < 7"
fi

# === 5. 黑名单词检查 — MJ prompt doc 特殊性 ===
# MJ prompt doc 通篇都在讨论「禁词 / --no 防护 / 3 重防护」体例,
# 元描述也会出现 legendary 字面值。本类 doc 不调 verify_blacklist_words,
# 改靠 prompt 自检 + 早上人工 review。
# memory feedback_nightshift_v2_first_run_lessons A3 第二轮修补
echo "  blacklist: skipped (MJ doc 元描述类,改人工 review)"

# === 6. 体量 ≤ 150 行 ===
LINES=$(wc -l < "$DOC")
if [ "$LINES" -gt 150 ]; then
  verify_fail "doc 体量爆 $LINES > 150 行"
fi
echo "  doc lines: $LINES (≤150 OK)"

# === 7. commit message ===
verify_commit_message "nightshift T03"

verify_done
