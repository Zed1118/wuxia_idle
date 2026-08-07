#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/doc_link_scan.py — docs/ 内部引用死链扫描器

派单:docs/dispatch/2026-08-07_L1D.md(L1-D)
目的:把 2026-08-07 B1 报告(1092 处死链)中的三类系统性假阳性正确排除,
     让任何人跑一条命令就能拿到可信的死链底账。

三类假阳性(必须排除):
  1) .gitignore 明文声明"不入库"的路径(验收截图 / docs/art/ / test/tools/output/ 等)
     —— 文件在本地磁盘真实存在,只是按策略不进 git。不是死链,是合规。
  2) *.g.dart 等 build 产物 —— 上次扫描跑在没跑过 build_runner 的 fresh worktree,
     全判死;实属生成物,不进 git,也不算死链。
  3) git worktree / 分支名(形如 `docs/foo@25221323`)—— 根本不是文档路径。

关键改进(别用 os.path.exists):
  - 用 `git ls-files` 建立"仓库已跟踪文件集",判定 target in TRACKED 或 target 是
    某已跟踪文件的父目录。与工作树 build 状态解耦,任何地方跑结果一致。
  - 对判定为"不存在"的 target,再批量跑 `git check-ignore --stdin` 二次过滤。
    命中的归入 ignored 类单独计数,不计入死链。

只用 Python 3 标准库 + subprocess 调 git。无第三方依赖。

用法:
  python3 tools/doc_link_scan.py            # 人读汇总
  python3 tools/doc_link_scan.py --json     # 结构化输出(供 diff 比对)
  python3 tools/doc_link_scan.py --rows     # 人读汇总 + 死链明细行
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Iterable

# --------------------------------------------------------------------------
# 常量
# --------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parent.parent

# 扫描范围:docs/**/*.md,排除下列路径:
#   - docs/_archive/  —— 派单 §1.1 明文排除(归档历史,不扫)
#   - docs/dispatch/reports/  —— 死链扫描报告本身。报告把每条死链写在
#     反引号里作为示例,扫它会把"已记录的死链"当作"新发现的死链",
#     自指循环,无意义(派单 §1.1 字面未列,但与"工具必须产可信底账"
#     的目的冲突,故排除;在报告中明确说明此口径选择)。
#   - docs/PATH_MIGRATION_MAP.md  —— 迁移映射表本体。文档第 3 行自陈:
#     "多数不是失修,是当时的真实路径"。它把旧路径写在反引号里作为
#     映射表左侧,扫它必然把旧路径采集成死链——与 reports/ 报告本身
#     自指同性质,一并排除(同口径,不凑数)。
SCAN_ROOT = "docs"
EXCLUDE_DIRS = {"docs/_archive", "docs/dispatch/reports"}
EXCLUDE_FILES = {"docs/PATH_MIGRATION_MAP.md"}

# 反引号路径:必须以这些顶级目录开头(允许 ./ ../ 前缀),才视为路径 token。
# 与派单 §1.2 一致:docs / lib / test / data / tool / tools / assets。
# build 仅用于识别文档中明确写出的 gitignored 生成物引用,由 check-ignore
# 归入 ignored,避免把这类引用在采集阶段静默漏掉。
TOP_DIRS = ("docs", "lib", "test", "data", "tool", "tools", "assets", "build")

# 已知扩展名(用于剥字段后缀):data/skills.yaml.powerMultiplier → data/skills.yaml
KNOWN_EXTS = (
    "yaml", "yml", "dart", "json", "md", "markdown",
    "png", "jpg", "jpeg", "webp", "gif", "svg", "bmp", "ico",
    "tsv", "csv", "txt", "sh", "bash", "zsh",
    "lock", "toml", "gradle", "plist", "xml", "html", "htm",
    "css", "js", "ts", "tsx", "jsx", "go", "py", "rb", "rs",
    "c", "cpp", "h", "hpp", "cc",
    "frag", "vert", "glsl", "spv",
)

