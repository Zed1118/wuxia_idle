#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""A1 派单 · 领域实体实例字段声明提取

来源:2026-08-07 A1 审计时写在 /tmp/a1_audit/extract_fields.py 的临时脚本,
P4 单(2026-08-08)入仓。改动仅:ROOT 由写死的 worktree 绝对路径改为
从本文件位置推导仓库根,任何 worktree 里跑结果一致。

做什么:扫描 lib/core/domain/*.dart + lib/features/*/domain/**/*.dart
(排除 *.g.dart),按大括号深度只认类体顶层的实例字段声明,
输出 `(类名, 字段名, 行号, 文件)` TSV。

审计基线(af82baea)实测:classes=102 fields=661 files=102。

用法:
  python3 a1_extract_fields.py            # TSV 打到 stdout
  python3 a1_extract_fields.py -o fields.tsv
"""
import argparse
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# 字段声明正则:行首(可选注解后)的类型 + 字段名 + ; 或 =
FIELD_RE = re.compile(
    r'^\s*(?:final\s+|late\s+)?'
    r'(?:const\s+)?'                      # const 修饰
    r'(?!static\s|get\s|set\s|factory\s)'  # 非 static/getter/setter/factory
    r'([A-Za-z_$][\w$<>?.,\[\]\s]*)'    # 类型(可能多单词如 "List<int>")
    r'\s+'
    r'([A-Za-z_$][\w$]*)'                 # 字段名
    r'\s*[=;].*?;?\s*(?:$|//|/\*)'        # 以 =...; 或 ; 结束(允许尾注释/函数调用)
)
# 注解行(独占一行,前缀 @)
ANNOT_RE = re.compile(r'^\s*@')


def extract(path):
    """返回 [(class_name, field_name, line_no, path)]"""
    out = []
    with open(path, encoding="utf-8") as fh:
        lines = fh.readlines()
    cur_class = None
    brace_depth = 0          # 类体深度
    class_body_started = False
    pending_annot = False    # 上一行是注解
    class_re = re.compile(r'^\s*(?:abstract\s+|sealed\s+|base\s+|final\s+)*(?:class|mixin)\s+([A-Za-z_$][\w$]*)\b')
    for i, raw in enumerate(lines):
        line = raw.rstrip("\n")
        stripped = line.strip()
        # 类定义
        m = class_re.match(line)
        if m and 'class ' in line and not line.strip().startswith('//'):
            cur_class = m.group(1)
            class_body_started = False
            # 找本行 { 之后的深度
            if '{' in line:
                depth = line.count('{') - line.count('}')
                brace_depth = depth
                class_body_started = True
            pending_annot = False
            continue
        if cur_class is None:
            continue
        if not class_body_started:
            if '{' in line:
                brace_depth = line.count('{') - line.count('}')
                class_body_started = True
            else:
                continue
        # 忽略字符串中的大括号不处理(近似,够用)
        if stripped.startswith('//') or stripped.startswith('/*') or stripped.startswith('*/'):
            continue
        if stripped.startswith('@'):
            pending_annot = True
            continue
        # 更新括号深度(先于匹配,该行自身的 { 计入)
        opens = line.count('{') - line.count('}')
        brace_depth += opens
        if brace_depth <= 0 and '}' in line:
            cur_class = None
            class_body_started = False
            brace_depth = 0
            pending_annot = False
            continue
        m = FIELD_RE.match(line)
        if m and brace_depth == 1 and '{' not in line:
            typ = m.group(1).strip()
            fname = m.group(2)
            # 排除方法/构造:类型以 ( 结尾
            if typ.endswith('(') or typ == 'const':
                pending_annot = False
                continue
            # getter/setter 排除
            if re.search(r'\sget\s', line):
                pending_annot = False
                continue
            if fname in ('async', 'sync', 'await', 'return', 'void', 'new', 'this', 'class', 'factory', 'operator', 'hashCode'):
                pending_annot = False
                continue
            out.append((cur_class, fname, i + 1, path))
            pending_annot = False
            continue
        pending_annot = False
        continue
    return out


def domain_files():
    core_domain = os.path.join(ROOT, "lib/core/domain")
    files = sorted(os.listdir(core_domain))
    files = [os.path.join(core_domain, f) for f in files
             if f.endswith(".dart") and not f.endswith(".g.dart")]
    for f in sorted(glob.glob(os.path.join(ROOT, "lib/features/*/domain/**/*.dart"), recursive=True)):
        if f.endswith(".g.dart"):
            continue
        files.append(f)
    return files


def main():
    ap = argparse.ArgumentParser(description="A1 领域实体字段声明提取")
    ap.add_argument('-o', '--out', help='输出文件(默认 stdout)')
    args = ap.parse_args()

    files = domain_files()
    all_fields = []
    for f in files:
        try:
            all_fields.extend(extract(f))
        except Exception as e:
            print(f"ERR {f}: {e}", file=sys.stderr)

    out = open(args.out, 'w', encoding='utf-8') if args.out else sys.stdout
    # 去重(同名类同字段在不同文件罕见,保留)
    print(f"# classes={len(set(c for c, _, _, _ in all_fields))} "
          f"fields={len(all_fields)} files={len(files)}", file=out)
    for c, f, ln, p in all_fields:
        # 输出仓库相对路径,保证任何 worktree 结果一致
        print(f"{c}\t{f}\t{ln}\t{os.path.relpath(p, ROOT)}", file=out)
    if args.out:
        out.close()


if __name__ == '__main__':
    main()
