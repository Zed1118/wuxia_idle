#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""A1 派单 · 类上下文归属过滤(消同名污染)

来源:2026-08-07 A1 审计时写在 /tmp/a1_audit/classify_owned.py 的临时脚本,
P4 单(2026-08-08)入仓。改动:
  1. ROOT 由写死的 worktree 绝对路径改为从本文件位置推导仓库根;
  2. 中间产物(fields.tsv / refs_by_field.tsv / candidates.txt /
     candidates_owned.txt)路径参数化(--workdir);
  3. refs 内文件路径为仓库相对路径,源码索引同步改为相对键。

做什么:对候选字段(candidates.txt 的 `### 类.字段` 行)的引用做
类上下文归属:`.field` 前的对象名必须能在同文件找到该类类型声明
(或构造赋值),否则视为同名污染剔除;`this.x` 只归属声明文件。
归属后再做读/写分类,输出仍无生产读者到 candidates_owned.txt。

用法:
  python3 a1_classify_owned.py --workdir /tmp/a1_run
"""
import argparse
import os
import re
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def load_source_lines():
    """收集 lib/ 与 test/ 全部 dart 文件行,键为仓库相对路径。"""
    files = {}
    for sub in ("lib", "test"):
        for root, dirs, fnames in os.walk(os.path.join(ROOT, sub)):
            for f in fnames:
                if sub == "lib" and f.endswith(".g.dart"):
                    continue
                if not f.endswith(".dart"):
                    continue
                p = os.path.join(root, f)
                files[os.path.relpath(p, ROOT)] = open(p, encoding="utf-8").readlines()
    return files


def object_is_of_class(files, path, obj, cls):
    """文件中 obj 的声明类型是否为 cls(含构造调用赋值)。"""
    content = files.get(path, [])
    # 类型注解 + 变量名: AttackResult obj / AttackResult? obj / List<AttackResult> obj
    pat = re.compile(r"\b" + re.escape(cls) + r"(?:<[^>]*>)?\??\s+" + re.escape(obj) + r"\b")
    for line in content:
        if pat.search(line):
            return True
    # 构造调用赋值: obj = AttackResult( / obj = const AttackResult(
    pat2 = re.compile(r"\b" + re.escape(obj) + r"\s*=\s*(?:const\s+)?\s*" + re.escape(cls) + r"\(")
    for line in content:
        if pat2.search(line):
            return True
    # this.obj 引用(obj 是字段,声明文件内)
    if path.endswith('/domain/' + cls + '.dart') or os.path.basename(path).startswith(cls.lower()):
        return True
    return False


def make_decl_re(fname):
    return re.compile(r'^\s*(?:@\w+(?:\([^)]*\))?\s*)*(?:final\s+|late\s+|const\s+)*[A-Za-z_$][\w$<>?.,\[\]\s]*\s' + re.escape(fname) + r'\s*[=;]')


def make_read_pat(fname):
    return re.compile(r'(?<!this)(?:\.|\.\.\s*)\s*' + re.escape(fname) + r'(?!\s*[+\-*/%&|^]?=(?![=!<>]))|' +
                      re.escape(fname) + r'EqualTo\b|sortBy' + re.escape(fname[:1].upper() + fname[1:]) + r'\b|' +
                      r'get\s+' + re.escape(fname) + r'\b')


def make_write_pat(fname):
    return re.compile(r'(?:\.|\.\.)\s*' + re.escape(fname) + r'\s*=(?!=)|' +
                      re.escape(fname) + r'\s*:')


def filter_owned(ref_lines, cls, fname, files):
    """类上下文归属过滤 + 读/写分类。

    ref_lines:引用行列表,每行形如 `相对路径:行号\t文本`。
    files:load_source_lines() 的 {相对路径: [行]} 索引。
    返回 (decls, reads, writes, uncls),元素为原引用行字符串。
    """
    decls, reads, writes, uncls = [], [], [], []
    for l in ref_lines:
        if l.strip().startswith(('//', '/*', '*/', '*')):
            continue
        path = l.split(':', 1)[0].strip()
        txt = l.split('\t', 1)[1] if '\t' in l else ''
        # 归属过滤:提取 .field 前的对象名,验证其类型
        dot = re.search(r"([A-Za-z_$][\w$]*)\.\s*" + re.escape(fname) + r"\b", txt)
        if dot and txt.strip().startswith(('//', '/*')):
            continue
        if dot and not dot.group(1).startswith('_'):
            obj = dot.group(1)
            if obj == 'this':
                if not (os.path.basename(path) == (cls + '.dart')):
                    continue  # 其他类构造的 this.x 初始化
            elif not object_is_of_class(files, path, obj, cls):
                continue  # 其他类对象/局部变量污染
        # 命名参数 / 裸名形态:若文件不含类名,视为污染
        if not dot:
            if not os.path.basename(path) == (cls + '.dart') and not re.search(r"\b" + re.escape(cls) + r"\b", ''.join(files.get(path, [])[:400])):
                continue
        if make_decl_re(fname).match(txt):
            decls.append(l)
        elif make_read_pat(fname).search(txt):
            reads.append(l)
        elif make_write_pat(fname).search(txt):
            writes.append(l)
        else:
            uncls.append(l)
    return decls, reads, writes, uncls


def main():
    ap = argparse.ArgumentParser(description="A1 类上下文归属过滤")
    ap.add_argument('--workdir', required=True)
    args = ap.parse_args()
    wd = args.workdir

    files = load_source_lines()

    # 读取 refs(仓库相对路径)
    refs = defaultdict(list)
    cur = None
    for l in open(os.path.join(wd, 'refs_by_field.tsv'), encoding='utf-8'):
        l = l.rstrip('\n')
        if l.startswith('  '):
            refs[cur].append(l)
        else:
            p = l.split('\t')
            cur = (p[0], p[1])

    # 对候选字段(从 candidates.txt 读)做归属过滤
    candidates = []
    for l in open(os.path.join(wd, 'candidates.txt'), encoding='utf-8'):
        m = re.match(r'### (\S+)\.(\S+)\s+\(', l)
        if m:
            candidates.append((m.group(1), m.group(2)))

    # 复刻 classify 的读/写判定(注释行排除,this. 排除)
    out = []
    for cls, fname in candidates:
        decls, reads, writes, uncls = filter_owned(refs.get((cls, fname), []), cls, fname, files)
        out.append((cls, fname, decls, reads, writes, uncls))

    # 输出
    n_no_read = 0
    lines = []
    for cls, fname, decls, reads, writes, uncls in out:
        if not reads:
            n_no_read += 1
            lines.append(f"### {cls}.{fname}  (reads={len(reads)}, writes={len(writes)}, decls={len(decls)}, uncls={len(uncls)})")
            for tag, lst in (('W', writes), ('U', uncls), ('D', decls)):
                for l in lst:
                    lines.append(f"  [{tag}] {l[:160]}")
        else:
            lines.append(f"### {cls}.{fname}  (HAS-READ {len(reads)})")
            for l in reads:
                lines.append(f"  [R] {l[:160]}")
    print(f"无生产读字段数(类上下文归属后): {n_no_read} / {len(candidates)}")
    out_path = os.path.join(wd, 'candidates_owned.txt')
    open(out_path, 'w', encoding='utf-8').write('\n'.join(lines))
    print(f"written {out_path}")


if __name__ == '__main__':
    main()