# 尾部标点(剥):含中文标点 + 半角 + 空白
TRAILING_PUNCT = "。，；：、」』】)》〉\"'。).,;: \t\r\n"

# 单字母/明显占位段(整段为这些值时跳过)
PLACEHOLDER_SEGS = {"X", "x", "foo", "bar", "baz", "FOO", "BAR", "BAZ", "_"}

# 出 repo 边界标记
OUT_OF_REPO_MARKERS = (".claude/projects/",)

# --------------------------------------------------------------------------
# 工具:subprocess 调 git(批量 stdin 模式)
# --------------------------------------------------------------------------

def git_ls_files() -> list[str]:
    """返回仓库所有已跟踪文件路径(相对 repo root)。"""
    out = subprocess.check_output(
        ["git", "ls-files"], cwd=REPO_ROOT, text=True, encoding="utf-8"
    )
    return [line for line in out.splitlines() if line]


def git_check_ignore(paths: Iterable[str]) -> set[str]:
    """批量判定 path 是否被 .gitignore 命中。返回命中的 path 集合。

    一次性 stdin 喂入,避免逐个调用(很慢)。
    """
    paths = list(paths)
    if not paths:
        return set()
    # git check-ignore --stdin 一次吃 N 行,输出命中的那批。
    stdin = "\n".join(paths) + ("\n" if paths else "")
    proc = subprocess.run(
        ["git", "check-ignore", "--stdin"],
        cwd=REPO_ROOT, input=stdin,
        text=True, capture_output=True, encoding="utf-8",
    )
    # exit code 0 = 至少一条命中;1 = 全部未命中;其他 = 异常
    if proc.returncode not in (0, 1):
        raise RuntimeError(
            f"git check-ignore 异常 rc={proc.returncode} stderr={proc.stderr!r}"
        )
    return {line for line in proc.stdout.splitlines() if line}


def git_ls_files_for_ignore_test(paths: Iterable[str]) -> set[str]:
    """对路径(可能未跟踪、可能不存在),用 check-ignore 判定。
    别名,清晰起见。"""
    return git_check_ignore(paths)


# --------------------------------------------------------------------------
# 扫描源:已跟踪的 docs/**/*.md(排除 _archive)
# --------------------------------------------------------------------------

def collect_scan_files(tracked: set[str]) -> list[str]:
    """扫描源 = 已跟踪的 docs/**/*.md,排除 docs/_archive/。

    用 git ls-files 而非工作树 os.walk,理由同 §1.6:
    与工作树 build 状态解耦,任何 worktree / 主树跑结果一致。
    """
    files = []
    for p in tracked:
        if not p.endswith(".md"):
            continue
        if not p.startswith("docs/"):
            continue
        if p.startswith("docs/_archive/"):
            continue
        if p.startswith("docs/dispatch/reports/"):
            continue
        if p in EXCLUDE_FILES:
            continue
        files.append(p)
    files.sort()
    return files


# --------------------------------------------------------------------------
# 文本扫描:反引号路径 + md 链接,跳过代码围栏
# --------------------------------------------------------------------------

# 反引号 token 正则:`` ` 路径 ` ``
# 路径必须以 TOP_DIRS 开头(允许 ./ ../ 前缀),且 TOP_DIRS 后紧跟 / 或 \ 或反引号结尾。
# 后两个约束避免误抓 `testWidgets\(` 这种字面字符串(开头是 `test` 但不是路径)。
# 后跟路径字符(字母数字下划线点连斜杠冒号 @ 等但不允许空白)。
# 不含反引号本身。
_TOP_DIRS_ALT = "|".join(re.escape(d) for d in TOP_DIRS)
_BACKTICK_PATH = re.compile(
    r"`((?:\./|\.\./)*(?:" + _TOP_DIRS_ALT + r")(?=[\\/`])(?P<body>[^`]*))`"
)

# md 链接 [text](path) 与 ![alt](path)
_MD_LINK = re.compile(r"!?\[([^\]]*)\]\(([^)]*)\)")

