#!/bin/bash
# T22 verify · 总收尾 stage_audit + ROADMAP v1.3 + 6h handoff + PROGRESS 顶段

set -uo pipefail

source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"

verify_init "T22"

# === 1. path_guard 白名单 ===
verify_path_guard "docs/handoff/stage_audit_1_0_overall_.+\.md|docs/handoff/6h_unattended_handoff_.+\.md|docs/ROADMAP_1_0\.md|PROGRESS\.md|pubspec\.lock"

# === 2. stage_audit 2026-05-25 存在 + ≤80 行(目标 ≤60 + 容差) ===
audit_doc=$(ls docs/handoff/stage_audit_1_0_overall_2026-05-25*.md 2>/dev/null | head -1)
if [ -z "$audit_doc" ]; then
  verify_fail "stage_audit 2026-05-25 doc 缺"
fi
audit_lines=$(wc -l < "$audit_doc")
if [ "$audit_lines" -gt 80 ]; then
  verify_fail "stage_audit doc $audit_lines 行超 80 上限(目标 ≤60)"
fi

# === 3. 6h handoff doc 存在 + ≤70 行(目标 ≤50 + 容差) ===
handoff_doc=$(ls docs/handoff/6h_unattended_handoff_2026-05-25*.md 2>/dev/null | head -1)
if [ -z "$handoff_doc" ]; then
  verify_fail "6h_unattended_handoff doc 缺"
fi
handoff_lines=$(wc -l < "$handoff_doc")
if [ "$handoff_lines" -gt 70 ]; then
  verify_fail "handoff doc $handoff_lines 行超 70 上限(目标 ≤50)"
fi

# === 4. ROADMAP v1.3 升版 ===
if ! grep -qE "v1\.3" docs/ROADMAP_1_0.md; then
  verify_fail "ROADMAP_1_0.md 缺 v1.3 变更段"
fi
# P1.2 状态对齐(任何 P1.2 % 升或闭环 / partial 描述均接受 · 容 honest 部分完工)
if ! grep -qE "P1\.2.*[0-9]+%|P1\.2.*B[1-4]|P1\.2.*闭环|江湖恩怨.*[0-9]+|P1\.2.*partial|江湖恩怨.*partial" docs/ROADMAP_1_0.md; then
  verify_fail "ROADMAP_1_0.md P1.2 状态未对齐(应含 P1.2 % 升 / B1-4 描述 / 闭环 / partial 任一)"
fi

# === 5. PROGRESS 顶段更新 + ≤100 行 ===
progress_lines=$(wc -l < PROGRESS.md)
if [ "$progress_lines" -gt 100 ]; then
  verify_fail "PROGRESS.md $progress_lines 行超 100 上限"
fi
if ! grep -qE "2026-05-25.*nightshift T17-T22|6h 挂机" PROGRESS.md; then
  verify_fail "PROGRESS.md 顶段缺本批 nightshift T17-T22 总览"
fi

# === 6. 0 lib/data/test 改动(纯 doc task) ===
changed=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null)
if echo "$changed" | grep -qE "^lib/|^data/|^test/"; then
  echo "  改动文件清单:"
  echo "$changed" | head -10
  verify_fail "T22 doc-only task 不应改 lib/data/test · 真改了"
fi

# === 7. commit message ===
verify_commit_message "nightshift T22"

verify_done
