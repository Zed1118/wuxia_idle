#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/audit/run_all.py — Q2/A1 审计五计数复跑入口

派单:docs/dispatch/2026-08-08_P4_audit_scripts.md 对应的 P4 单。
目的:让 2026-08-07 Q2(config bypass)与 A1(dead fields)两份报告
的五个关键计数能被任何人一条命令复跑:

  Q2 背离(confirmed)= 8(报告值,基线 af82baea)
  Q2 部分背离        = 7
  Q2 休眠配置        = 21(已解析零 caller)
  A1 只写不读        = 44
  A1 仅 debug/test 读 = 14

方法(与报告判据一致,见 audit_anchors.py):
  - 机械底座:q2_leaf_extract(yaml 叶字段)、q2_field_usage(loader final
    字段 + 业务侧零引用筛)、a1_extract_fields(领域字段声明)。
  - 结论复验:报告主表逐条落成锚点(audit_anchors.py),对**当前代码**
    复验每条结论是否仍成立——Q2 用"业务侧 `.prop` 零读 + 硬编码证据仍在",
    A1 用原审计同一套读写形态分类 + 类上下文归属(a1_classify_owned.
    filter_owned)。计数 = 仍成立的条数。main 前进导致结论失效(如稀有度
    收口)时计数如实变化,差异在输出明细里逐条给出。

只用 Python 3 标准库。中间产物不落仓库(默认 tempdir)。

用法:
  python3 tools/audit/run_all.py           # 人读输出(五计数 + 明细)
  python3 tools/audit/run_all.py --json    # 结构化输出(供 diff 比对)
  python3 tools/audit/run_all.py --full    # 追加跑全量 A1 管道(慢,分钟级)
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)

import audit_anchors as A                       # noqa: E402
import q2_leaf_extract                          # noqa: E402
import q2_field_usage                           # noqa: E402
import a1_extract_fields                        # noqa: E402
import a1_classify_owned as owned               # noqa: E402

REPORT = {  # 报告值(2026-08-07 基线 af82baea)
    "q2_confirmed": 8,
    "q2_partial": 7,
    "q2_dormant": 21,
    "a1_write_only": 44,
    "a1_debug_test_only": 14,
}

# --------------------------------------------------------------------------
# Q2 侧
# --------------------------------------------------------------------------

def q2_base():
    """机械底座:叶字段总数 + loader final 字段 + 业务侧零引用候选。"""
    yamls = sorted(
        os.path.join('data', f) for f in os.listdir(os.path.join(ROOT, 'data'))
        if f.endswith('.yaml'))
    leaves_total = 0
    numbers_leaves = 0
    for y in yamls:
        n = len(q2_leaf_extract.extract(os.path.join(ROOT, y)))
        leaves_total += n
        if y.endswith('numbers.yaml'):
            numbers_leaves = n
    all_fields, usage = q2_field_usage.run()
    zero = [name for name, hits in usage.items() if not hits]
    return {
        "top_config_yaml": len(yamls),
        "leaves_total": leaves_total,
        "numbers_leaves": numbers_leaves,
        "typed_fields": len(all_fields),
        "zero_ref_candidates": len(zero),
        "zero_ref_names": sorted(zero),
    }


def _biz_reads(prop: str) -> list[str]:
    return q2_field_usage.grep_count(r'\.' + re.escape(prop) + r'\b')


def _anchor_present(rel_path: str, regex: str) -> bool:
    p = os.path.join(ROOT, rel_path)
    if not os.path.exists(p):
        return False
    with open(p, encoding='utf-8') as f:
        return re.search(regex, f.read(), re.MULTILINE) is not None


