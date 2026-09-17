#!/usr/bin/env python3
"""只读执行四层复核；所有命中数来自本次 rg/git，唯一可选写入为本单报告。"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys

sys.dont_write_bytecode = True
import numbers_key_usage as usage

REPORT = "docs/audit/numbers_yaml_unused_keys_review_2026-09-17.md"
ORIGINAL = "docs/audit/numbers_yaml_unused_keys_2026-09-17.md"
NC = "lib/data/numbers_config.dart"
GR = "lib/data/game_repository.dart"
CHOICES = ("删除候选", "头注 UNUSED", "保留（有合同）", "待拍板")
POOL_PATHS = {f"equipment.tiers[].{slot}.attack_max" for slot in ("weapon", "armor", "accessory")}

# 人工语义结论与定位；不是手填命中数。rg/sed 每次重新执行并保存完整输出。
RULES = [
    (r"meta\.", "头注 UNUSED", "存档时间戳，不是运行配置；已有纯文档说明。", "last_updated|纯文档", ["data/numbers.yaml"], [("data/numbers.yaml", 28, 34)]),
    (r"combat\.", "头注 UNUSED", "公式结构文档；布尔字段不是运行时开关，保留说明锚。", "纯文档|最终伤害|基础伤害|skill_multiplier_added", ["GDD.md", "data/numbers.yaml"], [("data/numbers.yaml", 99, 118), ("GDD.md", 319, 349)]),
    (r"equipment\.tiers", "保留（有合同）", "独立装备 YAML 明确要求数值范围对齐该段；阶名也属于同表设计锚，零读取不解除合同。", "equipment.tiers|寻常货|像样货|利器|神物", ["data/equipment.yaml", "GDD.md"], [("data/equipment.yaml", 1, 10), ("GDD.md", 153, 168)]),
    (r"equipment\.enhancement\.max_level_formula", "保留（有合同）", "GDD 强化上限合同仍存在；生产用角色层数实现，该字符串未被读取。", "强化等级上限", ["GDD.md"], [("GDD.md", 429, 429)]),
    (r"equipment\.enhancement\.", "保留（有合同）", "GDD 明定高段成功曲线以该段为准；当前解析器使用独立公式实现，不能直接删设计公式。", "success_curve|0.30|0.02", ["GDD.md"], [("GDD.md", 431, 445), (NC, 990, 1010)]),
    (r"equipment\.resonance\.", "保留（有合同）", "换主清零仍是 GDD 合同，原注释明确预埋勿删；字段本身未读取。", "换主清零|new_owner_retention", ["GDD.md", "data/numbers.yaml", "docs/audit/full_audit_2026-06-16.md"], [("GDD.md", 469, 469), ("data/numbers.yaml", 832, 837)]),
    (r"techniques\.", "保留（有合同）", "七阶名称有 GDD 与 schema 合同；解析器只取阶枚举与速度，阶名是设计锚。", "入门功|常练功|传说神功", ["GDD.md", "data_schema.md"], [("GDD.md", 170, 180), ("data_schema.md", 180, 190)]),
    (r"skills\.", "头注 UNUSED", "YAML 明定为招式配置参考范围；现行倍率全局红线另行约束，保留文档并标未消费。", "设计参考|指导值|全局.*8,000|max_skill_multiplier", ["data/numbers.yaml", "GDD.md", "CLAUDE.md"], [("data/numbers.yaml", 1051, 1073)]),
    (r"character\.attributes\.distribution_", "待拍板", "未能判定是否保留未来随机生成参数：GDD 正态生成意图与当前静态 profile 分叉。", "正态|character.attributes|未来程序化|静态 profile", ["GDD.md", "CLAUDE.md", "data/numbers.yaml", "docs/spec/rarity_wiring_gap_2026-08-07.md"], [("GDD.md", 209, 213), ("CLAUDE.md", 564, 564), ("data/numbers.yaml", 1111, 1114), ("docs/spec/rarity_wiring_gap_2026-08-07.md", 113, 121)]),
    (r"character\.attributes\.", "保留（有合同）", "属性上下限及不可重 roll 有设计合同；当前实现该规则不等于读取本字段。", "单项属性范围|rerollable|16-24|1-10|不可重 roll", ["CLAUDE.md", "GDD.md", "docs/spec/rarity_wiring_gap_2026-08-07.md"], [("CLAUDE.md", 564, 564), ("docs/spec/rarity_wiring_gap_2026-08-07.md", 115, 121)]),
    (r"character\.adventure_", "头注 UNUSED", "原注释已说明仅设计参考，单次加点由独立奇遇 outcome 配置承担。", "bonus_per_event|attributeDelta", ["data/numbers.yaml", "data/encounters.yaml"], [("data/numbers.yaml", 1140, 1149)]),
    (r"retreat\.", "头注 UNUSED", "固定传统时辰的文档锚；代码按 period 与时钟规则实现，不读取该时间数组或 null。", "time_range|子时|正午", ["data/numbers.yaml", "GDD.md", "data_schema.md"], [("data/numbers.yaml", 1371, 1388), ("GDD.md", 542, 547)]),
    (r"tower\.", "待拍板", "未能判定旧段去留：旧三十层、每日限制或云同步锚与当前四十九层及本地榜合同分叉。", "每天 5 次|每日 5 次|1:1 锚死|Boss 位 14|当前本地榜|接线或删除需拍板", ["GDD.md", "data_schema.md", "data/numbers.yaml"], [("GDD.md", 603, 607), ("data_schema.md", 1253, 1255), ("data/numbers.yaml", 1487, 1497)]),
    (r"inheritance\.unlock_rules\.(can_take_disciple_at|disciple_can_take_grand_disciple_at)", "待拍板", "未能判定旧收徒境界门槛去留：文档解锁合同与当前剧情事件准入分叉。", "can_take_disciple_at|徒孙|一流|绝顶", ["data/recruit_candidates.yaml", "GDD.md"], [("data/recruit_candidates.yaml", 1, 4), ("GDD.md", 499, 505), ("data/numbers.yaml", 1565, 1581)]),
    (r"inheritance\.", "头注 UNUSED", "旧传承字段是重复语义锚；活配置已在飞升或装备段，删除仍需单独批准。", "can_pass_legacy_at|重复声明|resonance_retention|auto_buff_internal_force_max|internal_force_max_bonus|inheritance_retention", ["data/numbers.yaml"], [("data/numbers.yaml", 1574, 1577), ("data/numbers.yaml", 1591, 1600), (NC, 404, 437), (NC, 807, 833)]),
    (r"synergies\.", "待拍板", "未能判定旧相生段去留：已标历史残留，但 GDD 五组效果与 schema 旧结构仍有合同，须明确主从。", "阴阳调和|丐帮传承|少林正宗|武当圆融|华山合璧|effectType|effectValue|multipliers", ["GDD.md", "data_schema.md", "data/synergies.yaml"], [("GDD.md", 272, 282), ("data_schema.md", 1700, 1705), ("data/numbers.yaml", 1623, 1629)]),
    (r"validation_examples\.", "头注 UNUSED", "手工公式战例；原文要求人工重算且测试值独立手写，不冒充自动验证。", "validation_examples|战例|纯文档", ["data/numbers.yaml", "docs/_archive/phase1_tasks.md"], [("data/numbers.yaml", 1661, 1671)]),
]

PARENTS = [
    "meta", "damage_formula", "combat|final_damage_formula", "equipment|tiers",
    "enhancement|success_curve|_fallbackFormula", "resonance|stages",
    "techniques|tiers|_parseTechniqueSpeedBonus", "skills|skillDefs", "character|rarity|adventure_attribute_bonus",
    "timeOfDayBonus|time_of_day_bonus|ziShi|zhengWu", "tower|towerDefs|towers", "inheritance|heritageItems|heritage_items",
    "synergies|synergyDefs", "validation_examples|raw",
]

SLICES = [
    [(NC, 345, 354)], [(NC, 2429, 2435)], [(NC, 1361, 1398)],
    [(NC, 376, 386), (GR, 219, 232)], [(NC, 922, 940), (NC, 990, 1010)],
    [(NC, 404, 419), (NC, 619, 645)], [(NC, 553, 561)], [(GR, 219, 240)],
    [(NC, 492, 507)], [(NC, 2847, 2868), (NC, 2912, 2918)],
    [(GR, 219, 227), (GR, 270, 277)], [(NC, 428, 437), (NC, 807, 833)],
    [(GR, 369, 382)], [(NC, 537, 542)],
]


def cell(value):
    return str(value).replace("|", "\\|").replace("\n", "<br>")


class Evidence:
    def __init__(self, root):
        self.root, self.items, self.cache = root, [], {}
        self.prefetched = {}

    def prefetch(self, commands):
        """并发只读历史检索，证据编号仍由主线程首次使用顺序决定。"""
        unique = list(dict.fromkeys(tuple(cmd) for cmd in commands))
        def read(cmd):
            return subprocess.run(cmd, cwd=self.root, capture_output=True, text=True)
        with ThreadPoolExecutor(max_workers=4) as pool:
            self.prefetched.update(zip(unique, pool.map(read, unique)))

    def run(self, args):
        key = tuple(args)
        if key not in self.cache:
            p = self.prefetched.pop(key, None)
            if p is None:
                p = subprocess.run(args, cwd=self.root, capture_output=True, text=True)
            allowed = (0, 1) if args[0] == "rg" else (0,)
            if p.returncode not in allowed or p.stderr:
                raise RuntimeError(f"命令失败：{shlex.join(args)}\n{p.stderr}")
            item = {"id": f"Q{len(self.items) + 1:03}", "command": shlex.join(args),
                    "exit": p.returncode, "count": len(p.stdout.splitlines()), "output": p.stdout.rstrip("\n")}
            self.items.append(item)
            self.cache[key] = item
        return self.cache[key]

    def rg(self, pattern, paths, fixed=False, globs=()):
        args = ["rg", "-n", "--with-filename", "--no-heading", "--sort", "path"]
        if fixed:
            args += ["-F"]
        for glob in globs:
            args += ["--glob", glob]
        return self.run(args + ["--", pattern] + paths)

    def sed(self, file, start, end):
        return self.run(["sed", "-n", f"{start},{end}p", file])


def ref(q):
    return f"[{q['id']}](#{q['id'].lower()})={q['count']}"


def locations(q):
    locs = []
    for line in q["output"].splitlines():
        m = re.match(r"([^:]+:\d+):", line)
        if m:
            locs.append(m.group(1))
    return "; ".join(f"`{x}`" for x in dict.fromkeys(locs)) or "无"


def original_keys(root):
    text = (root / ORIGINAL).read_text()
    table = text.split("## 零引用逐条表", 1)[1].split("## 独立复核命令", 1)[0]
    return set(re.findall(r"^\| `([^`]+)` \|", table, re.M))


def original_suggestions(root):
    table = (root / ORIGINAL).read_text().split("## 零引用逐条表", 1)[1].split("## 独立复核命令", 1)[0]
    return {line.split("`", 2)[1]: line.rsplit("|", 2)[1].strip().split("：", 1)[0]
            for line in table.splitlines() if line.startswith("| `")}


def build(root, baseline, include_pool=False):
    data = usage.audit(root, baseline)
    unchanged = subprocess.run(["git", "diff", "--quiet", baseline, "--", "lib", "test", "data", "GDD.md", "CLAUDE.md", "data_schema.md"], cwd=root)
    if unchanged.returncode:
        raise RuntimeError("审计源相对派单基线变化；需重新人工复核，不能复用本单语义结论")
    if not data["lib_baseline_guard"]["passed"]:
        raise RuntimeError("基线保护未通过，禁止沿用逐组排除结论")
    if baseline != usage.BASELINE:
        raise RuntimeError("本单人工语义证据仅审核派单基线；其他基线只可运行基础扫描器")
    ev = Evidence(root)
    zero = [r for r in data["rows"] if r["verdict"] == "零引用"]
    old = original_keys(root)
    current = {r["key"] for r in zero}
    if current != old:
        raise RuntimeError("候选集合变化，必须重新人工审查动态消费与建议后更新生成器")
    common = [
        ev.rg(r"raw\[|\.raw\b|\.entries|\.keys|\.values|forEach\(", [NC, GR]),
        ev.rg(r"\.raw\b|raw\[|numbersRaw\b", ["lib"], globs=("*.dart",)),
        ev.rg(r"\$\{|\$[a-zA-Z_]|\.join\(|\[[a-zA-Z_]\w*\]|_requireKeys", [NC, GR]),
        ev.rg(r"loadTestNumbersSection|path.split|red_lines|deepConvertYaml|extract_leaves", ["lib/data/yaml_loader.dart", "test", "tools/audit/q2_leaf_extract.py", "tools/audit/run_all.py"], globs=("*.dart", "*.py")),
    ]
    factory = ev.sed(NC, 345, 542)
    generic_slices = [(f"{f}:{s}-{e}", ev.sed(f, s, e)) for f, s, e in [
        ("lib/data/yaml_loader.dart", 8, 19), ("test/support/test_data.dart", 1, 18),
        ("test/data/numbers_config_required_keys_test.dart", 113, 130),
        ("tools/audit/q2_leaf_extract.py", 22, 70), ("tools/audit/run_all.py", 69, 76),
    ]]
    history_intents = []
    for sha, meaning in [
        ("fb99985ae0fe1f4ffe08eae4b26b0197d34b21a4", "初始化迁入 data/；本表各完整路径在该文件中首次出现，不能当作设计最初产生时间。"),
        ("13ce2300f0a00be78d2e51e2bfc3d0122e47e4f9", "明确元数据和战例为纯文档、收徒门槛设计与实装分叉、传位门槛存在替代配置。"),
        ("9f59ddc2b64faf28d06c52a26f70ea60e8014f3a", "明确公式开关与固定传统时辰仅作说明，不作为可调运行参数。"),
        ("c1444c9a8f5a077639b2172ce7c3eb3553bff057", "明确单次奇遇属性范围仅供设计参考，实际增量由 outcome 承担。"),
        ("93a8687c4a48a410717346c36fda2358aeba81f2", "明确旧塔段和相生段 UNUSED；保留设计锚，接线或删除需拍板。"),
    ]:
        q = ev.run(["git", "show", "--format=fuller", "--no-ext-diff", "--no-color", sha, "--", "data/numbers.yaml"])
        history_intents.append((meaning, q))
    historical_substrings = ev.run(["git", "log", "-p", "--format=fuller", "--no-ext-diff", "--no-color", baseline,
                                   "-Scultivation_multiplier", "--", "lib"])
    groups = []
    for i, (pattern, name, reason, sources) in enumerate(usage.ZERO_GROUPS):
        q = ev.rg(PARENTS[i], [NC, GR])
        pieces = [(f"{f}:{s}-{e}", ev.sed(f, s, e)) for f, s, e in SLICES[i]]
        exact = [(src, ev.sed(src.rsplit(":", 1)[0], int(src.rsplit(":", 1)[1]), int(src.rsplit(":", 1)[1]))) for src in sources]
        groups.append({"name": name, "reason": reason, "parent": q, "pieces": pieces, "exact": exact,
                       "leaves": sum(bool(re.match(pattern, r["key"])) for r in zero)})

    def review(rows):
        grouped = defaultdict(list)
        for r in rows:
            grouped[r["normalized_key"]].append(r)
        commands = []
        for terminal in dict.fromkeys(r["terminal"] for r in rows):
            commands += [
                ["git", "log", "--oneline", baseline, "-S" + terminal, "--", "lib", "data/numbers.yaml"],
                ["git", "log", "--oneline", baseline, "-S" + terminal, "--", "lib"],
                ["git", "log", "--reverse", "--format=%H %s", baseline, "-S" + terminal, "--", "data/numbers.yaml"],
            ]
        ev.prefetch([cmd for cmd in commands if tuple(cmd) not in ev.cache])
        result = []
        for path, rs in sorted(grouped.items(), key=lambda kv: (min(r["yaml_line"] for r in kv[1]), kv[0])):
            terminal = rs[0]["terminal"]
            one = ev.rg(terminal, ["lib", "test", "tool", "tools"], fixed=True, globs=("*.dart", "*.py", "*.sh"))
            # 同时给出无扩展名过滤的最低命令，避免漏掉脚本 shebang 或无扩展名工具。
            broad = ev.rg(terminal, ["lib", "test", "tool", "tools"], fixed=True)
            fullpath = re.sub(r"\[\]", "", path)
            fragments = [".".join(fullpath.split(".")[i:]) for i in range(len(fullpath.split(".")) - 1)]
            fragment = ev.rg("|".join(re.escape(x) for x in fragments), ["lib", "test", "tool", "tools"], globs=("*.dart", "*.py", "*.sh"))
            three = ev.rg(terminal, ["data", "GDD.md", "CLAUDE.md", "data_schema.md", "docs"], fixed=True, globs=("!docs/audit/numbers_yaml_unused_keys*",))
            four = ev.run(["git", "log", "--oneline", baseline, "-S" + terminal, "--", "lib", "data/numbers.yaml"])
            history_lib = ev.run(["git", "log", "--oneline", baseline, "-S" + terminal, "--", "lib"])
            first = ev.run(["git", "log", "--reverse", "--format=%H %s", baseline, "-S" + terminal, "--", "data/numbers.yaml"])
            first_sha = first["output"].split()[0]
            # 末段首次出现的提交必须真的含完整归一路径，禁止拿同名路径冒充。
            first_source = ev.run(["git", "show", first_sha + ":data/numbers.yaml"])
            source = first_source["output"]
            historical = usage.leaves_with_marks(source)
            first_rows = [r for r in historical if usage.normalize(r["key"]) == path]
            if not first_rows:
                first_sha = "未能判定（末段首次提交未含完整路径）"
            rule = next((r for r in RULES if re.match(r[0], path)), None)
            if rule is None:
                raise RuntimeError("缺少人工语义复核规则：" + path)
            _, suggestion, reason, pattern, paths, slices = rule
            contract = ev.rg(pattern, paths)
            contract_slices = [(f"{f}:{s}-{e}", ev.sed(f, s, e)) for f, s, e in slices]
            gi = next((i for i, g in enumerate(usage.ZERO_GROUPS) if re.match(g[0], rs[0]["key"])), None)
            if gi is None:
                # 弹性尾只选已审计父段但未进入正式候选组的路径，结论更保守。
                suggestion = "待拍板"
                reason = "未能判定：虽满足补捞字面条件，仍缺该父段完整动态消费排除，保留正式待人判。"
            scope = Counter(line.split("/", 1)[0] for line in one["output"].splitlines())
            result.append({"path": path, "leaves": len(rs), "rows": rs, "terminal": terminal,
                           "one": one, "broad": broad, "fragment": fragment, "three": three,
                           "four": four, "history_lib": history_lib, "first": first, "first_sha": first_sha,
                           "first_source": first_source,
                           "first_lines": sorted({r["yaml_line"] for r in first_rows}),
                           "group": gi, "contract": contract, "contract_slices": contract_slices,
                           "suggestion": suggestion, "reason": reason, "scope": dict(scope)})
        return result

    reviewed = review(zero)
    pool = []
    pool_evidence = []
    if include_pool:
        all_terminals = defaultdict(set)
        for r in data["rows"]:
            all_terminals[r["terminal"]].add(r["key"].split(".")[0])
        tops = {r["path"].split(".")[0] for r in reviewed}
        candidates = [r for r in data["rows"] if r["verdict"] == "疑似间接消费需人判"
                      and r["lib_literal_count"] == 0 and len(all_terminals[r["terminal"]]) == 1
                      and r["key"].split(".")[0] in tops]
        # 本弹性尾只补捞已逐条核实的三种装备上界，其他候选不借宽泛前缀直接归类。
        selected = [r for r in candidates if r["normalized_key"] in POOL_PATHS]
        assert {r['normalized_key'] for r in selected} == POOL_PATHS
        pool_evidence = [ev.rg("attack_max", ["lib"], fixed=True), ev.sed(NC, 1928, 1938)]
        pool = review(selected)
        pool_counts = (len({r["normalized_key"] for r in candidates}), len(candidates))
    else:
        pool_counts = None
    totals = {s: {"paths": sum(r["suggestion"] == s for r in reviewed),
                  "leaves": sum(r["leaves"] for r in reviewed if r["suggestion"] == s)} for s in CHOICES}
    assert sum(x["paths"] for x in totals.values()) == data["counts"]["zero_normalized_paths"]
    assert sum(x["leaves"] for x in totals.values()) == data["counts"]["verdicts"]["零引用"]
    return {"scan": data, "evidence": ev.items, "groups": groups, "common": common, "factory": factory,
            "review": reviewed, "pool": pool, "pool_candidates": pool_counts, "totals": totals,
            "pool_evidence": pool_evidence,
            "old_suggestions": original_suggestions(root), "history_intents": history_intents, "generic_slices": generic_slices,
            "historical_substrings": historical_substrings,
            "old": sorted(old), "added": sorted(current - old), "removed": sorted(old - current)}


def render(result):
    d, rows = result["scan"], result["review"]
    c, baseline = d["counts"], d["baseline"]
    lines = ["# numbers.yaml 零引用 key 逐条复核（B2 · 2026-09-17）", "",
             f"基线：`{baseline}`。输入联合 SHA-256：`{d['input_sha256']}`；配置 SHA-256：`{d['numbers_sha256']}`。",
             "", "## B2-1 基线与本次计数", "", "```sh",
             f"python3 tools/audit/numbers_key_usage.py --baseline {baseline}",
             "python3 tools/audit/numbers_unused_keys_review.py --check" + (" --include-pool" if result["pool_candidates"] is not None else ""), "```", "",
             f"标量叶子 **{c['scalar_leaves']}**；归一路径 **{c['normalized_paths']}**；末段名 **{c['unique_terminals']}**。",
             f"基线保护：exit_code `{d['lib_baseline_guard']['exit_code']}` / tracked_paths_match `true` / passed `true`。",
             "", "| 判定 | 本次标量叶子 |", "|---|---:|"]
    lines += [f"| {k} | {v} |" for k, v in c["verdicts"].items()]
    old = result["old"]
    terminals = lambda paths: {re.sub(r"\[\d+\]", "", x).split(".")[-1] for x in paths}
    new_keys = {r["key"] for r in d["rows"] if r["verdict"] == "零引用"}
    lines += ["", "原表对照仅从原表逐条表重新提取 key 集合计数，未转抄原表头部数字；当前判定由扫描器重新实跑。", "",
              "| 零引用口径 | 原表逐条重计 | 本次 | 新增 | 移出 |", "|---|---:|---:|---:|---:|",
              f"| 标量叶子 | {len(old)} | {len(new_keys)} | {len(result['added'])} | {len(result['removed'])} |",
              f"| 归一路径 | {len({usage.normalize(x) for x in old})} | {c['zero_normalized_paths']} | {len({usage.normalize(x) for x in new_keys}-{usage.normalize(x) for x in old})} | {len({usage.normalize(x) for x in old}-{usage.normalize(x) for x in new_keys})} |",
              f"| 末段名 | {len(terminals(old))} | {c['zero_unique_terminals']} | {len(terminals(new_keys)-terminals(old))} | {len(terminals(old)-terminals(new_keys))} |", "",
              "新增零引用清单：" + ("、".join(result["added"]) or "无") + "。移出零引用清单：" + ("、".join(result["removed"]) or "无") + "。",
              "未发现新守卫消费、lib 新引用或排除理由失效导致集合变化。缺值 fail-fast 仍只约束原先显式读取字段；没有把整个父 Map 的所有叶子纳入守卫。",
              "", "## B2-2 建议汇总", "", "| 建议 | 归一路径 | 标量叶子 |", "|---|---:|---:|"]
    lines += [f"| {s} | {v['paths']} | {v['leaves']} |" for s, v in result["totals"].items()]
    lines += ["", "下表每格为“归一路径 / 标量叶子”；数组索引折叠为 []，null 与数组叶子的归一路径分别保留。", "",
              "| 顶级段 | 删除候选 | 头注 UNUSED | 保留（有合同） | 待拍板 | 合计 |", "|---|---:|---:|---:|---:|---:|"]
    for top in dict.fromkeys(r["path"].split(".")[0] for r in rows):
        subset = [r for r in rows if r["path"].split(".")[0] == top]
        cells = []
        for s in CHOICES:
            part = [r for r in subset if r["suggestion"] == s]
            cells.append(f"{len(part)} / {sum(r['leaves'] for r in part)}")
        lines.append(f"| {top} | " + " | ".join(cells) + f" | {len(subset)} / {sum(r['leaves'] for r in subset)} |")
    lines += ["", "### 命中口径与动态消费结论", "",
              "所有命中数均为命令输出行数，含注释；不是出现次数、文件数或运行消费数。①列为 Dart/Python/Shell 末段匹配和路径片段匹配，逐条证据另给不限制扩展名的最低检索。③原始匹配包含 numbers.yaml 自身、历史记录和同名异义项；补充合同检索与原文片段用于区分规则、文档锚和冲突。不能把③任何一行命中都解释为有效合同。",
              "②列给公共搜索 / 父级搜索的原始行数；当前目标路径的实际动态玩法消费未发现（0），证据见十四组 parser 片段。NumbersConfig.raw 只在里程碑授予取值，numbersRaw 另外只交给 realms；其他 raw 局部变量分属动作链与周目等类型，不属于本表候选。插值诊断字符串不当读取。",
              "泛型消费需披露：deepConvertYaml 会递归转换整表；审计脚本会枚举叶子；测试有 loadTestNumbersSection 和 path.split('.')。这些是转换/审计/显式路径测试，当前路径列表不含本表字段，未发现把本表字段接入玩法或守卫的证据。不将泛型搬运等同生产数值消费。",
              "历史首次 SHA 指当前 data/numbers.yaml 路径首次包含完整归一路径；初始化提交从旧位置迁入，不能声称设计首次发明。git log -S 不能排除同数替换或所有历史动态消费；只报告固定基线可达历史的实际检索结果。",
              "审计脚本自身出现 key 会计入①，报告自身按要求排除于③，避免报告生成后污染复跑。新增的恢复点和收据不含候选末段，复跑不变。",
              "", "公共动态命令：" + "；".join(ref(q) for q in result["common"]) + "。完整工厂：" + ref(result["factory"]) + "。",
              "泛型读取原文：" + "；".join(f"`{loc}` {ref(q)}" for loc, q in result["generic_slices"]) + "。", ""]

    def table(items):
        out = ["| 归一路径 | 叶子数 | 值（多叶给首→尾） | YAML 行 | ①末段 / 路径 | ②公共 / 父级 | ③原始 / 合同（文件:行） | ④提交数 / lib 数；首次加入 | 建议 | 理由 |",
               "|---|---:|---|---|---|---|---|---|---|---|"]
        for r in items:
            vals = [x["value"] for x in r["rows"]]
            value = json.dumps(vals[0], ensure_ascii=False)
            if len(vals) > 1:
                value += " → " + json.dumps(vals[-1], ensure_ascii=False)
            yl = ",".join(str(x) for x in sorted({x["yaml_line"] for x in r["rows"]}))
            parent = result["groups"][r["group"]]["parent"] if r["group"] is not None else None
            two = ref(result["common"][0]) + " / " + (ref(parent) if parent else "未能判定")
            out.append("| " + " | ".join([f"`{r['path']}`", str(r["leaves"]), cell(value), yl,
                ref(r["one"]) + " / " + ref(r["fragment"]), two,
                ref(r["three"]) + " / " + ref(r["contract"]) + "；" + locations(r["contract"]),
                ref(r["four"]) + " / " + ref(r["history_lib"]) + f"；`{r['first_sha']}`",
                r["suggestion"], r["reason"]]) + " |")
        return out

    lines += ["## 逐条表（按 YAML 行号升序）", ""] + table(rows)
    lines += ["", "## 对 B-2 原表的更正", "",
              "“误判：实际消费”共 **0 个归一路径 / 0 个叶子**；没有证据支持伪造更正。原表零引用集合保持一致。",
              "建议口径需要更正：原表部分行只依据静态零命中提出删除候选，本表增加合同、设计锚、历史意图后重新分类；建议变化逐行列于下表。旧历史 handoff 将传承旧字段说成活配置，不能据此认定当前实际消费；当前活源在装备或飞升段。", "",
              "| 原表归类 | 本表建议 | 归一路径 | 标量叶子 |", "|---|---|---:|---:|"]
    suggestion_changes = Counter()
    for r in rows:
        old_suggestions = {result['old_suggestions'][x['key']] for x in r["rows"]}
        old_label = "、".join(sorted(old_suggestions))
        suggestion_changes[(old_label, r["suggestion"])] += 1
    for (old_label, suggestion), count in suggestion_changes.items():
        leaves = sum(r["leaves"] for r in rows if r["suggestion"] == suggestion and result['old_suggestions'][r['rows'][0]['key']] == old_label)
        lines.append(f"| {old_label} | {suggestion} | {count} | {leaves} |")
    lines += ["", "## 删除候选", "",
              "本次 **0 条** 满足无规则合同、无设计锚、无待决冲突的删除条件；因此没有可随机抽取的 8 条删除候选，不能为了抽样数量制造候选。",
              "假如未来用户另行批准，当前可下发的 [schema] 删除位置清单为空：yaml 行、data_schema.md 同步段、测试 fixture 引用均无本次获准候选。塔与相生等待决项必须先澄清合同，不能把这一节当作删除授权。",
              "", "## 历史加入与后续意图", "",
              "初始迁入之后未见这些字段的直接消费撤销证据。以下关键 patch 原文可复跑；它们支持设计锚、替代配置与待拍板边界。", ""]
    for meaning, q in result["history_intents"]:
        lines += [f"- {meaning} {ref(q)}。"]
    lines += ["", "唯一非零 lib 历史末段检索为 cultivation_multiplier（3 个提交），实际 patch 都是心魔 main_cultivation_multiplier / sub_cultivation_multiplier 子串，与战例无关：" + ref(result["historical_substrings"]) + "。",
              "", "## 十四组人工排除证据（链 tip 真实行号）", ""]
    for g in result["groups"]:
        lines += ["### " + g["name"], "", f"本次 {g['leaves']} 叶子。{g['reason']} 父级复搜：{ref(g['parent'])}。", ""]
        for loc, q in g["exact"] + g["pieces"]:
            lines += [f"`{loc}`；`{q['command']}`；输出 {q['count']} 行。", "", "```dart", q["output"], "```", ""]
    lines += ["## 逐条证据索引", ""]
    for r in rows + result["pool"]:
        lines += [f"### `{r['path']}`", "", "① " + ref(r["one"]) + f"；分目录 {r['scope']}；不限制扩展名 " + ref(r["broad"]) + "；完整/后缀片段 " + ref(r["fragment"]) + "。",
                  "② 公共 " + "、".join(ref(q) for q in result["common"]) + "；父级 " + (ref(result["groups"][r["group"]]["parent"]) if r["group"] is not None else "未能判定") + "。",
                  "③ 原始 " + ref(r["three"]) + "；合同补查 " + ref(r["contract"]) + "；原文 " + "；".join(f"`{loc}` {ref(q)}" for loc, q in r["contract_slices"]) + "。",
                  "④ " + ref(r["four"]) + "；仅 lib " + ref(r["history_lib"]) + "；当前路径首次查询 " + ref(r["first"]) + "；原文件 " + ref(r["first_source"]) + f"，完整路径已在该提交的 data/numbers.yaml:{','.join(map(str,r['first_lines']))} 核验。", ""]
    if result["pool_candidates"] is not None:
        lines += ["## 附录：待人判池补捞（B2-3）", "",
                  f"在 B2-2 READY 提交 `c579d0766159d4bf875295e1b573bad074750a97` 之后执行。筛选按 lib 末段精确字面量 0、同末段仅一个顶级段、该顶级段已有主体零引用；满足 {result['pool_candidates'][0]} 路径 / {result['pool_candidates'][1]} 叶子，本次挑选并复核 {len(result['pool'])} 路径 / {sum(r['leaves'] for r in result['pool'])} 叶子，其余候选未扩审。正式四类计数完全不变。",
                  "三条均保留（有合同），不新增删除候选。lib 原文命中来自红线上限字段的同名后缀，解析的是另一路径；装备阶模板本身仍没有读取入口。补充排除：" + "；".join(ref(q) for q in result["pool_evidence"]) + "。本附录不把有注释或子串命中的待人判条目提升为正式零引用。", ""] + table(result["pool"])
    lines += ["", "## 命令原文、命中数与完整结果", "",
              "以下输出不截断。rg 退出 1 表示零命中，其他错误直接终止生成；sed 行号由命令及引用给出，git 输出为 commit 证据。含行尾空白的输出以 JSON 字符串数组逐行无损表示，避免把历史 patch 的空白变成本单补丁格式错误；命中数仍按原始输出计。", ""]
    for q in result["evidence"]:
        raw_lines = q["output"].splitlines()
        quoted = any(line != line.rstrip() for line in raw_lines)
        display = json.dumps(raw_lines, ensure_ascii=False, indent=2) if quoted else q["output"]
        lines += [f"<a id=\"{q['id'].lower()}\"></a>", f"### {q['id']}", "", "```sh", q["command"], "```", "",
                  f"命中/输出行数：{q['count']}；退出码：{q['exit']}。", "", "```json" if quoted else "```text", display or "（无输出）", "```", ""]
    lines += ["## 验证与限制", "", "报告只写建议，没有删除或修改任何配置。Flutter test / analyze / format 均 NOT_RUN；本单验证为 Python 实跑、命令证据、确定性复生成及 Git 白名单/补丁检查。",
              "静态检索不能给出所有历史动态执行路径的绝对否定证明；存在规则分叉或未来参数意图的条目已标“未能判定”并留待拍板。本单 READY 仅表示审计产出可独立复核，不表示建议获准实施。", ""]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", default=usage.BASELINE)
    parser.add_argument("--include-pool", action="store_true")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--summary", action="store_true")
    args = parser.parse_args()
    if args.write and args.check:
        parser.error("--write 与 --check 不可同时使用")
    root = Path(__file__).resolve().parents[2]
    result = build(root, args.baseline, args.include_pool)
    output = render(result)
    if args.check:
        if (root / REPORT).read_text() != output:
            raise SystemExit("报告与本次四层复跑不一致")
        print("四层复跑与报告逐字节一致")
    elif args.write:
        (root / REPORT).write_text(output)
    elif not args.summary:
        print(output, end="")
    if args.summary or args.write or args.check:
        print(json.dumps({"counts": result["scan"]["counts"], "suggestions": result["totals"],
                          "added": result["added"], "removed": result["removed"],
                          "pool": len(result["pool"]), "commands": len(result["evidence"]),
                          "report_sha256": hashlib.sha256(output.encode()).hexdigest()}, ensure_ascii=False))


if __name__ == "__main__":
    main()
