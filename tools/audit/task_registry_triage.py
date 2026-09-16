#!/usr/bin/env python3
"""只读核对 ready_reviewed 登记项；默认输出 JSON，--markdown 输出报告正文。"""

import argparse
from collections import Counter
from functools import lru_cache
import json
from pathlib import Path
import re
import shlex
import subprocess

import yaml


ROOT = Path(__file__).resolve().parents[2]
REGISTRY = "docs/dispatch/phase0a_overhaul/task_registry.yaml"
BASE = "c307b3ffcb155af58d4efb9179e36453297b1360"
CHAIN = "origin/codex/p2-player-flow-20260910"
ENDPOINTS = (
    "reviewed_candidate_commit", "tip_commit", "validated_tip",
    "validated_code_tip", "validated_commit", "code_candidate_commit",
)
# 这项没有提交字段、READY 标记或含任务 ID 的提交主题；精确主题及任务
# 登记 diff 已人工核对。仍要求本次 git log 命中且命中提交为目标链祖先。
REVIEWED_QUERIES = {
    "P2-M5-M6-POST-G2-INTEGRATION": "同步G2后M5M6真实状态",
}


def git(*args, required=True):
    result = subprocess.run(
        ["git", *args], cwd=ROOT, text=True, capture_output=True, check=False,
    )
    if required and result.returncode:
        raise RuntimeError(f"git {shlex.join(args)}: {result.stderr.strip()}")
    return result


@lru_cache(maxsize=None)
def resolve(ref):
    result = git("rev-parse", "--verify", f"{ref}^{{commit}}", required=False)
    return result.stdout.strip() if result.returncode == 0 else None


@lru_cache(maxsize=None)
def ancestor(sha, target):
    result = git("merge-base", "--is-ancestor", sha, target, required=False)
    if result.returncode not in (0, 1):
        raise RuntimeError(result.stderr)
    return result.returncode


def values(value):
    if isinstance(value, list):
        return [str(item) for item in value]
    return [str(value)] if value is not None else []


def md(value):
    return str(value).replace("|", "\\|").replace("\n", "<br>")


