#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""A1 派单 · 全库引用枚举

来源:2026-08-07 A1 审计时写在 /tmp/a1_audit/refs.py 的临时脚本,
P4 单(2026-08-08)入仓。改动:
  1. ROOT 由写死的 worktree 绝对路径改为从本文件位置推导仓库根;
  2. fields.tsv / refs_by_field.tsv 路径参数化(--workdir),不再写死 /tmp;
  3. fields.tsv 内路径按仓库相对路径解释(与 a1_extract_fields.py 输出一致)。

做什么:对每个 (类, 字段) 声明,在全部非 *.g.dart 的 dart 文件里做词边界
匹配,产出该字段的全部引用位置,写 refs_by_field.tsv:
  header 行:`类\t字段\t引用数\t声明位置`
  引用行  :`  文件:行号\t行文本(截断 150 字符)`

用法:
  python3 a1_refs.py --workdir /tmp/a1_run [--fields fields.tsv]
"""
import argparse
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def all_dart_files():
    out = []
    for root, dirs, files in os.walk(os.path.join(ROOT, "lib")):
        for f in files:
            if f.endswith(".dart") and not f.endswith(".g.dart"):
                out.append(os.path.join(root, f))
    return out


def main():
    ap = argparse.ArgumentParser(description="A1 全库引用枚举")
    ap.add_argument('--workdir', required=True, help='中间产物目录')
    ap.add_argument('--fields', default=None, help='fields.tsv 路径(默认 workdir/fields.tsv)')
    args = ap.parse_args()

    fields_path = args.fields or os.path.join(args.workdir, 'fields.tsv')
    refs_path = os.path.join(args.workdir, 'refs_by_field.tsv')

    files = all_dart_files()
    print(f"# files={len(files)}")

    # 行索引:file -> [(lineno, text)]
    index = {}
    for f in files:
        with open(f, encoding="utf-8") as fh:
            index[f] = list(enumerate(fh.readlines(), 1))

    # 读取字段表(第 4 列为仓库相对路径)
    fields = []
    for line in open(fields_path, encoding="utf-8"):
        if line.startswith('#'):
            continue
        p = line.rstrip("\n").split("\t")
        if len(p) == 4:
            fields.append(p)
    print(f"# fields={len(fields)}")

    # 对每个字段名:grep 所有文件(按字段名缓存,同名共享)
    name_re_cache = {}

    def find_refs(fname):
        """返回 [(file, lineno, text)]"""
        if fname in name_re_cache:
            return name_re_cache[fname]
        pat = re.compile(r"\b" + re.escape(fname) + r"\b")
        refs = []
        for f in files:
            for lineno, text in index[f]:
                if pat.search(text):
                    refs.append((f, lineno, text.rstrip("\n")))
        name_re_cache[fname] = refs
        return refs

    out = open(refs_path, "w", encoding="utf-8")
    for cls, fname, lineno, path in fields:
        refs = find_refs(fname)
        out.write(f"{cls}\t{fname}\t{len(refs)}\t{path}:{lineno}\n")
        for f, ln, txt in refs:
            out.write(f"  {os.path.relpath(f, ROOT)}:{ln}\t{txt[:150]}\n")
    out.close()
    print(f"done -> {refs_path}")


if __name__ == '__main__':
    main()
