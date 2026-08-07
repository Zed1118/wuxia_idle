#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Q2 派单 · 强类型配置字段业务消费扫描

来源:2026-08-07 Q2 审计时写在 /tmp/q2/field_usage.py 的临时脚本,
P4 单(2026-08-08)入仓。改动仅两处:
  1. ROOT 由写死的 worktree 绝对路径改为从本文件位置推导仓库根,
     任何 worktree 里跑结果一致;
  2. 提取 main() 供 run_all.py 复用。

做什么:
  - 从 lib/data/numbers_config.dart + lib/data/defs/*.dart 提取所有
    class 的 `final` 实例字段(强类型配置字段);
  - 对每个字段名 grep `\\.<name>\\b` 全 lib,排除 lib/data/(loader 自身)、
    lib/features/debug/、*.g.dart,统计业务侧引用行数;
  - 零引用者即"机械筛候选"(Q2 报告口径:89 个,2026-08-07 基线)。

用法:
  python3 q2_field_usage.py          # 打印 全量 "引用数 字段名 类 位置"
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def parse_dart_classes(path):
    """Return dict class_name -> list[(field_name, line_no)] for final fields."""
    classes = {}
    cur = None
    with open(path, encoding='utf-8') as f:
        for i, line in enumerate(f, 1):
            m = re.match(r'^(?:abstract )?class (\w+)', line)
            if m:
                cur = m.group(1)
                classes.setdefault(cur, [])
                continue
            if cur:
                fm = re.match(r'^  final\s+(?:[\w<>,\s\?]+?)\s+(\w+)\s*[;=]', line)
                if fm:
                    name = fm.group(1)
                    classes[cur].append((name, i))
    return classes


def loader_files():
    return ['lib/data/numbers_config.dart'] + sorted(
        os.path.join('lib/data/defs', f)
        for f in os.listdir(os.path.join(ROOT, 'lib/data/defs'))
        if f.endswith('.dart'))


def grep_count(pattern):
    """Count files with matches for a usage pattern in business code."""
    try:
        out = subprocess.run(
            ['grep', '-rn', '--include=*.dart', '-E', pattern, 'lib'],
            cwd=ROOT, capture_output=True, text=True).stdout.strip().splitlines()
    except Exception:
        return []
    hits = []
    for ln in out:
        path = ln.split(':', 1)[0]
        if path.startswith('lib/data/') or path.startswith('lib/features/debug/') or path.endswith('.g.dart'):
            continue
        hits.append(ln)
    return hits


def run():
    """返回 {field_name: [(class, loader_path, line), ...]},以及每字段业务引用行。"""
    all_fields = {}
    for lp in loader_files():
        for cls, fields in parse_dart_classes(lp).items():
            for name, ln in fields:
                all_fields.setdefault(name, []).append((cls, lp, ln))
    usage = {}
    for name in sorted(all_fields):
        usage[name] = grep_count(r'\.' + re.escape(name) + r'\b')
    return all_fields, usage


if __name__ == '__main__':
    all_fields, usage = run()
    print(f"# total unique field names: {len(all_fields)}")
    for name in sorted(all_fields):
        hits = usage[name]
        cls = all_fields[name][0][0]
        loc = all_fields[name][0][1] + ':' + str(all_fields[name][0][2])
        print(f"{len(hits):3d}  {name:42s} {cls:32s} {loc}")