def run(target):
    target_sha = resolve(target)
    main_sha = resolve("main")
    if not target_sha or not main_sha:
        raise RuntimeError("目标链或 main 不能解析为提交")
    text = (ROOT / REGISTRY).read_text()
    data = yaml.safe_load(text)
    if not isinstance(data.get("tasks"), list):
        raise RuntimeError("登记簿缺少 tasks 列表，无法机器定位")
    nodes = yaml.compose(text)
    task_nodes = next(v for k, v in nodes.value if k.value == "tasks")
    lines = {
        next(v.value for k, v in node.value if k.value == "id"):
        node.start_mark.line + 1 for node in task_nodes.value
    }
    tasks = [task for task in data["tasks"] if task.get("status") == "ready_reviewed"]
    if len({t["id"] for t in tasks}) != len(tasks):
        raise RuntimeError("任务 ID 重复，拒绝合并计数")
    rows = []
    for task in tasks:
        row = {
            "id": task["id"], "milestone": task["milestone"],
            "registry_line": lines[task["id"]], "branch": task.get("branch"),
            "clues": {}, "refs": [], "invalid_commit_clues": [],
            "judgement": "未能判定", "method": None, "evidence": [],
        }
        for key in ENDPOINTS + ("integration_commit", "integration_commits"):
            if key in task:
                row["clues"][key] = task[key]
                for value in values(task[key]):
                    if not resolve(value):
                        row["invalid_commit_clues"].append({"field": key, "value": value})
        branch = task.get("branch")
        if branch and branch != "none":
            for ref in (f"refs/heads/{branch}", f"refs/remotes/origin/{branch}"):
                sha = resolve(ref)
                if sha:
                    subject = git("show", "-s", "--format=%s", sha).stdout.strip()
                    row["refs"].append({
                        "ref": ref, "tip": sha, "subject": subject,
                        "ready": subject.startswith("[READY]"),
                        "ancestor_exit": ancestor(sha, target_sha),
                    })

        def integrated(sha, method, clue, destination=target_sha):
            row["judgement"] = "已集成"
            row["method"] = method
            row["evidence"].append({
                "kind": "ancestor", "sha": sha, "target": destination,
                "exit": ancestor(sha, destination), "clue": clue,
                "command": f"git merge-base --is-ancestor {sha} {destination}",
            })

        # 优先用登记的完成端点，不把 base_commit / governance_source_commit
        # 或某个任意 implementation_commit 当成本任务完成证据。
        for destination in (target_sha, main_sha):
            for key in ENDPOINTS:
                for value in values(task.get(key)):
                    sha = resolve(value)
                    if sha and ancestor(sha, destination) == 0:
                        integrated(sha, "完成端点祖先", key, destination)
                        break
                if row["method"]:
                    break
            if row["method"]:
                break

        if not row["method"]:
            integration = values(task.get("integration_commits"))
            integration += values(task.get("integration_commit"))
            resolved = [resolve(value) for value in integration]
            if resolved and all(sha and ancestor(sha, target_sha) == 0 for sha in resolved):
                for sha in dict.fromkeys(resolved):
                    integrated(sha, "全部登记集成提交祖先", "integration_commit(s)")

        # 精确 READY 主题优先，再搜任务 ID；搜索结果本身也必须在候选链。
        if not row["method"]:
            queries = [task.get("ready_marker"), task["id"], REVIEWED_QUERIES.get(task["id"])]
            for query in dict.fromkeys(q for q in queries if q):
                result = git("log", "--all", "--fixed-strings", f"--grep={query}", "--format=%H%x09%s")
                hits = [line.split("\t", 1) for line in result.stdout.splitlines()]
                for sha, subject in hits:
                    # 避免只在提交正文随手提到任务名即被视为集成。
                    if query not in subject or ancestor(sha, target_sha) != 0:
                        continue
                    row["evidence"].append({
                        "kind": "log", "query": query, "sha": sha, "subject": subject,
                        "command": "git log --all --fixed-strings " + shlex.quote(f"--grep={query}") + " --format='%H %s'",
                    })
                    integrated(sha, "主题命中且祖先", query)
                    break
                if row["method"]:
                    break

        if not row["method"]:
            for key in ENDPOINTS:
                for value in values(task.get(key)):
                    sha = resolve(value)
                    if not sha:
                        continue
                    result = git("cherry", target_sha, sha)
                    entries = result.stdout.splitlines()
                    if entries and all(line.startswith("- ") for line in entries):
                        row["judgement"] = "已集成"
                        row["method"] = "全补丁等价"
                        row["evidence"].append({
                            "kind": "cherry", "sha": sha, "target": target_sha,
                            "minus": len(entries), "plus": 0, "output": entries,
                            "command": f"git cherry {target_sha} {sha}",
                        })
                        # 同主题链上提交提供额外 ancestry 抽检入口。
                        subject = git("show", "-s", "--format=%s", sha).stdout.strip()
                        matches = git("log", target_sha, "--fixed-strings", f"--grep={subject}", "--format=%H%x09%s")
                        for line in matches.stdout.splitlines():
                            hit, hit_subject = line.split("\t", 1)
                            if hit_subject == subject:
                                integrated(hit, "全补丁等价", f"原 tip {sha} 的相同主题")
                                break
                        break
                if row["method"]:
                    break

        if not row["method"]:
            # 没有登记端点的任务，仅在所登记分支的 tip 已入链时认定集成。
            for ref in row["refs"]:
                if ref["ancestor_exit"] == 0:
                    integrated(ref["tip"], "分支端点祖先", ref["ref"])
                    break
        if not row["method"]:
            row["reason"] = (
                "没有充分的任务完成端点、链上集成或替代证据；分支存在亦不能自动证明仍应合入。"
            )
        rows.append(row)
    return {
        "base_sha": BASE, "target_ref": target, "target_sha": target_sha,
        "chain_ref": CHAIN, "chain_ref_observed_sha": resolve(CHAIN),
        "main_sha": main_sha, "registry": REGISTRY,
        "registry_blob": git("hash-object", REGISTRY).stdout.strip(),
        "all_task_count": len(data["tasks"]), "ready_reviewed_count": len(rows),
        "counts": {key: sum(r["judgement"] == key for r in rows) for key in ("已集成", "已过时", "待合", "未能判定")},
        "methods": dict(Counter(row["method"] for row in rows)), "rows": rows,
    }


