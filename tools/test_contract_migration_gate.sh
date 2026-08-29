#!/bin/bash
# 测试契约迁移校验器
#
# 背景:gate.sh 的 test_deletions 是零删除策略(test/ 下出现任何 ^-[^-] 即 FAIL)。
# 但当一个单的产品目标本身就是改掉旧契约——例如把第一章其余四关从 legacy 路由
# 迁到 migrated——那些钉住旧状态的断言必然要删,零删除策略给不出合法出口。
#
# 本校验器把「这次删除是否合法」变成机器可判的条件,取代人工逐条读 diff。
#
# 用法:
#   tools/test_contract_migration_gate.sh <worktree> <base_sha> <head_sha> <ledger.yaml>
# 退出码 0 = PASS;非 0 = FAIL 并逐条打印原因。
#
# 判据(全部机器可判):
#   G1 每条被删的断言/用例行都在登记表里精确登记(按出现次数配平,重复行需重复登记)
#   G2 登记表没有幽灵条目(登记了但 diff 里并不存在的删除)
#   G3 每条登记项都有非空 reason,且 replacement 字符串在 head 树的 test/ 下真实存在
#   G4 新增 expect 数 >= 删除 expect 数,且新增用例数 >= 删除用例数
#
# 明确判不了:替代断言在语义上是否真的比被删的更强。这一条由派单包冻结的范围
# 与 G2 真人试玩兜底,不要假装本校验器覆盖了它。

set -u

if [[ "$#" -ne 4 ]]; then
  printf 'usage: test_contract_migration_gate.sh <worktree> <base_sha> <head_sha> <ledger.yaml>\n' >&2
  exit 2
fi

WORKTREE="$1"
BASE_SHA="$2"
HEAD_SHA="$3"
LEDGER="$4"

git -C "$WORKTREE" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  printf 'FAIL: invalid worktree: %s\n' "$WORKTREE" >&2
  exit 2
}
[[ -f "$LEDGER" ]] || {
  printf 'FAIL: ledger not found: %s\n' "$LEDGER" >&2
  exit 2
}

DIFF_FILE="$(mktemp)"
trap 'rm -f "$DIFF_FILE"' EXIT
if ! git -C "$WORKTREE" --no-pager diff --no-ext-diff --no-color \
  "$BASE_SHA".."$HEAD_SHA" -- 'test/' >"$DIFF_FILE" 2>/dev/null; then
  printf 'FAIL: git diff failed\n' >&2
  exit 2
fi

python3 - "$DIFF_FILE" "$LEDGER" "$WORKTREE" "$HEAD_SHA" <<'PY'
# -*- coding: utf-8 -*-
import collections
import re
import subprocess
import sys

diff_path, ledger_path, worktree, head_sha = sys.argv[1:5]

with open(diff_path, encoding="utf-8") as handle:
    diff_lines = handle.read().splitlines()

CASE_RE = re.compile(r"^\s*(test|testWidgets|group)\s*\(")


def load_bearing(text):
    return "expect(" in text or CASE_RE.match(text) is not None


deleted, added = [], []
for line in diff_lines:
    if line.startswith("-") and not line.startswith("---"):
        deleted.append(line[1:])
    elif line.startswith("+") and not line.startswith("+++"):
        added.append(line[1:])

deleted_key = collections.Counter(t.strip() for t in deleted if load_bearing(t))


def count(rows, needle):
    if needle == "expect":
        return sum(1 for r in rows if "expect(" in r)
    return sum(1 for r in rows if CASE_RE.match(r))


# ---- 解析登记表(只认固定体例,不引 YAML 依赖) ----
entries, current = [], None
with open(ledger_path, encoding="utf-8") as handle:
    for raw in handle.read().splitlines():
        stripped = raw.strip()
        for field in ("deleted", "replacement", "reason"):
            marker = "- {}:".format(field) if field == "deleted" else "{}:".format(field)
            if stripped.startswith(marker):
                value = stripped[len(marker):].strip()
                if len(value) >= 2 and value[0] == value[-1] == '"':
                    value = value[1:-1]
                if field == "deleted":
                    current = {"deleted": value, "replacement": "", "reason": ""}
                    entries.append(current)
                elif current is not None:
                    current[field] = value
                break

failures = []

if not entries:
    failures.append("登记表为空或体例不符(每项需 `- deleted:` / `replacement:` / `reason:`)")

ledger_key = collections.Counter(e["deleted"].strip() for e in entries)

# G1 每条被删的断言/用例都已登记
for text, need in deleted_key.items():
    have = ledger_key.get(text, 0)
    if have < need:
        failures.append("G1 未登记的删除(需 {} 条登记,实有 {}):{}".format(need, have, text[:110]))

# G2 无幽灵条目
for text, have in ledger_key.items():
    need = deleted_key.get(text, 0)
    if have > need:
        failures.append("G2 幽灵登记项(diff 里只删了 {} 条,登记了 {}):{}".format(need, have, text[:110]))

# G3 reason 非空 + replacement 在 head 树里真实存在
for entry in entries:
    if not entry["reason"]:
        failures.append("G3 reason 为空:{}".format(entry["deleted"][:110]))
    replacement = entry["replacement"]
    if not replacement:
        failures.append("G3 replacement 为空:{}".format(entry["deleted"][:110]))
        continue
    found = subprocess.run(
        ["git", "-C", worktree, "grep", "-F", "-q", "--", replacement, head_sha, "--", "test/"],
        capture_output=True,
    )
    if found.returncode != 0:
        failures.append(
            "G3 replacement 在 head 的 test/ 下不存在:{}".format(replacement[:110])
        )

# G4 断言与用例总数不下降
del_expect, add_expect = count(deleted, "expect"), count(added, "expect")
del_case, add_case = count(deleted, "case"), count(added, "case")
if add_expect < del_expect:
    failures.append("G4 expect 净减少:删 {} 增 {}".format(del_expect, add_expect))
if add_case < del_case:
    failures.append("G4 用例净减少:删 {} 增 {}".format(del_case, add_case))

print("[migration] expect 删 {} / 增 {};用例 删 {} / 增 {};登记 {} 条".format(
    del_expect, add_expect, del_case, add_case, len(entries)))

if failures:
    for item in failures:
        print("[FAIL] " + item)
    print("FAIL: test_contract_migration")
    sys.exit(1)

print("PASS: test_contract_migration")
PY