def q2_verify() -> dict:
    confirmed, partial, dormant = [], [], []

    for e in A.Q2_CONFIRMED:
        reads = {p: _biz_reads(p) for p in e["properties"]}
        zeros_ok = all(not v for v in reads.values())
        anchor_detail = [(f, r, _anchor_present(f, r)) for f, r in e["anchors"]]
        anchors_ok = all(ok for _, _, ok in anchor_detail)
        holds = zeros_ok and anchors_ok
        confirmed.append({
            "id": e["id"], "title": e["title"], "holds": holds,
            "prop_reads": {k: len(v) for k, v in reads.items()},
            "anchors": [{"file": f, "regex": r, "present": ok}
                        for f, r, ok in anchor_detail],
        })

    for e in A.Q2_PARTIAL:
        reads = {p: _biz_reads(p) for p in e["properties"]}
        holds = all(not v for v in reads.values())
        partial.append({
            "id": e["id"], "title": e["title"], "holds": holds,
            "prop_reads": {k: len(v) for k, v in reads.items()},
        })

    for e in A.Q2_DORMANT:
        prop, loader = e["prop"], e["loader"]
        reads = _biz_reads(prop)
        loader_ok = _anchor_present(loader, r'\b' + re.escape(prop) + r'\b')
        dormant.append({
            "id": e["id"], "prop": prop,
            "holds": (not reads) and loader_ok,
            "reads": len(reads), "loader_present": loader_ok,
        })

    return {
        "confirmed": confirmed,
        "partial": partial,
        "dormant": dormant,
        "count_confirmed": sum(1 for e in confirmed if e["holds"]),
        "count_partial": sum(1 for e in partial if e["holds"]),
        "count_dormant": sum(1 for e in dormant if e["holds"]),
    }


# --------------------------------------------------------------------------
# A1 侧
# --------------------------------------------------------------------------

def _lib_lines():
    """lib/ 全部非 .g.dart dart 文件行索引 {相对路径: [(行号, 文本)]}。"""
    idx = {}
    for root, dirs, files in os.walk(os.path.join(ROOT, 'lib')):
        for f in files:
            if f.endswith('.dart') and not f.endswith('.g.dart'):
                p = os.path.join(root, f)
                rel = os.path.relpath(p, ROOT)
                with open(p, encoding='utf-8') as fh:
                    idx[rel] = list(enumerate(fh.readlines(), 1))
    return idx


def _test_lines():
    idx = {}
    tdir = os.path.join(ROOT, 'test')
    if not os.path.isdir(tdir):
        return idx
    for root, dirs, files in os.walk(tdir):
        for f in files:
            if f.endswith('.dart'):
                p = os.path.join(root, f)
                rel = os.path.relpath(p, ROOT)
                with open(p, encoding='utf-8') as fh:
                    idx[rel] = list(enumerate(fh.readlines(), 1))
    return idx


def _refs_of(fname: str, index: dict) -> list[str]:
    """词边界匹配,返回 `相对路径:行号\t文本` 行列表(与 a1_refs 同形态)。"""
    pat = re.compile(r'\b' + re.escape(fname) + r'\b')
    out = []
    for rel, lines in index.items():
        for ln, text in lines:
            if pat.search(text):
                out.append(f"{rel}:{ln}\t{text.rstrip()[:150]}")
    return out


def _is_debug(rel_path: str) -> bool:
    return rel_path.startswith('lib/features/debug/')


def _is_test(rel_path: str) -> bool:
    return rel_path.startswith('test/')


def a1_base() -> dict:
    files = a1_extract_fields.domain_files()
    all_fields = []
    for f in files:
        all_fields.extend(a1_extract_fields.extract(f))
    return {
        "domain_files": len(files),
        "classes": len(set(c for c, _, _, _ in all_fields)),
        "fields": len(all_fields),
    }


def _loose_dt_reads(fname: str, cls: str, test_idx: dict, lib_idx: dict,
                    files_src: dict) -> tuple[int, list[str]]:
    """debug/test 读的兜底判据:文件含类名 + 行是读形态(排除声明/写)。

    test/debug 里变量常无类型注解(如 `expect(save.x, …)`),严格归属会漏;
    放宽为"文件提及该类即归属",只用于 A/B 档归类,不影响生产读判定。
    """
    rp = owned.make_read_pat(fname)
    dp = owned.make_decl_re(fname)
    wp = owned.make_write_pat(fname)
    name_pat = re.compile(r'\b' + re.escape(fname) + r'\b')
    cls_pat = re.compile(r'\b' + re.escape(cls) + r'\b')
    n = 0
    sites: list[str] = []
    for is_test_idx, idx in ((True, test_idx), (False, lib_idx)):
        for rel, lines in idx.items():
            if not is_test_idx and not _is_debug(rel):
                continue
            content = files_src.get(rel)
            if content is None or not cls_pat.search(''.join(content)):
                continue
            for ln, text in lines:
                t = text.rstrip()
                if t.strip().startswith(('//', '/*', '*/', '*')):
                    continue
                if not name_pat.search(t):
                    continue
                if dp.match(t) or wp.search(t):
                    continue
                if rp.search(t):
                    n += 1
                    sites.append(f"{rel}:{ln}\t{t[:120]}")
    return n, sites