# URL 协议头(不扫)
_URL_PROTO = re.compile(r"^[a-z][a-z0-9+.\-]*://", re.IGNORECASE)

# 代码围栏起止
_FENCE = re.compile(r"^\s*(```+|~~~+)\s*")


def iter_doc_refs(file_rel: str, content: str) -> list[dict]:
    """逐行扫描单个 md 文件,产出引用记录。

    返回 list[dict],每条:
      {"file": file_rel, "line": int(1-based), "target": str(规范化前),
       "raw": str(原始 token), "kind": "backtick"|"mdlink"}
    跳过:
      - 代码围栏(``` 与 ~~~ 块)内部
      - URL(http(s):// mailto: ftp://)、纯锚点(#section)
      - 跳过类(§1.5)
    """
    refs: list[dict] = []
    in_fence = False
    lines = content.splitlines()
    for i, line in enumerate(lines, start=1):
        # 围栏起止
        m = _FENCE.match(line)
        if m:
            # 切换围栏状态(任何围栏都可切换,Markdown 规范的~~~与```)
            in_fence = not in_fence
            continue
        if in_fence:
            continue

        # --- 1) 反引号路径 ---
        for m in _BACKTICK_PATH.finditer(line):
            raw = m.group(1)
            target = raw  # 规范化前先存
            refs.append({"file": file_rel, "line": i, "target": target,
                         "raw": raw, "kind": "backtick"})

        # --- 2) md 链接 ---
        for m in _MD_LINK.finditer(line):
            text = m.group(1)
            path = m.group(2)
            # 剥首尾空白
            path = path.strip()
            if not path:
                continue
            # URL 不扫
            if _URL_PROTO.match(path):
                continue
            # mailto: ftp: 不扫
            if path.lower().startswith(("mailto:", "ftp:")):
                continue
            # 纯锚点(#section)不扫
            if path.startswith("#"):
                continue
            refs.append({"file": file_rel, "line": i, "target": path,
                         "raw": f"[{text}]({path})", "kind": "mdlink"})

    return refs


# --------------------------------------------------------------------------
# 清洗(按序,§1.4)
# --------------------------------------------------------------------------

# 已知扩展名正则片段
_EXT_ALT = "|".join(re.escape(e) for e in KNOWN_EXTS)

# 剥 #anchor:路径末段形如 `foo.md#section` 或 `foo#section`
_RE_STRIP_ANCHOR = re.compile(r"#.*$")

# 剥 :行号 / :行-行 / :行,行 / :行+ / :行,行-行 等
_RE_STRIP_LINENO = re.compile(
    r":\d+(?:[-,+]\d+)*$"  # :12 / :12-30 / :12,30 / :12+ / :12,30-50
)

# 剥字段后缀:已知扩展名后再有 .xxx 的剥掉
# data/skills.yaml.powerMultiplier → data/skills.yaml
# 注意只剥 1 段,若有 .a.b.c 多段后缀也只剥尾段(更通用做法递归剥)。
_RE_STRIP_FIELDSUFFIX = re.compile(
    r"^(.*?\.(?:" + _EXT_ALT + r"))\.[^/\\]+$"
)

# worktree/分支名:含 @ 后跟 6+ 位 hex
_RE_WORKTREE_HEX = re.compile(r"@[0-9a-fA-F]{6,}")

# 通配 * ? { }
_RE_WILDCARD = re.compile(r"[*?{}]")

# 模板占位 <...> 或 [...](path 内不可能有 [...],但仍判)或 ... 占位
_RE_TEMPLATE_ANGLE = re.compile(r"<[^>]+>")
_RE_TEMPLATE_BRACKET = re.compile(r"\[[^\]]+\]")
_RE_DOTDOT_PLACEHOLDER = re.compile(r"(^|/)\.\.?(?=$|/)")  # 用于占位判断,见下

