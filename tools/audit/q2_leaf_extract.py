#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Q2 派单 · YAML 叶子字段提取器

来源:2026-08-07 Q2 审计时写在 /tmp/q2/leaf_extract.py 的临时脚本,
P4 单(2026-08-08)原样入仓(仅补本文件头与 main 守卫)。

按缩进解析单个 YAML 文件(轻量正则实现,不依赖 PyYAML),
产出每个标量叶子:(点分路径, 值, 行号)。

列表项:`parent[].key` / `parent[]` 记法。注释与空行跳过。
对 data/ 顶层 config yaml 的提取结果与 2026-08-07 审计存档
(/tmp/q2/numbers_leaves.tsv, 1239 叶 @ numbers.yaml)逐行一致。

用法:
  python3 q2_leaf_extract.py <path/to/file.yaml>
  输出:行号<TAB>点分路径<TAB>值
"""
import sys, re


def extract(path):
    """Yield (dotted_path, value, line_no) for scalar leaf keys in a YAML file."""
    stack = []  # list of (indent, key)
    leaves = []
    with open(path, encoding='utf-8') as f:
        for lineno, raw in enumerate(f, 1):
            line = raw.rstrip('\n')
            stripped = line.strip()
            # skip blanks, comments, list items we handle loosely
            if not stripped or stripped.startswith('#'):
                continue
            indent = len(line) - len(line.lstrip(' '))
            # pop stack to current indent
            while stack and stack[-1][0] >= indent:
                stack.pop()
            # key: value
            m = re.match(r'^([^:#]+?):\s*(.*)$', stripped)
            if m:
                key = m.group(1).strip().strip('"\'')
                val = m.group(2).strip()
                path_ = '.'.join([k for _, k in stack] + [key])
                if val == '' or val.startswith('#'):
                    # branch node
                    stack.append((indent, key))
                else:
                    # leaf (could still be a list item value handled elsewhere)
                    # strip trailing comment
                    v = re.split(r'\s+#', val)[0].strip()
                    leaves.append((path_, v, lineno))
                continue
            # list item
            m2 = re.match(r'^-\s*(.*)$', stripped)
            if m2:
                content = m2.group(1).strip()
                # list item that is "key: value" inline
                m3 = re.match(r'^([^:#]+?):\s*(.*)$', content)
                parent = '.'.join([k for _, k in stack])
                if m3:
                    key = m3.group(1).strip().strip('"\'')
                    val = m3.group(2).strip()
                    v = re.split(r'\s+#', val)[0].strip()
                    leaves.append((f"{parent}[].{key}" if parent else f"[].{key}", v, lineno))
                else:
                    v = re.split(r'\s+#', content)[0].strip()
                    parent = '.'.join([k for _, k in stack])
                    leaves.append((f"{parent}[]" if parent else "[]", v, lineno))
    return leaves


if __name__ == '__main__':
    path = sys.argv[1]
    leaves = extract(path)
    for p, v, ln in leaves:
        print(f"{ln}\t{p}\t{v}")
