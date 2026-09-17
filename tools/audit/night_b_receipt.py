#!/usr/bin/env python3
"""按审计收据 schema 向 stdout 生成当前已提交 tip 的真实 Git 收据，不写文件。"""

import argparse
import json
from pathlib import Path
import re
import subprocess


ROOT = Path(__file__).resolve().parents[2]
BASE = "c307b3ffcb155af58d4efb9179e36453297b1360"
EXCEPTIONS = {
    "docs/superpowers/plans/2026-09-16-night-b-governance.md",
    "docs/dispatch/reports/2026-09-16_night_B_receipt.yaml",
}


def command(args):
    result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, check=False)
    if result.returncode:
        raise RuntimeError(f"命令失败 {args!r}: {result.stderr or result.stdout}")
    return result.stdout


def quote(value):
    return json.dumps(value, ensure_ascii=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--head", default="HEAD", help="收据覆盖的提交；提交收据后可指定其 head_sha 重现")
    args = parser.parse_args()
    if command(["git", "status", "--porcelain"]).strip():
        raise RuntimeError("工作区未干净，不能生成收工收据")
    head = command(["git", "rev-parse", "--verify", f"{args.head}^{{commit}}"]).strip()
    if not re.fullmatch(r"[0-9a-f]{40}", head):
        raise RuntimeError("无法解析完整 tip SHA")
    diff_range = f"{BASE}..{head}"
    changed = []
    for line in command(["git", "diff", "--no-renames", "--name-status", diff_range]).splitlines():
        status, path = line.split("\t", 1)
        if status != "A" or not (
            path in EXCEPTIONS
            or re.fullmatch(r"(?:docs/audit/[^/]+\.md|tools/audit/[^/]+\.py)", path)
        ):
            raise RuntimeError(f"白名单外或非新增文件：{line}")
        changed.append(path)
    # 使用 schema 原文的固定管道；两个插值均为已验证的 Git SHA，不引入 shell 文本。
    pipeline = (
        "LC_ALL=C git -c core.quotePath=false --no-pager diff --no-ext-diff "
        "--no-textconv --no-renames --binary --full-index --no-color "
        f"{diff_range} | shasum -a 256"
    )
    patch_sha256 = command(["/bin/bash", "-o", "pipefail", "-c", pipeline]).split()[0]
    command(["git", "diff", "--check", diff_range])
    lines = [
        "schema_version: 1",
        f"base_sha: {quote(BASE)}",
        f"head_sha: {quote(head)}",
        "changed_files:",
        *(f"  - {quote(path)}" for path in sorted(set(changed), key=lambda s: s.encode())),
        'full_test_last_line: "NOT_RUN"',
        # 固定 schema 无 null 槽；0 是未运行占位，不能解释成零失败的测试结果。
        "error_block_count: 0",
        'analyze_last_line: "NOT_RUN"',
        'format_last_line: "NOT_RUN"',
        # gate.sh 的专用解析器只接受空块，不接受 break_red: []。
        "break_red:",
        "audit_verification:",
        '  kind: "git_diff_check_and_patch_sha256"',
        "  diff_check_exit: 0",
        f"  patch_sha256: {quote(patch_sha256)}",
    ]
    print("\n".join(lines))


if __name__ == "__main__":
    main()