# 范围简写 a..b(段内含 .. 但不是单独 ..)
_RE_RANGE_SHORTHAND = re.compile(r"[^/]\.\.[^/]")


def _strip_trailing_punct(s: str) -> str:
    """剥尾部标点(含中文标点)。停在路径字符上。"""
    while s and s[-1] in TRAILING_PUNCT:
        s = s[:-1]
    return s


def clean_target(target: str) -> str:
    """按 §1.4 顺序清洗 target。"""
    # 0) 反斜杠 → 正斜杠:Windows 风格路径(如 `docs\handoff\foo.png`)
    #    统一为 POSIX 风格,与 B1 旧口径一致(B1 报告 0 反斜杠引用)。
    #    仅当 target 以 TOP_DIRS 之一 + 反斜杠/正斜杠开头时才转;
    #    这样不动 Windows 盘符路径(C:\...)与字面字符串。
    for d in TOP_DIRS:
        # 形如 `docs\` 或 `docs\...` 才转
        if target == d or target.startswith(d + "\\") or target.startswith(d + "/"):
            target = target.replace("\\", "/")
            break
    # 1) 剥 #anchor
    target = _RE_STRIP_ANCHOR.sub("", target)
    # 2) 剥 :行号
    target = _RE_STRIP_LINENO.sub("", target)
    # 3) 剥字段后缀(已知扩展名后的 .xxx)
    # 递归剥(最多剥 3 段,避免死循环)
    for _ in range(3):
        m = _RE_STRIP_FIELDSUFFIX.match(target)
        if not m:
            break
        target = m.group(1)
    # 4) 剥尾部标点(含中文标点)
    target = _strip_trailing_punct(target)
    return target


# --------------------------------------------------------------------------
# 跳过判定(§1.5)
# --------------------------------------------------------------------------

def should_skip(target: str) -> tuple[bool, str]:
    """按 §1.5 判定是否跳过(不计入引用,也不计入死链)。

    返回 (skip, reason)。
    """
    if not target:
        return True, "empty"

    # 通配 * ? { }
    if _RE_WILDCARD.search(target):
        return True, "wildcard"

    # 模板占位 <...>
    if _RE_TEMPLATE_ANGLE.search(target):
        return True, "template<>"

    # 模板占位 [...] (注意:md link path 不会含,反引号路径里可能有)
    if _RE_TEMPLATE_BRACKET.search(target):
        return True, "template[]"

    # 含 ... 占位(整段或段中三点)
    if "..." in target:
        return True, "ellipsis"

    # 范围简写 a..b(段内 ..)
    if _RE_RANGE_SHORTHAND.search(target):
        return True, "range a..b"

    # worktree/分支名 @hex
    if _RE_WORKTREE_HEX.search(target):
        return True, "worktree@hex"

    # 出 repo:.claude/projects/ 或 ../ 越过仓库根(此处仅判 marker,
    # 真正的 ../ 越界在规范化时判)
    for marker in OUT_OF_REPO_MARKERS:
        if marker in target:
            return True, "out-of-repo"

    # 前缀简写:末段无扩展名且以 _ 结尾
    last_seg = target.rsplit("/", 1)[-1]
    if last_seg.endswith("_") and "." not in last_seg:
        return True, "prefix shorthand _"

    # 单字母/明显占位段
    for seg in target.split("/"):
        if seg in PLACEHOLDER_SEGS:
            return True, f"placeholder seg:{seg}"

    return False, ""


# --------------------------------------------------------------------------
# 路径规范化:把 target 解析为相对 repo root 的路径(或越界标记)
# --------------------------------------------------------------------------