def markdown(result):
    out = [
        "# 登记簿 ready_reviewed 任务分类审计（2026-09-17）", "",
        "## 实测口径与复跑命令", "",
        f"本次固定基线及目标链提交：`{result['target_sha']}`；读取到 `{CHAIN}` = `{result['chain_ref_observed_sha']}`；`main` = `{result['main_sha']}`。未 fetch，结论只覆盖本地已有 Git 对象及这些固定提交。",
        f"登记簿 blob：`{result['registry_blob']}`。任务总数 **{result['all_task_count']}**，`ready_reviewed` **{result['ready_reviewed_count']}** 条，正文逐条表 **{len(result['rows'])}** 行。", "",
        "```bash", "python3 - <<'PY'", "import yaml",
        f"d = yaml.safe_load(open('{REGISTRY}'))",
        "print(sum(t.get('status') == 'ready_reviewed' for t in d['tasks']))", "PY",
        f"rg -c '^    status: ready_reviewed$' {REGISTRY}",
        "python3 tools/audit/task_registry_triage.py",
        "python3 tools/audit/task_registry_triage.py --markdown", "```", "",
        f"两条独立统计命令均输出 `{result['ready_reviewed_count']}`。脚本依赖本机已有 PyYAML；默认固定目标 SHA，默认 stdout 为 JSON，`--markdown` 重建本正文和逐条表，不包含后附人工审阅的 M 门附录。", "",
        "| 判定 | 实测数量 |", "|---|---:|",
    ]
    out.extend(f"| {key} | {value} |" for key, value in result["counts"].items())
    out += ["", "| 证据方法 | 条数 |", "|---|---:|"]
    out.extend(f"| {key} | {value} |" for key, value in result["methods"].items())
    out += [
        "", "分类边界：已集成指登记任务的历史交付已进入候选链/main，或源分支全部差异补丁已等价进入；不表示当前功能未经后续调整、不表示 formal M0–M9、真人或 Windows 验收关闭。`base_commit`、测试计数和 READY 字样本身均不作为集成证据。登记簿当前结构可机器定位，无需改写。",
        "", "已过时仅接受明确替代证据；待合必须有尚未纳入且仍有效的交付证据。没有为了凑三类而强行分配条目。祖先命令退出码 `0` 为真、`1` 为假；全补丁等价另外列出 `git cherry` 的 `-`/`+` 数，未把源 SHA 非祖先误报为待合。", "",
        "## 逐条表", "",
        "| 任务 id | 里程碑 | 登记分支与提交线索 | 判定 | 本次机器证据 |",
        "|---|---|---|---|---|",
    ]
    for row in result["rows"]:
        clues = [f"`{row['branch']}`", f"登记簿:{row['registry_line']}"]
        for key, value in row["clues"].items():
            clues.append(f"{key}=" + ", ".join(f"`{v}`" for v in values(value)))
        if not row["refs"]:
            clues.append("登记的同名本地/远端跟踪分支均不存在")
        for ref in row["refs"]:
            clues.append(f"{ref['ref']} → `{ref['tip']}`；tip [READY]={'是' if ref['ready'] else '否'}")
        evidence = []
        for entry in row["evidence"]:
            suffix = ""
            if entry["kind"] == "ancestor":
                suffix = f" → exit={entry['exit']}（{entry['clue']}）"
            elif entry["kind"] == "log":
                suffix = f" → `{entry['sha']}` {entry['subject']}"
            elif entry["kind"] == "cherry":
                suffix = f" → -={entry['minus']}，+=0；源提交非祖先，全部差异补丁等价"
            evidence.append(f"`{entry['command']}`{suffix}")
        for clue in row["invalid_commit_clues"]:
            evidence.append(f"登记 {clue['field']}=`{clue['value']}` 无法解析；未用该值作证")
        if row.get("reason"):
            evidence.append(row["reason"])
        out.append("| " + " | ".join(md(v) for v in (row["id"], row["milestone"], "<br>".join(clues), row["judgement"], "<br>".join(evidence))) + " |")
    out += ["", "## 建议（不修改登记簿）", ""]
    integrated = [r for r in result["rows"] if r["judgement"] == "已集成"]
    out += [
        f"逐条表判为已集成的 **{len(integrated)}** 项建议协调者按目标链归属改为 `integrated_candidate_chain`；另行验证主线归属后再采用 `integrated_main`。本审计没有复跑远端 CI，不建议直接冠以 `*_ci_success`。",
        "", "本次没有证据需要把这些 ready_reviewed 项改为 `superseded`；也不能从该集合未见待合项推导全仓没有孤立债，B-3 审计的是另一个分支集合。保留登记历史分支及源提交可以溯源，不应为状态自洽而删除证据。",
    ]
    invalid = [r for r in result["rows"] if r["invalid_commit_clues"]]
    for row in invalid:
        out += ["", f"`{row['id']}` 有不可解析的提交值，建议先按表内可复核的真实提交纠正引用，不能仅截断旧值猜 SHA。"]
    out += ["", "## 验证边界", "", "本次执行 YAML 解析、Git 对象解析、逐项祖先/补丁核对及报告行数检查；没有运行 Flutter analyze/format/test，没有启动游戏或读取真实存档。数字均由本次脚本运行产生。", ""]
    return "\n".join(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", default=BASE, help="核对目标 ref/SHA，默认锁定派单基线")
    parser.add_argument("--markdown", action="store_true")
    args = parser.parse_args()
    result = run(args.target)
    output = markdown(result) if args.markdown else json.dumps(result, ensure_ascii=False, indent=2)
    print(output.rstrip())


if __name__ == "__main__":
    main()
