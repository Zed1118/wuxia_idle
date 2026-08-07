#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""A1 派单 · 引用形态读/写分类(无类归属版)

来源:2026-08-07 A1 审计时写在 /tmp/a1_audit/classify.py 的临时脚本,
P4 单(2026-08-08)入仓。改动:fields.tsv / refs_by_field.tsv / 输出
路径参数化(--workdir),不再写死 /tmp;debug 路径判定改为仓库相对前缀。

做什么:对每个字段的引用行做形态分类(声明/读/写/debug/未分类),
输出无生产读(reads=0)的候选字段到 workdir/candidates.txt。

用法:
  python3 a1_classify.py --workdir /tmp/a1_run
"""
import argparse
import os
import re
from collections import defaultdict


def is_debug_path(f):
    return 'lib/features/debug/' in f


def classify_refs(reflist, fname):
    """把引用行列表分成 (decls, reads, writes, debugs, unclassified)。

    与 2026-08-07 审计 classify.py 完全同判据:
      - 注释/文档行不算引用
      - 声明形态:`[final|late|const] Type fname [=;]`
      - debug 路径单列
      - 读形态:`.fname`(非赋值)/ fnameEqualTo / sortByFname / get fname
      - 写形态:`.fname =` / `fname:`(命名参数)
    """
    reads, writes, debugs, decls, unclassified = [], [], [], [], []
    for f, ln, txt in reflist:
        if txt.strip().startswith(('//', '/*', '*/', '*')):
            continue  # 注释/文档行不算引用
        decl_re = re.compile(r'^\s*(?:@\w+(?:\([^)]*\))?\s*)*(?:final\s+|late\s+|const\s+)*[A-Za-z_$][\w$<>?.,\[\]\s]*\s' + re.escape(fname) + r'\s*[=;]')
        if decl_re.match(txt):
            decls.append((f, ln, txt))
            continue
        if is_debug_path(f):
            debugs.append((f, ln, txt))
            continue
        # 读形态
        read_pat = re.compile(r'(?<!this)(?:\.|\.\.\s*)\s*' + re.escape(fname) + r'(?!\s*[+\-*/%&|^]?=(?![=!<>]))|' +
                              re.escape(fname) + r'EqualTo\b|sortBy' + re.escape(fname[:1].upper() + fname[1:]) + r'\b|' +
                              r'get\s+' + re.escape(fname) + r'\b')
        write_pat = re.compile(r'(?:\.|\.\.)\s*' + re.escape(fname) + r'\s*=(?!=)|' +
                               re.escape(fname) + r'\s*:')
        if read_pat.search(txt):
            reads.append((f, ln, txt))
        elif write_pat.search(txt):
            writes.append((f, ln, txt))
        else:
            # 裸名出现(可能读可能写可能无关)
            unclassified.append((f, ln, txt))
    return decls, reads, writes, debugs, unclassified


def parse_refs(refs_path):
    """解析 refs_by_field.tsv。返回 {(cls,fname): [(file, lineno, text)]}。"""
    refs = defaultdict(list)
    cur = None
    for line in open(refs_path, encoding='utf-8'):
        line = line.rstrip('\n')
        if line.startswith('  '):
            parts = line.strip('\t').split('\t', 1)
            loc, txt = parts[0], parts[1] if len(parts) > 1 else ''
            f, ln = loc.rsplit(':', 1)
            refs[cur].append((f, int(ln), txt))
        else:
            p = line.split('\t')
            cur = (p[0], p[1])
    return refs


def main():
    ap = argparse.ArgumentParser(description="A1 引用形态分类")
    ap.add_argument('--workdir', required=True)
    args = ap.parse_args()

    refs = parse_refs(os.path.join(args.workdir, 'refs_by_field.tsv'))

    results = []
    for (cls, fname), reflist in refs.items():
        decls, reads, writes, debugs, unclassified = classify_refs(reflist, fname)
        results.append((cls, fname, decls, reads, writes, debugs, unclassified))

    # 输出:无生产读(reads 为空)的字段
    n_no_read = 0
    out_lines = []
    for cls, fname, decls, reads, writes, debugs, unclassified in results:
        if not reads:
            n_no_read += 1
            out_lines.append(f"### {cls}.{fname}  (reads=0, writes={len(writes)}, decls={len(decls)}, debug={len(debugs)}, uncls={len(unclassified)})")
            for tag, lst in (('W', writes), ('D', debugs), ('U', unclassified)):
                for f, ln, txt in lst:
                    out_lines.append(f"  [{tag}] {f}:{ln}\t{txt[:160]}")
    print(f"无生产读字段数: {n_no_read} / {len(results)}")
    out_path = os.path.join(args.workdir, 'candidates.txt')
    open(out_path, 'w', encoding='utf-8').write('\n'.join(out_lines))
    print(f"written {out_path}")


if __name__ == '__main__':
    main()