def normalize_target(target: str, src_file: str) -> tuple[str | None, str]:
    """把 target 规范化为相对 repo root 的路径。

    返回 (normalized_or_None, reason)。
      - normalized_or_None = None:越界或不可解析(跳过)
      - reason:状态字符串

    规则:
      - 剥 ./ 前缀(冗余)
      - 处理 ../ :基于 src_file 所在目录逐级向上
      - 不以顶级目录开头的相对路径(如 ./foo 或 foo):基于 src_file 所在目录拼
      - 顶级目录开头(docs/ lib/ ...):直接当 repo 相对路径
    """
    if not target:
        return None, "empty"

    # 剥 ./ 前缀(可多个)
    while target.startswith("./"):
        target = target[2:]
    # 剥开头的 ../ 前缀(逐个处理)
    src_dir_parts = src_file.split("/")[:-1]  # md 文件所在目录(相对 repo root)

    if target.startswith("../"):
        # 逐级向上
        parts = target.split("/")
        up = 0
        idx = 0
        while idx < len(parts) and parts[idx] == "..":
            up += 1
            idx += 1
        rest = parts[idx:]
        # 当前目录 = src_dir_parts 向上 up 级
        if up > len(src_dir_parts):
            return None, "out-of-repo (../)"
        base_parts = src_dir_parts[: len(src_dir_parts) - up]
        normalized = "/".join(base_parts + rest)
        return normalized, "ok"

    # 绝对路径(/foo):不规化(本仓几乎不会有,当越界)
    if target.startswith("/"):
        return None, "absolute"

    # 顶级目录开头:直接当 repo 相对路径
    first_seg = target.split("/", 1)[0]
    if first_seg in TOP_DIRS:
        return target, "ok"

    # 其他相对路径(无 ./ ../ 前缀,且不以顶级目录开头):
    # 视为基于 src_dir 拼接。这种 token 在反引号采集阶段不会被采(因为
    # _BACKTICK_PATH 强制以顶级目录开头),但 md link path 可能出现。
    # 派单口径:md link 也走存在性判定,但裸相对路径需要基准。
    # 按派单 §1.2 的反引号口径,这里兜底:拼到 src_dir。
    if src_dir_parts:
        return "/".join(src_dir_parts) + "/" + target, "rel-to-srcdir"
    return target, "rel-to-root"


# --------------------------------------------------------------------------
# 存在性判定(§1.6 关键改进)
# --------------------------------------------------------------------------

def make_existence_checker(tracked: set[str]):
    """返回 (is_tracked_or_dir, target) 判定函数。

    target 命中 TRACKED: 存活(文件)
    target 是某已跟踪文件的父目录: 存活(目录)
    否则: 不存在(交由 check-ignore 二次过滤)
    """
    # 预计算所有"已跟踪文件的目录前缀"集合,加速 "target 是父目录" 判定。
    # 数据量大时此集合会膨胀,实测 4086 tracked 文件 → 约 700 目录前缀,可接受。
    dir_prefixes: set[str] = set()
    for f in tracked:
        # f 形如 docs/foo/bar.md
        parts = f.split("/")
        for i in range(1, len(parts)):
            dir_prefixes.add("/".join(parts[:i]) + "/")

    def check(target: str) -> tuple[bool, str]:
        if target in tracked:
            return True, "tracked file"
        if (target + "/") in dir_prefixes or target.endswith("/") and target in dir_prefixes:
            return True, "tracked dir"
        if target.endswith("/") and target.rstrip("/") in tracked:
            return True, "tracked dir (file w/ trailing /)"
        # 兜底:target 形如 docs/foo/(末尾带/) 判定
        if target.endswith("/") and target.rstrip("/") + "/" in dir_prefixes:
            return True, "tracked dir"
        return False, "missing"

    return check


# --------------------------------------------------------------------------
# 主流程
# --------------------------------------------------------------------------

