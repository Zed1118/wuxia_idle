#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""A1 派单 · fields.tsv 形态复核

来源:2026-08-07 A1 审计时写在 /tmp/a1_audit/verify_fields.py 的临时脚本,
P4 单(2026-08-08)入仓。改动:fields.tsv 路径参数化(--fields),
声明路径按仓库相对路径解释。

做什么:逐行验证 fields.tsv 的每条记录在源码里确实长得像字段声明
(非注释、非方法签名、匹配声明形态),输出 bad 计数。

用法:
  python3 a1_verify_fields.py --fields /tmp/a1_run/fields.tsv
"""
import argparse
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

DECL_RE = re.compile(
    r'^\s*(?:@[A-Za-z_]+\s*\(.*?\)\s*)*'   # 行内注解(罕见)
    r'(?:final\s+|late\s+|const\s+)*'
    r'[A-Za-z_$][\w$<>?.,\[\]]*\s+'        # 类型
    r'[A-Za-z_$][\w$]*'                    # 名字
    r'\s*(?:=|;)'                          # 以 = 或 ; 结束
)
METHOD_RE = re.compile(r'^\s*(?:final\s+|late\s+)*[A-Za-z_$][\w$<>?.,\[\]]*\s+[A-Za-z_$][\w$]*\s*\(')  # 方法签名


def main():
    ap = argparse.ArgumentParser(description="A1 fields.tsv 形态复核")
    ap.add_argument('--fields', required=True)
    args = ap.parse_args()

    bad = 0
    ln = 0
    for ln, line in enumerate(open(args.fields, encoding='utf-8'), 1):
        if line.startswith('#'):
            continue
        parts = line.rstrip('\n').split('\t')
        if len(parts) != 4:
            print(f'BAD format line {ln}: {line!r}'); bad += 1; continue
        cls, fname, lineno, path = parts
        try:
            src_line = open(os.path.join(ROOT, path), encoding='utf-8').readlines()[int(lineno) - 1]
        except Exception as e:
            print(f'BAD read {path}:{lineno}: {e}'); bad += 1; continue
        s = src_line.strip()
        if s.startswith('//') or s.startswith('///'):
            print(f'COMMENT {cls}.{fname} {path}:{lineno}: {s[:60]}'); bad += 1; continue
        if METHOD_RE.match(s):
            print(f'METHOD? {cls}.{fname} {path}:{lineno}: {s[:60]}'); bad += 1; continue
        if not DECL_RE.match(s):
            print(f'NOTDECL {cls}.{fname} {path}:{lineno}: {s[:80]}'); bad += 1
    print(f'total lines={ln} bad={bad}')


if __name__ == '__main__':
    main()
