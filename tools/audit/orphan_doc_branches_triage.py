#!/usr/bin/env python3
"""只读复核夜批 B-3 的分支元数据；仅向标准输出输出 JSON。"""

import argparse
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASELINE = "c307b3ffcb155af58d4efb9179e36453297b1360"
CHAIN = "origin/codex/p2-player-flow-20260910"
LEDGER = "docs/audit/worktree_ledger_2026-09-16.md"
EXCLUDED = {
    "codex/tower-multi-recon-20260912": "台账执行记录明确排除已移除的目录；分支仍存在",
    "worktree-review-followup-20260912": "台账执行记录明确单列的 locked 保留 worktree",
}


def git(*args, allowed=(0,)):
    result = subprocess.run(
        ["git", *args], cwd=ROOT, text=True, capture_output=True, check=False
    )
    if result.returncode not in allowed:
        raise RuntimeError(f"git {args!r}: {result.stderr.strip()}")
    return result


def output(*args):
    return git(*args).stdout.strip()


def collect(chain):
    chain_sha = output("rev-parse", f"{chain}^{{commit}}")
    ledger = output("show", f"{BASELINE}:{LEDGER}")
    section = ledger.split("## ③ 孤立 · 仅文档/证据/工具", 1)[1].split("## ②", 1)[0]
    listed = re.findall(r"\| `(codex/[^`]+|worktree-review-followup[^`]+)` \|", section)
    branches = [branch for branch in listed if branch not in EXCLUDED]
    if len(listed) != 23 or len(branches) != 21 or len(set(branches)) != 21:
        raise RuntimeError("台账结构或分支数改变，停止而不猜测范围")
    rows = []
    for branch in branches:
        tip = output("rev-parse", f"refs/heads/{branch}^{{commit}}")
        merge_base = output("merge-base", chain_sha, tip)
        files = output("diff", "--name-only", f"{merge_base}..{tip}").splitlines()
        cherry = output("cherry", chain_sha, tip).splitlines()
        details = []
        for path in files:
            branch_blob = git("rev-parse", f"{tip}:{path}", allowed=(0, 128))
            chain_blob = git("rev-parse", f"{chain_sha}:{path}", allowed=(0, 128))
            details.append({
                "path": path,
                "exists_on_chain": chain_blob.returncode == 0,
                "same_blob_on_chain": branch_blob.returncode == 0
                and chain_blob.returncode == 0
                and branch_blob.stdout == chain_blob.stdout,
            })
        commits = []
        for line in output("log", "--reverse", "--format=%H%x09%s", f"{chain_sha}..{tip}").splitlines():
            sha, subject = line.split("\t", 1)
            commits.append({"sha": sha, "subject": subject})
        rows.append({
            "branch": branch,
            "tip": tip,
            "tip_subject": output("log", "-1", "--format=%s", tip),
            "merge_base": merge_base,
            "unique_commit_count": int(output("rev-list", "--count", f"{chain_sha}..{tip}")),
            "commits": commits,
            "files": details,
            "is_ancestor_exit_code": git("merge-base", "--is-ancestor", tip, chain_sha, allowed=(0, 1)).returncode,
            "patch_equivalent_count": sum(line.startswith("- ") for line in cherry),
            "patch_unique_count": sum(line.startswith("+ ") for line in cherry),
            "git_cherry": cherry,
        })
    return {
        "ledger_baseline": BASELINE,
        "chain_argument": chain,
        "chain_sha": chain_sha,
        "ledger_row_count": len(listed),
        "excluded": EXCLUDED,
        "branch_count": len(rows),
        "unique_commit_count_sum": sum(row["unique_commit_count"] for row in rows),
        "rows": rows,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--chain", default=CHAIN, help="复核链；要固定复现时传报告中的 SHA")
    args = parser.parse_args()
    print(json.dumps(collect(args.chain), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