def scan():
    tracked_set = set(git_ls_files())
    scan_files = collect_scan_files(tracked_set)

    # 第一遍:扫所有 md,采集 + 清洗 + 跳过 + 规范化
    all_refs: list[dict] = []
    skipped_count = 0
    skipped_reasons: dict[str, int] = {}
    out_of_repo_count = 0
    # target 规范化失败的(用于诊断)
    invalid_norms: list[dict] = []

    for fpath in scan_files:
        full = REPO_ROOT / fpath
        try:
            content = full.read_text(encoding="utf-8")
        except (UnicodeDecodeError, FileNotFoundError):
            # 二进制或编码问题,跳过
            continue
        for ref in iter_doc_refs(fpath, content):
            raw = ref["raw"]
            # 清洗
            cleaned = clean_target(ref["target"])
            # 跳过判定
            skip, reason = should_skip(cleaned)
            if skip:
                skipped_count += 1
                skipped_reasons[reason] = skipped_reasons.get(reason, 0) + 1
                continue
            # 规范化为 repo 相对路径
            norm, norm_reason = normalize_target(cleaned, ref["file"])
            if norm is None:
                # 越界(出 repo)
                out_of_repo_count += 1
                skipped_reasons[norm_reason] = (
                    skipped_reasons.get(norm_reason, 0) + 1
                )
                continue
            # 规范化后可能再次需要清洗末尾标点(../ 后剥导致的尾点等)
            norm = norm.rstrip("/") or norm  # 末尾 / 保留(目录前缀判定需要)
            # 重新判定跳过(规范化后的形态)
            skip2, reason2 = should_skip(norm)
            if skip2:
                skipped_count += 1
                skipped_reasons[reason2] = skipped_reasons.get(reason2, 0) + 1
                continue
            all_refs.append({
                "file": ref["file"],
                "line": ref["line"],
                "target": norm,
                "raw": raw,
                "kind": ref["kind"],
            })

    # 第二遍:存在性判定
    existence = make_existence_checker(tracked_set)
    not_alive: list[dict] = []
    alive_count = 0
    for ref in all_refs:
        ok, _ = existence(ref["target"])
        if ok:
            alive_count += 1
        else:
            not_alive.append(ref)

    # 第三遍:批量 check-ignore 过滤
    not_alive_targets = {r["target"] for r in not_alive}
    ignored_targets = git_check_ignore(not_alive_targets)
    ignored_count = 0
    ignored_rows: list[dict] = []
    dead_rows: list[dict] = []
    for ref in not_alive:
        if ref["target"] in ignored_targets:
            ignored_count += 1
            ignored_rows.append(ref)
        else:
            dead_rows.append(ref)

    # 排序保证幂等
    dead_rows.sort(key=lambda r: (r["file"], r["line"], r["target"], r["raw"]))
    ignored_rows.sort(key=lambda r: (r["file"], r["line"], r["target"], r["raw"]))

    # 子目录分布
    by_dir_dead: dict[str, int] = {}
    by_dir_refs: dict[str, int] = {}
    for r in all_refs:
        seg = r["file"].split("/")
        d = seg[1] if len(seg) > 2 else "(top)"
        by_dir_refs[d] = by_dir_refs.get(d, 0) + 1
    for r in dead_rows:
        seg = r["file"].split("/")
        d = seg[1] if len(seg) > 2 else "(top)"
        by_dir_dead[d] = by_dir_dead.get(d, 0) + 1

    return {
        "scanned_files": len(scan_files),
        "refs_total": len(all_refs),
        "alive": alive_count,
        "dead": len(dead_rows),
        "ignored": ignored_count,
        "skipped": skipped_count,
        "out_of_repo": out_of_repo_count,
        "skipped_reasons": skipped_reasons,
        "by_dir_refs": dict(sorted(by_dir_refs.items())),
        "by_dir_dead": dict(sorted(by_dir_dead.items())),
        "rows": dead_rows,
        "ignored_rows": ignored_rows,
        "tracked_files_total": len(tracked_set),
    }