def a1_verify() -> dict:
    files_src = owned.load_source_lines()
    lib_idx = _lib_lines()
    test_idx = _test_lines()
    lib_cache: dict[str, list[str]] = {}

    def lib_refs(fname):
        if fname not in lib_cache:
            lib_cache[fname] = _refs_of(fname, lib_idx)
        return lib_cache[fname]

    def verify_one(cls, fname, decl_file, sites=None):
        detail = {"class": cls, "field": fname, "decl_file": decl_file}
        # 声明仍在?(按文件含字段名近似核验,行号漂移不致命)
        decl_path = os.path.join(ROOT, decl_file)
        decl_ok = os.path.exists(decl_path) and re.search(
            r'\b' + re.escape(fname) + r'\b',
            open(decl_path, encoding='utf-8').read()) is not None
        detail["decl_present"] = decl_ok
        if not decl_ok:
            detail.update(prod_reads=0, debug_reads=0, test_reads=0,
                          debug_test_reads_loose=0, sites_ok=None,
                          status="decl_missing", holds=False)
            return detail

        # 生产读:全 lib(含 debug,与 classify_owned 口径一致)归属过滤后读形态
        decls, reads, writes, uncls = owned.filter_owned(lib_refs(fname), cls, fname, files_src)
        prod_reads = [l for l in reads if not _is_debug(l.split(':', 1)[0])]
        debug_reads = [l for l in reads if _is_debug(l.split(':', 1)[0])]

        # debug/test 读:test 侧同样走归属过滤;再加"文件含类名"兜底
        test_lines = _refs_of(fname, test_idx)
        _, test_reads, _, _ = owned.filter_owned(test_lines, cls, fname, files_src)
        loose_n, loose_sites = _loose_dt_reads(fname, cls, test_idx, lib_idx, files_src)
        dt_total = len(debug_reads) + len(test_reads) + loose_n

        # 报告引证的 debug/test 读取点是否仍在(文件含该字段名,容忍行漂)
        sites_ok = None
        if sites is not None:
            sites_ok = False
            for s in sites:
                sp = os.path.join(ROOT, s)
                if os.path.exists(sp) and re.search(
                        r'\b' + re.escape(fname) + r'\b',
                        open(sp, encoding='utf-8').read()):
                    sites_ok = True
                    break

        detail.update(
            prod_reads=len(prod_reads),
            debug_reads=len(debug_reads),
            test_reads=len(test_reads),
            debug_test_reads_loose=loose_n,
            sites_ok=sites_ok,
            prod_read_sites=prod_reads[:5],
            debug_test_read_sites=(debug_reads + test_reads + loose_sites)[:5],
        )
        if prod_reads:
            detail["status"] = "has_prod_read"
        elif dt_total or sites_ok:
            detail["status"] = "debug_test_only"
        else:
            detail["status"] = "write_only"
        return detail

    # 表 A 判据(A1 报告 §2):全 lib(排除 *.g.dart/features/debug/test)零读取
    # —— debug/test 读不影响归档(报告口径如此,如 criticalMultiplier 有 test 读仍归 A)
    table_a = [verify_one(c, f, d) for c, f, d in A.A1_TABLE_A]
    for d in table_a:
        d["holds"] = d["status"] in ("write_only", "debug_test_only")
    # 表 B 判据(A1 报告 §3):生产零读 AND debug/test 读点仍在
    table_b = [verify_one(c, f, d, sites) for c, f, d, sites in A.A1_TABLE_B]
    for d in table_b:
        d["holds"] = d["status"] == "debug_test_only"
    doubtful = [verify_one(c, f, d) for c, f, d in A.A1_DOUBTFUL]

    count_a = sum(1 for d in table_a if d["holds"])
    count_b = sum(1 for d in table_b if d["holds"])
    return {
        "table_a": table_a,
        "table_b": table_b,
        "doubtful": doubtful,
        "count_write_only": count_a,
        "count_debug_test_only": count_b,
    }


