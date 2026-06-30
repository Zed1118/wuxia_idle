#!/usr/bin/env python3
"""Audit paper-surface widgets for deep-background text colors.

`WuxiaColors.textPrimary/textSecondary/textMuted` are light text tokens for
dark UI surfaces. On Wuxia paper surfaces they become low-contrast gray/white.
This audit scans Dart widget scopes that are known to render paper-like
surfaces and reports those token uses.

Use `// paper-text-audit: allow <reason>` on the same or previous line for a
deliberate exception, such as text rendered inside a nested dark panel.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path


TEXT_TOKEN_RE = re.compile(
    r"WuxiaColors\.text(?:Primary|Secondary|Muted)(?:\.withValues\([^)]*\))?"
)
PAPER_FILL_RE = re.compile(r"WuxiaUi\.(?:paper|paper2|panelFill|slotFill)\b")
ALLOW_RE = re.compile(r"paper-text-audit:\s*allow\b")

SURFACE_CALLS = (
    "PaperPanel",
    "PaperDialog",
    "PaperDialog.show",
    "CeremonyImagePanel",
)

PAPER_FILL_CALLS = (
    "Container",
    "DecoratedBox",
    "ColoredBox",
    "Card",
    "Material",
)


@dataclass(frozen=True)
class Scope:
    start: int
    end: int
    kind: str


@dataclass(frozen=True)
class Finding:
    path: Path
    line: int
    column: int
    token: str
    scope: str
    text: str


def iter_dart_files(root: Path) -> list[Path]:
    paths = [p for p in (root / "lib").rglob("*.dart") if p.is_file()]
    return sorted(paths)


def next_non_space(text: str, idx: int) -> int:
    while idx < len(text) and text[idx].isspace():
        idx += 1
    return idx


def is_ident_char(ch: str) -> bool:
    return ch.isalnum() or ch == "_"


def call_ranges(text: str, name: str) -> list[Scope]:
    scopes: list[Scope] = []
    search_from = 0
    while True:
        idx = text.find(name, search_from)
        if idx == -1:
            break
        before = text[idx - 1] if idx > 0 else ""
        after_idx = idx + len(name)
        if before and is_ident_char(before):
            search_from = after_idx
            continue
        open_idx = next_non_space(text, after_idx)
        if open_idx >= len(text) or text[open_idx] != "(":
            search_from = after_idx
            continue
        close_idx = matching_paren(text, open_idx)
        if close_idx != -1:
            scopes.append(Scope(idx, close_idx + 1, name))
            search_from = close_idx + 1
        else:
            search_from = after_idx
    return scopes


def matching_paren(text: str, open_idx: int) -> int:
    depth = 0
    quote: str | None = None
    escape = False
    line_comment = False
    block_comment = False
    i = open_idx
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if line_comment:
            if ch == "\n":
                line_comment = False
            i += 1
            continue
        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
                i += 2
            else:
                i += 1
            continue
        if quote:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                quote = None
            i += 1
            continue
        if ch == "/" and nxt == "/":
            line_comment = True
            i += 2
            continue
        if ch == "/" and nxt == "*":
            block_comment = True
            i += 2
            continue
        if ch in {"'", '"'}:
            quote = ch
            i += 1
            continue
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def line_starts(text: str) -> list[int]:
    starts = [0]
    for idx, ch in enumerate(text):
        if ch == "\n":
            starts.append(idx + 1)
    return starts


def line_col(starts: list[int], idx: int) -> tuple[int, int]:
    lo, hi = 0, len(starts)
    while lo + 1 < hi:
        mid = (lo + hi) // 2
        if starts[mid] <= idx:
            lo = mid
        else:
            hi = mid
    return lo + 1, idx - starts[lo] + 1


def line_text(text: str, starts: list[int], line: int) -> str:
    start = starts[line - 1]
    end = starts[line] - 1 if line < len(starts) else len(text)
    return text[start:end].strip()


def in_line_comment(text: str, starts: list[int], line: int, column: int) -> bool:
    start = starts[line - 1]
    end = starts[line] - 1 if line < len(starts) else len(text)
    raw = text[start:end]
    comment_idx = raw.find("//")
    return comment_idx != -1 and comment_idx < column - 1


def allowed(lines: list[str], line: int) -> bool:
    current = lines[line - 1] if 0 <= line - 1 < len(lines) else ""
    previous = lines[line - 2] if 0 <= line - 2 < len(lines) else ""
    return bool(ALLOW_RE.search(current) or ALLOW_RE.search(previous))


def collect_scopes(text: str) -> list[Scope]:
    scopes: list[Scope] = []
    for name in SURFACE_CALLS:
        scopes.extend(call_ranges(text, name))
    for name in PAPER_FILL_CALLS:
        for scope in call_ranges(text, name):
            snippet = text[scope.start : scope.end]
            if PAPER_FILL_RE.search(snippet):
                scopes.append(Scope(scope.start, scope.end, f"{name}+paper-fill"))
    return scopes


def audit_file(path: Path) -> list[Finding]:
    text = path.read_text(encoding="utf-8")
    starts = line_starts(text)
    lines = text.splitlines()
    findings: list[Finding] = []
    seen: set[tuple[int, str]] = set()
    for scope in collect_scopes(text):
        snippet = text[scope.start : scope.end]
        for match in TEXT_TOKEN_RE.finditer(snippet):
            absolute = scope.start + match.start()
            line, col = line_col(starts, absolute)
            token = match.group(0)
            key = (line, token)
            if key in seen or allowed(lines, line) or in_line_comment(text, starts, line, col):
                continue
            seen.add(key)
            findings.append(
                Finding(
                    path=path,
                    line=line,
                    column=col,
                    token=token,
                    scope=scope.kind,
                    text=line_text(text, starts, line),
                )
            )
    return findings


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Audit paper surfaces for dark-UI text token misuse."
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=Path("."),
        help="Project root. Defaults to current directory.",
    )
    parser.add_argument(
        "--format",
        choices=("text", "csv"),
        default="text",
        help="Output format.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    findings: list[Finding] = []
    for path in iter_dart_files(root):
        findings.extend(audit_file(path))

    if args.format == "csv":
        print("file,line,column,scope,token,text")
        for f in findings:
            rel = f.path.relative_to(root).as_posix()
            text = f.text.replace('"', '""')
            print(f'"{rel}",{f.line},{f.column},"{f.scope}","{f.token}","{text}"')
    else:
        for f in findings:
            rel = f.path.relative_to(root)
            print(f"{rel}:{f.line}:{f.column}: {f.scope}: {f.token}")
            print(f"  {f.text}")
        if findings:
            print()
        print(f"paper text contrast findings: {len(findings)}")

    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