def fmt_human(result: dict, show_rows: bool = False,
              show_ignored: bool = False) -> str:
    lines = []
    lines.append("=" * 60)
    lines.append("docs/ 内部引用死链扫描报告")
    lines.append("=" * 60)
    lines.append("")
    lines.append("汇总:")
    lines.append(f"  扫描 md 文件数:  {result['scanned_files']}")
    lines.append(f"  引用总数(存活+死+ignored):  {result['refs_total']}")
    lines.append(f"  ├─ 存活(已跟踪):  {result['alive']}")
    lines.append(f"  ├─ ignored(gitignored,不计死链):  {result['ignored']}")
    lines.append(f"  └─ 死链(未跟踪且未被 ignore):  {result['dead']}")
    lines.append(f"  跳过类(通配/模板/worktree 名等):  {result['skipped']}")
    lines.append(f"    (其中出 repo 边界:  {result['out_of_repo']})")
    lines.append(f"  已跟踪文件总数(参考):  {result['tracked_files_total']}")
    lines.append("")

    lines.append("跳过类分布:")
    for reason, n in sorted(result["skipped_reasons"].items(),
                            key=lambda kv: (-kv[1], kv[0])):
        lines.append(f"  {reason:30s}  {n}")
    lines.append("")

    lines.append("按 docs 一级子目录分布:")
    lines.append(f"  {'子目录':20s} {'引用数':>10s} {'死链数':>10s}")
    all_dirs = sorted(set(result["by_dir_refs"]) | set(result["by_dir_dead"]))
    for d in all_dirs:
        r = result["by_dir_refs"].get(d, 0)
        dead = result["by_dir_dead"].get(d, 0)
        lines.append(f"  {d:20s} {r:>10d} {dead:>10d}")
    lines.append("")

    if show_rows:
        lines.append("死链明细(按 文件 / 行 / target 排序):")
        lines.append(f"  共 {len(result['rows'])} 条")
        lines.append(f"  {'文件':50s} {'行':>6s}  target")
        for r in result["rows"]:
            lines.append(f"  {r['file']:50s} {r['line']:>6d}  {r['target']}")
        lines.append("")

    if show_ignored:
        lines.append("ignored 明细(gitignored,不计死链;按 文件 / 行 / target 排序):")
        lines.append(f"  共 {len(result['ignored_rows'])} 条")
        lines.append(f"  {'文件':50s} {'行':>6s}  target")
        for r in result["ignored_rows"]:
            lines.append(f"  {r['file']:50s} {r['line']:>6d}  {r['target']}")
        lines.append("")

    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="docs/ 内部引用死链扫描器(派单 L1-D)",
    )
    parser.add_argument("--json", action="store_true",
                        help="输出结构化 JSON(供 diff 比对)")
    parser.add_argument("--rows", action="store_true",
                        help="人读模式 + 死链明细行")
    parser.add_argument("--ignored", action="store_true",
                        help="人读模式 + ignored 明细行(诊断用)")
    args = parser.parse_args(argv)

    result = scan()

    if args.json:
        # JSON 模式:输出结构化结果(rows 已排序,幂等)
        # 标准形状只含 dead rows(派单 §二建议);ignored_rows 仅在诊断时用,
        # 这里一并输出便于外部脚本三类反例验证,字段名独立,不影响标准形状消费。
        out = {
            "scanned_files": result["scanned_files"],
            "refs_total": result["refs_total"],
            "alive": result["alive"],
            "dead": result["dead"],
            "ignored": result["ignored"],
            "skipped": result["skipped"],
            "by_dir_refs": result["by_dir_refs"],
            "by_dir_dead": result["by_dir_dead"],
            "rows": [
                {"file": r["file"], "line": r["line"], "target": r["target"],
                 "raw": r["raw"], "kind": r["kind"]}
                for r in result["rows"]
            ],
            "ignored_rows": [
                {"file": r["file"], "line": r["line"], "target": r["target"],
                 "raw": r["raw"], "kind": r["kind"]}
                for r in result["ignored_rows"]
            ],
        }
        print(json.dumps(out, ensure_ascii=False, indent=2, sort_keys=False))
        return 0

    print(fmt_human(result, show_rows=args.rows, show_ignored=args.ignored))
    return 0


if __name__ == "__main__":
    sys.exit(main())