# --------------------------------------------------------------------------
# --full:全量 A1 管道(慢)
# --------------------------------------------------------------------------

def a1_full_pipeline() -> dict:
    with tempfile.TemporaryDirectory(prefix='a1_audit_') as wd:
        fields_tsv = os.path.join(wd, 'fields.tsv')
        e = subprocess.run([sys.executable, os.path.join(HERE, 'a1_extract_fields.py'),
                            '-o', fields_tsv], check=True, cwd=ROOT,
                           capture_output=True, text=True)
        with open(fields_tsv, encoding='utf-8') as fh:
            extract_header = fh.readline().strip()
        subprocess.run([sys.executable, os.path.join(HERE, 'a1_refs.py'),
                        '--workdir', wd], check=True, cwd=ROOT)
        c1 = subprocess.run([sys.executable, os.path.join(HERE, 'a1_classify.py'),
                             '--workdir', wd], check=True, cwd=ROOT,
                            capture_output=True, text=True)
        c2 = subprocess.run([sys.executable, os.path.join(HERE, 'a1_classify_owned.py'),
                             '--workdir', wd], check=True, cwd=ROOT,
                            capture_output=True, text=True)
        n_candidates = sum(1 for line in open(os.path.join(wd, 'candidates.txt'),
                                              encoding='utf-8')
                           if line.startswith('### '))
        first = lambda s: s.strip().splitlines()[0] if s.strip() else ""
        return {
            "extract": extract_header,
            "classify_no_read": first(c1.stdout),
            "classify_owned": first(c2.stdout),
            "candidates": n_candidates,
        }


# --------------------------------------------------------------------------
# 输出
# --------------------------------------------------------------------------

def gather(full: bool) -> dict:
    head = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'], cwd=ROOT,
                          capture_output=True, text=True).stdout.strip()
    q2b = q2_base()
    q2v = q2_verify()
    a1b = a1_base()
    a1v = a1_verify()
    counts = {
        "Q2 背离(confirmed)": q2v["count_confirmed"],
        "Q2 部分背离": q2v["count_partial"],
        "Q2 休眠配置(已解析零 caller)": q2v["count_dormant"],
        "A1 只写不读": a1v["count_write_only"],
        "A1 仅 debug/test 读": a1v["count_debug_test_only"],
    }
    out = {
        "head": head,
        "counts": counts,
        "report_values": {
            "Q2 背离(confirmed)": 8,
            "Q2 部分背离": 7,
            "Q2 休眠配置(已解析零 caller)": 21,
            "A1 只写不读": 44,
            "A1 仅 debug/test 读": 14,
        },
        "q2_base": {k: v for k, v in q2b.items() if k != "zero_ref_names"},
        "q2_zero_ref_candidates": q2b["zero_ref_candidates"],
        "a1_base": a1b,
        "q2_detail": q2v,
        "a1_detail": a1v,
    }
    if full:
        out["a1_full_pipeline"] = a1_full_pipeline()
    return out


def fmt_human(out: dict) -> str:
    lines = []
    lines.append("=" * 62)
    lines.append("Q2/A1 审计五计数复跑(HEAD %s)" % out["head"])
    lines.append("=" * 62)
    lines.append("")
    lines.append("五个计数(复跑值 = 仍成立的报告结论条数):")
    for name, val in out["counts"].items():
        rep = out["report_values"][name]
        mark = "✓" if val == rep else "△"
        lines.append(f"  {name} = {val}    (报告值 {rep}) {mark}")
    lines.append("")

    qb = out["q2_base"]
    lines.append("Q2 机械底座:")
    lines.append(f"  顶层 config yaml 数        = {qb['top_config_yaml']}")
    lines.append(f"  叶字段总数                 = {qb['leaves_total']}"
                 f"(numbers.yaml {qb['numbers_leaves']})")
    lines.append(f"  强类型配置字段数           = {qb['typed_fields']}")
    lines.append(f"  业务侧零引用候选数         = {qb['zero_ref_candidates']}")
    ab = out["a1_base"]
    lines.append("A1 机械底座:")
    lines.append(f"  领域文件数 = {ab['domain_files']}  类数 = {ab['classes']}"
                 f"  字段数 = {ab['fields']}")
    lines.append("")

    q2v = out["q2_detail"]
    lines.append("Q2 背离(confirmed)明细:")
    for e in q2v["confirmed"]:
        flag = "成立" if e["holds"] else "失效"
        lines.append(f"  [{flag}] {e['id']} {e['title']}")
        for p, n in e["prop_reads"].items():
            lines.append(f"         业务读 .{p} = {n}")
        for a in e["anchors"]:
            lines.append(f"         证据 {a['file']}  {'仍在' if a['present'] else '已消失'}")
    lines.append("")
    lines.append("Q2 部分背离明细:")
    for e in q2v["partial"]:
        flag = "成立" if e["holds"] else "失效"
        reads = ", ".join(f".{p}={n}" for p, n in e["prop_reads"].items())
        lines.append(f"  [{flag}] {e['id']} {e['title']}  ({reads})")
    lines.append("")
    lines.append("Q2 休眠配置明细(仅列失效项;成立共 %d 条):" % q2v["count_dormant"])
    broken = [e for e in q2v["dormant"] if not e["holds"]]
    if not broken:
        lines.append("  (全部成立)")
    for e in broken:
        lines.append(f"  [失效] {e['id']} .{e['prop']}  业务读={e['reads']}"
                     f"  loader={'在' if e['loader_present'] else '消失'}")
    lines.append("")

    a1v = out["a1_detail"]
    lines.append("A1 主表 A(只写不读,判据=生产零读)复验:")
    for d in a1v["table_a"]:
        if d["holds"]:
            continue
        lines.append(f"  [失效] {d['class']}.{d['field']} -> {d['status']}"
                     f"  (生产读 {d['prod_reads']} / debug 读 {d['debug_reads']}"
                     f" / test 读 {d['test_reads']})")
        for s in d.get("prod_read_sites", [])[:3]:
            lines.append(f"         {s[:120]}")
    n_ok_a = sum(1 for d in a1v["table_a"] if d["holds"])
    lines.append(f"  其余 {n_ok_a} 条仍为生产零读")
    lines.append("A1 主表 B(仅 debug/test 读,判据=生产零读+读点仍在)复验:")
    for d in a1v["table_b"]:
        if d["holds"]:
            continue
        lines.append(f"  [失效] {d['class']}.{d['field']} -> {d['status']}"
                     f"  (生产读 {d['prod_reads']} / debug 读 {d['debug_reads']}"
                     f" / test 读 {d['test_reads']} / 引证站点={'在' if d['sites_ok'] else '失'})")
    n_ok_b = sum(1 for d in a1v["table_b"] if d["holds"])
    lines.append(f"  其余 {n_ok_b} 条仍为仅 debug/test 读")
    for d in a1v["doubtful"]:
        lines.append(f"  [存疑项复核] {d['class']}.{d['field']} -> {d['status']}")
    lines.append("")

    if "a1_full_pipeline" in out:
        lines.append("A1 全量管道(--full):")
        for k, v in out["a1_full_pipeline"].items():
            lines.append(f"  {k}: {v}")
        lines.append("")
    return "\n".join(lines)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="Q2/A1 审计五计数复跑入口")
    ap.add_argument('--json', action='store_true', help='结构化 JSON 输出')
    ap.add_argument('--full', action='store_true',
                    help='追加跑全量 A1 管道(extract→refs→classify→owned,分钟级)')
    args = ap.parse_args(argv)

    out = gather(full=args.full)
    if args.json:
        print(json.dumps(out, ensure_ascii=False, indent=2))
    else:
        print(fmt_human(out))
    return 0


if __name__ == '__main__':
    sys.exit(main())
