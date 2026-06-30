#!/usr/bin/env python3
"""Audit visual acceptance artifacts and refresh summary manifests."""

from __future__ import annotations

import argparse
import csv
import json
import re
import struct
from pathlib import Path
from typing import Iterable


MD_LINK_RE = re.compile(r"!??\[[^\]]*\]\(([^)]+)\)")
HTML_ATTR_RE = re.compile(r"\b(?:src|href)=[\"']([^\"']+)[\"']")
CODE_RE = re.compile(r"`([^`]+)`")
LINE_REFERENCE_RE = re.compile(
    r"(.+\.(?:dart|py|sh|swift|md|yaml|yml|json|toml)):(\d+)$"
)

PATH_PREFIXES = (
    "docs/",
    "lib/",
    "tools/",
    "test/",
    "data/",
    "assets/",
    "screenshots/",
    "contact_sheets/",
    "logs/",
)

PATH_SUFFIXES = (
    ".md",
    ".html",
    ".csv",
    ".png",
    ".jpg",
    ".jpeg",
    ".dart",
    ".sh",
    ".swift",
    ".log",
)

REQUIRED_ARTIFACTS = (
    "MORNING_DASHBOARD.md",
    "report.md",
    "all_pages_acceptance_index.md",
    "visual_gallery.html",
    "page_review_matrix.md",
    "issue_backlog.md",
    "issue_backlog.csv",
    "issue_owner_map.md",
    "claude_visual_fix_prompt.md",
    "artifact_manifest.csv",
    "markdown_link_check.csv",
    "route_coverage_check.csv",
    "issue_evidence_check.csv",
    "issue_quality_check.csv",
    "required_artifact_check.csv",
    "screenshot_dimension_check.csv",
    "severity_consistency_check.csv",
    "line_reference_check.csv",
    "issue_traceability_check.csv",
    "hitbox_coverage_check.csv",
    "contact_sheet_check.csv",
    "visual_acceptance_status.json",
    "verification_summary.md",
    "second_pass_visual_audit.md",
    "second_pass_visual_metrics.csv",
    "second_pass_manual_review_notes.md",
    "shared_visual_component_risk_map.md",
    "dynamic_interaction_acceptance_plan.md",
    "objective_evidence_matrix.md",
    "FINAL_ACCEPTANCE_GATE.md",
    "contact_sheets/issues_triple_resolution.jpg",
    "contact_sheets/second_pass_machine_flags.jpg",
)

EXPECTED_SCREENSHOT_DIMS = (
    ("screenshots/full/1280x720/*.png", 2560, 1440),
    ("screenshots/full_1440/full/1440x900/*.png", 2880, 1800),
    ("screenshots/full_1920_clean/full/1920x1080/*.png", 3840, 2160),
)

EXPECTED_ISSUE_COUNTS = {"P1": 1, "P2": 8, "P3": 2}
EXPECTED_HITBOX_ROUTES = {
    "hitbox_strong": (
        "battle_scene",
        "inventory",
        "main_menu",
        "seclusion_map_list",
        "shop",
        "technique_panel_tier_all",
        "tower_floor_list",
        "weapon_codex_detail",
    ),
    "hitbox_extra": (
        "character_panel",
        "encounter_outcome_skill_banner",
        "inventory_currency",
        "item_use_inventory",
        "sect_screen_npc",
        "skill_codex",
        "taohua_island",
        "zangjuange",
    ),
}
EXPECTED_CONTACT_SHEETS = (
    "full_1280_part_01.jpg",
    "full_1280_part_02.jpg",
    "full_1280_part_03.jpg",
    "full_1280_part_04.jpg",
    "full_1280_part_05.jpg",
    "full_1440_part_01.jpg",
    "full_1440_part_02.jpg",
    "full_1440_part_03.jpg",
    "full_1440_part_04.jpg",
    "full_1440_part_05.jpg",
    "full_1920_clean_part_01.jpg",
    "full_1920_clean_part_02.jpg",
    "full_1920_clean_part_03.jpg",
    "full_1920_clean_part_04.jpg",
    "full_1920_clean_part_05.jpg",
    "hitbox_1280.jpg",
    "hitbox_extra_1280.jpg",
    "hitbox_strong_1280.jpg",
    "issues_triple_resolution.jpg",
    "risk_1440.jpg",
    "risk_1920_clean.jpg",
    "second_pass_machine_flags.jpg",
    "smoke_1280x720.jpg",
    "smoke_1440x900.jpg",
    "smoke_1920_clean.jpg",
    "smoke_1920x1080.jpg",
)
REQUIRED_ISSUE_FIELDS = (
    "severity",
    "priority",
    "route",
    "fix_area",
    "finding",
    "evidence_1280",
    "evidence_1440",
    "evidence_1920",
    "risk_evidence",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Audit a visual acceptance artifact directory.",
    )
    parser.add_argument(
        "artifact_root",
        type=Path,
        help="Directory such as docs/handoff/visual_acceptance_2026-06-30.",
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path.cwd(),
        help="Project root used to resolve lib/tools/assets references.",
    )
    return parser.parse_args()


def read_image_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    suffix = path.suffix.lower()
    if suffix == ".png":
        if data[:8] != b"\x89PNG\r\n\x1a\n":
            raise ValueError(f"not a PNG: {path}")
        return struct.unpack(">II", data[16:24])
    if suffix in {".jpg", ".jpeg"}:
        return read_jpeg_size(data, path)
    raise ValueError(f"unsupported image type: {path}")


def read_jpeg_size(data: bytes, path: Path) -> tuple[int, int]:
    if data[:2] != b"\xff\xd8":
        raise ValueError(f"not a JPEG: {path}")
    i = 2
    while i < len(data):
        while i < len(data) and data[i] == 0xFF:
            i += 1
        if i >= len(data):
            break
        marker = data[i]
        i += 1
        if marker in {0xD8, 0xD9}:
            continue
        if i + 2 > len(data):
            break
        segment_len = struct.unpack(">H", data[i : i + 2])[0]
        if segment_len < 2 or i + segment_len > len(data):
            break
        if 0xC0 <= marker <= 0xC3:
            start = i + 2
            height = struct.unpack(">H", data[start + 1 : start + 3])[0]
            width = struct.unpack(">H", data[start + 3 : start + 5])[0]
            return width, height
        i += segment_len
    raise ValueError(f"JPEG size not found: {path}")


def log_has(png_or_jpg: Path, needle: str) -> str:
    log = png_or_jpg.with_suffix(".log")
    if not log.exists():
        return "n/a"
    text = log.read_text(encoding="utf-8", errors="ignore")
    return "1" if needle in text else "0"


def group_route_resolution(root: Path, path: Path) -> tuple[str, str, str]:
    rel = path.relative_to(root)
    parts = rel.parts
    if parts[0] == "screenshots":
        group = parts[1]
        if group == "full" and len(parts) >= 4:
            return group, path.stem, parts[2]
        if len(parts) >= 5 and parts[2] in {"full", "smoke"}:
            return group, path.stem, parts[-2]
        if len(parts) >= 5:
            return group, parts[2], parts[3]
        if len(parts) >= 4:
            return group, path.stem, parts[2]
        return group, path.stem, ""
    if parts[0] == "contact_sheets":
        return parts[1], path.stem, ""
    return parts[0], path.stem, ""


def build_manifest(root: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    images = sorted(
        list(root.rglob("*.png"))
        + list(root.rglob("*.jpg"))
        + list(root.rglob("*.jpeg"))
    )
    for path in images:
        width, height = read_image_size(path)
        rel = str(path.relative_to(root))
        group, route, resolution = group_route_resolution(root, path)
        if rel.startswith("screenshots/"):
            kind = "screenshots"
        elif rel.startswith("contact_sheets/"):
            kind = "contact_sheets"
        else:
            kind = path.suffix.lstrip(".")
        rows.append(
            {
                "path": rel,
                "kind": kind,
                "group": group,
                "route": route,
                "resolution": resolution,
                "width": str(width),
                "height": str(height),
                "ready": log_has(path, "VISUAL_ROUTE_READY"),
                "window_id": log_has(path, "VISUAL_CAPTURE: window_id:"),
                "hitbox_enabled": log_has(path, "HITBOX_DEBUG enabled=true"),
            }
        )
    return rows


def split_line_suffix(target: str) -> str:
    match = re.match(r"(.+):(\d+)$", target)
    return match.group(1) if match else target


def looks_like_path(text: str) -> bool:
    if " " in text:
        return False
    if text.startswith(PATH_PREFIXES):
        return True
    return any(
        text.endswith(suffix) or re.match(rf".+\{suffix}:\d+$", text)
        for suffix in PATH_SUFFIXES
    )


def normalize_target(raw: str) -> str | None:
    target = raw.strip().strip("\"'")
    if not target:
        return None
    if target.startswith(
        ("#", "http://", "https://", "mailto:", "data:", "app://", "javascript:")
    ):
        return None
    if any(token in target for token in ("<route_id>", "<", ">", "*", "...")):
        return None
    target = target.split("#", 1)[0].split("?", 1)[0]
    return split_line_suffix(target) if target else None


def resolve_target(
    *,
    root: Path,
    project_root: Path,
    source_file: Path,
    target: str,
) -> Path:
    if target.startswith("/"):
        return Path(target)
    if target.startswith(str(root)):
        return Path(target)
    if target.startswith(("docs/", "lib/", "tools/", "test/", "data/", "assets/")):
        return project_root / target
    return source_file.parent / target


def build_link_check(root: Path, project_root: Path) -> list[dict[str, str]]:
    files = sorted(p for p in root.rglob("*") if p.suffix.lower() in {".md", ".html"})
    rows: list[dict[str, str]] = []
    for source in files:
        text = source.read_text(encoding="utf-8", errors="replace")
        for lineno, line in enumerate(text.splitlines(), 1):
            candidates: list[tuple[str, str]] = []
            candidates.extend(("markdown", m.group(1)) for m in MD_LINK_RE.finditer(line))
            candidates.extend(("html", m.group(1)) for m in HTML_ATTR_RE.finditer(line))
            for match in CODE_RE.finditer(line):
                raw = match.group(1)
                if looks_like_path(raw):
                    candidates.append(("code", raw))
            for kind, raw in candidates:
                target = normalize_target(raw)
                if target is None:
                    continue
                resolved = resolve_target(
                    root=root,
                    project_root=project_root,
                    source_file=source,
                    target=target,
                )
                rows.append(
                    {
                        "file": str(source),
                        "line": str(lineno),
                        "kind": kind,
                        "target": raw,
                        "resolved": str(resolved),
                        "exists": "1" if resolved.exists() else "0",
                    }
                )
    return rows


def iter_local_targets_from_docs(root: Path) -> Iterable[tuple[Path, int, str, str]]:
    files = sorted(p for p in root.rglob("*") if p.suffix.lower() in {".md", ".html"})
    for source in files:
        text = source.read_text(encoding="utf-8", errors="replace")
        for lineno, line in enumerate(text.splitlines(), 1):
            candidates: list[tuple[str, str]] = []
            candidates.extend(("markdown", m.group(1)) for m in MD_LINK_RE.finditer(line))
            candidates.extend(("html", m.group(1)) for m in HTML_ATTR_RE.finditer(line))
            for match in CODE_RE.finditer(line):
                raw = match.group(1)
                if looks_like_path(raw):
                    candidates.append(("code", raw))
            for kind, raw in candidates:
                yield source, lineno, kind, raw


def parse_line_reference(raw: str) -> tuple[str, int] | None:
    target = raw.strip().strip("\"'")
    if target.startswith(
        ("#", "http://", "https://", "mailto:", "data:", "app://", "javascript:")
    ):
        return None
    target = target.split("#", 1)[0].split("?", 1)[0]
    match = LINE_REFERENCE_RE.match(target)
    if not match:
        return None
    return match.group(1), int(match.group(2))


def line_reference_rows(root: Path, project_root: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for source, lineno, kind, raw in iter_local_targets_from_docs(root):
        parsed = parse_line_reference(raw)
        if parsed is None:
            continue
        target, target_line = parsed
        resolved = resolve_target(
            root=root,
            project_root=project_root,
            source_file=source,
            target=target,
        )
        if not resolved.exists():
            line_count = ""
            status = "missing_file"
        else:
            line_count_int = len(
                resolved.read_text(encoding="utf-8", errors="replace").splitlines()
            )
            line_count = str(line_count_int)
            status = "ok" if 1 <= target_line <= line_count_int else "out_of_range"
        rows.append(
            {
                "file": str(source),
                "line": str(lineno),
                "kind": kind,
                "target": raw,
                "resolved": str(resolved),
                "target_line": str(target_line),
                "line_count": line_count,
                "status": status,
            }
        )
    return rows


def write_csv(path: Path, rows: Iterable[dict[str, str]], fieldnames: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as out:
        writer = csv.DictWriter(out, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def count_logs(root: Path, glob: str, needle: str) -> int:
    return sum(
        1
        for log in root.glob(glob)
        if needle in log.read_text(encoding="utf-8", errors="ignore")
    )


def count_png(root: Path, glob: str) -> int:
    return len(list(root.glob(glob)))


def visual_route_ids(project_root: Path) -> list[str]:
    route_file = project_root / "lib/features/debug/application/visual_route.dart"
    if not route_file.exists():
        return []
    text = route_file.read_text(encoding="utf-8")
    return re.findall(r"\n\s*\w+\(\s*'([^']+)'", text)


def expected_route_count(project_root: Path) -> tuple[int | None, int | None]:
    route_ids = visual_route_ids(project_root)
    if not route_ids:
        return None, None
    total = len(route_ids)
    return total, total - (1 if "hub" in route_ids else 0)


def route_coverage_status(row: dict[str, str]) -> str:
    if row["expected"] != "1":
        return "extra"
    required = [
        "1280_png",
        "1280_ready",
        "1440_png",
        "1440_ready",
        "1920_png",
        "1920_ready",
        "1920_window_id",
    ]
    missing = [key for key in required if row.get(key) != "1"]
    return "ok" if not missing else "missing:" + "|".join(missing)


def route_coverage_rows(root: Path, project_root: Path) -> list[dict[str, str]]:
    route_ids = visual_route_ids(project_root)
    expected = set(route_ids) - {"hub"}
    paths = {
        "1280": root / "screenshots/full/1280x720",
        "1440": root / "screenshots/full_1440/full/1440x900",
        "1920": root / "screenshots/full_1920_clean/full/1920x1080",
    }
    captured = {
        key: {path.stem for path in directory.glob("*.png")}
        for key, directory in paths.items()
    }
    captured_routes = set().union(*captured.values()) if captured else set()
    rows: list[dict[str, str]] = []
    for route in sorted(expected | captured_routes):
        row = {
            "route": route,
            "expected": "1" if route in expected else "0",
        }
        for key, directory in paths.items():
            png = directory / f"{route}.png"
            log = directory / f"{route}.log"
            log_text = log.read_text(encoding="utf-8", errors="ignore") if log.exists() else ""
            row[f"{key}_png"] = "1" if png.exists() else "0"
            row[f"{key}_ready"] = "1" if "VISUAL_ROUTE_READY" in log_text else "0"
            if key == "1920":
                row["1920_window_id"] = (
                    "1" if "VISUAL_CAPTURE: window_id:" in log_text else "0"
                )
        row["status"] = route_coverage_status(row)
        rows.append(row)
    return rows


def gallery_stats(root: Path) -> tuple[int, int, int]:
    gallery = root / "visual_gallery.html"
    if not gallery.exists():
        return 0, 0, 0
    text = gallery.read_text(encoding="utf-8", errors="replace")
    sections = len(re.findall(r'<section class="route"', text))
    refs = re.findall(r"<img[^>]+src=[\"']([^\"']+)[\"']", text)
    missing = sum(1 for src in refs if not (gallery.parent / src).exists())
    return sections, len(refs), missing


def issue_backlog_rows(root: Path) -> int:
    backlog = root / "issue_backlog.csv"
    if not backlog.exists():
        return 0
    with backlog.open(encoding="utf-8") as f:
        return max(0, sum(1 for _ in f) - 1)


def issue_evidence_rows(root: Path) -> list[dict[str, str]]:
    backlog = root / "issue_backlog.csv"
    if not backlog.exists():
        return []
    evidence_columns = [
        "evidence_1280",
        "evidence_1440",
        "evidence_1920",
        "risk_evidence",
        "hitbox_evidence",
    ]
    required_columns = {
        "evidence_1280",
        "evidence_1440",
        "evidence_1920",
        "risk_evidence",
    }
    rows: list[dict[str, str]] = []
    with backlog.open(encoding="utf-8") as f:
        for issue in csv.DictReader(f):
            for column in evidence_columns:
                evidence_path = (issue.get(column) or "").strip()
                required = column in required_columns
                if not evidence_path:
                    status = "empty_required" if required else "optional_empty"
                    exists = "0" if required else "n/a"
                else:
                    exists = "1" if (root / evidence_path).exists() else "0"
                    status = "ok" if exists == "1" else "missing"
                rows.append(
                    {
                        "severity": issue.get("severity", ""),
                        "route": issue.get("route", ""),
                        "column": column,
                        "required": "1" if required else "0",
                        "evidence_path": evidence_path,
                        "exists": exists,
                        "status": status,
                    }
                )
    return rows


def issue_severity_counts(root: Path) -> dict[str, int]:
    backlog = root / "issue_backlog.csv"
    counts: dict[str, int] = {}
    if not backlog.exists():
        return counts
    with backlog.open(encoding="utf-8") as f:
        for issue in csv.DictReader(f):
            severity = issue.get("severity", "")
            counts[severity] = counts.get(severity, 0) + 1
    return counts


def issue_backlog_issues(root: Path) -> list[dict[str, str]]:
    backlog = root / "issue_backlog.csv"
    if not backlog.exists():
        return []
    with backlog.open(encoding="utf-8") as f:
        return list(csv.DictReader(f))


def issue_traceability_rows(root: Path) -> list[dict[str, str]]:
    issues = issue_backlog_issues(root)
    documents = {
        "issue_owner_map": root / "issue_owner_map.md",
        "claude_visual_fix_prompt": root / "claude_visual_fix_prompt.md",
        "report": root / "report.md",
        "page_review_matrix": root / "page_review_matrix.md",
    }
    texts = {
        name: path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""
        for name, path in documents.items()
    }
    rows: list[dict[str, str]] = []
    for issue in issues:
        route = issue.get("route", "")
        severity = issue.get("severity", "")
        presence = {
            name: "1" if route and route in text else "0"
            for name, text in texts.items()
        }
        missing = [name for name, value in presence.items() if value != "1"]
        rows.append(
            {
                "severity": severity,
                "route": route,
                "issue_owner_map": presence["issue_owner_map"],
                "claude_visual_fix_prompt": presence["claude_visual_fix_prompt"],
                "report": presence["report"],
                "page_review_matrix": presence["page_review_matrix"],
                "status": "ok" if not missing else "missing:" + "|".join(missing),
            }
        )
    return rows


def issue_quality_rows(root: Path) -> list[dict[str, str]]:
    issues = issue_backlog_issues(root)
    rows: list[dict[str, str]] = []
    counts: dict[str, int] = {}
    for issue in issues:
        severity = issue.get("severity", "")
        route = issue.get("route", "")
        counts[severity] = counts.get(severity, 0) + 1
        missing = [
            field
            for field in REQUIRED_ISSUE_FIELDS
            if not (issue.get(field) or "").strip()
        ]
        if severity not in EXPECTED_ISSUE_COUNTS:
            missing.append("valid_severity")
        rows.append(
            {
                "kind": "issue",
                "severity": severity,
                "route": route,
                "expected": "",
                "actual": "",
                "status": "ok" if not missing else "missing:" + "|".join(missing),
            }
        )
    for severity, expected in EXPECTED_ISSUE_COUNTS.items():
        actual = counts.get(severity, 0)
        rows.append(
            {
                "kind": "severity_count",
                "severity": severity,
                "route": "",
                "expected": str(expected),
                "actual": str(actual),
                "status": "ok" if actual == expected else "count_mismatch",
            }
        )
    unexpected = sorted(set(counts) - set(EXPECTED_ISSUE_COUNTS))
    for severity in unexpected:
        rows.append(
            {
                "kind": "unexpected_severity",
                "severity": severity,
                "route": "",
                "expected": "0",
                "actual": str(counts[severity]),
                "status": "unexpected",
            }
        )
    return rows


def hitbox_coverage_rows(root: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for group, routes in EXPECTED_HITBOX_ROUTES.items():
        for route in routes:
            png = root / f"screenshots/{group}/{route}/1280x720/{route}.png"
            log = png.with_suffix(".log")
            log_text = log.read_text(encoding="utf-8", errors="ignore") if log.exists() else ""
            checks = {
                "png": "1" if png.exists() else "0",
                "log": "1" if log.exists() else "0",
                "ready": "1" if "VISUAL_ROUTE_READY" in log_text else "0",
                "hitbox_enabled": "1" if "HITBOX_DEBUG enabled=true" in log_text else "0",
            }
            missing = [key for key, value in checks.items() if value != "1"]
            rows.append(
                {
                    "group": group,
                    "route": route,
                    **checks,
                    "status": "ok" if not missing else "missing:" + "|".join(missing),
                }
            )
    return rows


def contact_sheet_rows(root: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for filename in EXPECTED_CONTACT_SHEETS:
        path = root / "contact_sheets" / filename
        if not path.exists():
            width = ""
            height = ""
            status = "missing"
        else:
            try:
                width_int, height_int = read_image_size(path)
                width = str(width_int)
                height = str(height_int)
                status = "ok" if width_int > 0 and height_int > 0 else "invalid_size"
            except Exception:
                width = ""
                height = ""
                status = "unreadable"
        rows.append(
            {
                "contact_sheet": f"contact_sheets/{filename}",
                "exists": "1" if path.exists() else "0",
                "width": width,
                "height": height,
                "status": status,
            }
        )
    return rows


def required_artifact_rows(root: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for rel in REQUIRED_ARTIFACTS:
        path = root / rel
        rows.append(
            {
                "artifact": rel,
                "exists": "1" if path.exists() else "0",
                "status": "ok" if path.exists() else "missing",
            }
        )
    return rows


def screenshot_dimension_rows(root: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for glob, expected_width, expected_height in EXPECTED_SCREENSHOT_DIMS:
        for path in sorted(root.glob(glob)):
            actual_width, actual_height = read_image_size(path)
            status = (
                "ok"
                if actual_width == expected_width and actual_height == expected_height
                else "mismatch"
            )
            rows.append(
                {
                    "path": str(path.relative_to(root)),
                    "expected_width": str(expected_width),
                    "expected_height": str(expected_height),
                    "actual_width": str(actual_width),
                    "actual_height": str(actual_height),
                    "status": status,
                }
            )
    return rows


def read_route_index_severities(root: Path) -> dict[str, str]:
    path = root / "route_screenshot_index.csv"
    if not path.exists():
        return {}
    with path.open(encoding="utf-8") as f:
        return {
            row.get("route", ""): row.get("severity", "")
            for row in csv.DictReader(f)
            if row.get("route")
        }


def read_issue_backlog_severities(root: Path) -> dict[str, str]:
    path = root / "issue_backlog.csv"
    if not path.exists():
        return {}
    with path.open(encoding="utf-8") as f:
        return {
            row.get("route", ""): row.get("severity", "")
            for row in csv.DictReader(f)
            if row.get("route")
        }


def read_page_matrix_severities(root: Path) -> dict[str, str]:
    path = root / "page_review_matrix.md"
    if not path.exists():
        return {}
    rows: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = line.strip()
        if not stripped.startswith("|") or "`" not in stripped:
            continue
        cells = [cell.strip() for cell in stripped.strip("|").split("|")]
        if len(cells) < 3:
            continue
        route = cells[1].strip("` ")
        severity = cells[2].strip("` ")
        if route and severity and route != "route":
            rows[route] = severity
    return rows


def severity_consistency_rows(root: Path) -> list[dict[str, str]]:
    route_index = read_route_index_severities(root)
    issue_backlog = read_issue_backlog_severities(root)
    page_matrix = read_page_matrix_severities(root)
    routes = sorted(set(route_index) | set(issue_backlog) | set(page_matrix))
    rows: list[dict[str, str]] = []
    for route in routes:
        index_severity = route_index.get(route, "")
        issue_severity = issue_backlog.get(route, "")
        matrix_severity = page_matrix.get(route, "")
        statuses: list[str] = []
        if not index_severity:
            statuses.append("missing_route_index")
        if not matrix_severity:
            statuses.append("missing_page_matrix")
        if index_severity and matrix_severity and index_severity != matrix_severity:
            statuses.append("matrix_mismatch")
        is_issue = index_severity in {"P1", "P2", "P3"}
        if is_issue and not issue_severity:
            statuses.append("missing_issue_backlog")
        if issue_severity and not is_issue:
            statuses.append("unexpected_issue_backlog")
        if issue_severity and index_severity and issue_severity != index_severity:
            statuses.append("issue_mismatch")
        rows.append(
            {
                "route": route,
                "route_index_severity": index_severity,
                "page_matrix_severity": matrix_severity,
                "issue_backlog_severity": issue_severity,
                "status": "ok" if not statuses else "|".join(statuses),
            }
        )
    return rows


def build_summary(
    *,
    root: Path,
    project_root: Path,
    manifest_rows: list[dict[str, str]],
    link_rows: list[dict[str, str]],
    coverage_rows: list[dict[str, str]],
    issue_rows: list[dict[str, str]],
    required_rows: list[dict[str, str]],
    dimension_rows: list[dict[str, str]],
    severity_rows: list[dict[str, str]],
    line_reference_rows_: list[dict[str, str]],
    traceability_rows: list[dict[str, str]],
    issue_quality_rows_: list[dict[str, str]],
    hitbox_rows: list[dict[str, str]],
    contact_sheet_rows_: list[dict[str, str]],
) -> str:
    pngs = [r for r in manifest_rows if r["path"].endswith(".png")]
    jpgs = [
        r
        for r in manifest_rows
        if r["path"].endswith(".jpg") or r["path"].endswith(".jpeg")
    ]
    md_html_count = len(
        [p for p in root.rglob("*") if p.suffix.lower() in {".md", ".html"}]
    )
    broken_links = sum(1 for row in link_rows if row["exists"] != "1")
    gallery_sections, gallery_refs, gallery_missing = gallery_stats(root)
    route_total, expected_without_hub = expected_route_count(project_root)
    expected_full = expected_without_hub or 59
    coverage_ok = sum(1 for row in coverage_rows if row["status"] == "ok")
    coverage_bad = [row for row in coverage_rows if row["status"] != "ok"]
    issue_evidence_errors = sum(
        1 for row in issue_rows if row["required"] == "1" and row["status"] != "ok"
    )
    required_artifact_errors = sum(1 for row in required_rows if row["status"] != "ok")
    dimension_errors = sum(1 for row in dimension_rows if row["status"] != "ok")
    severity_errors = sum(1 for row in severity_rows if row["status"] != "ok")
    line_reference_errors = sum(
        1 for row in line_reference_rows_ if row["status"] != "ok"
    )
    traceability_errors = sum(1 for row in traceability_rows if row["status"] != "ok")
    issue_quality_errors = sum(
        1 for row in issue_quality_rows_ if row["status"] != "ok"
    )
    hitbox_errors = sum(1 for row in hitbox_rows if row["status"] != "ok")
    contact_sheet_errors = sum(
        1 for row in contact_sheet_rows_ if row["status"] != "ok"
    )
    issue_counts = issue_severity_counts(root)

    dim_counts: dict[str, int] = {}
    group_counts: dict[str, int] = {}
    for row in pngs:
        dim = f"{row['width']}x{row['height']}"
        dim_counts[dim] = dim_counts.get(dim, 0) + 1
        group = row["group"]
        group_counts[group] = group_counts.get(group, 0) + 1

    lines = [
        "# Visual Acceptance Verification Summary",
        "",
        "Generated from current filesystem artifacts and route logs.",
        "",
        "## Artifact Counts",
        "",
        f"- PNG screenshots: {len(pngs)}",
        f"- JPG contact sheets: {len(jpgs)}",
        f"- Markdown/HTML files checked: {md_html_count}",
        f"- Local links/assets checked: {len(link_rows)}",
        f"- Broken local links/assets: {broken_links}",
        f"- Gallery route sections: {gallery_sections}",
        f"- Gallery image refs: {gallery_refs}; missing: {gallery_missing}",
        f"- Issue backlog rows: {issue_backlog_rows(root)}",
        f"- Required core artifact errors: {required_artifact_errors}",
        f"- Screenshot dimension errors: {dimension_errors}",
        f"- Severity consistency errors: {severity_errors}",
        f"- Line reference errors: {line_reference_errors}",
        f"- Issue traceability errors: {traceability_errors}",
        f"- Issue quality errors: {issue_quality_errors}",
        f"- Hitbox coverage errors: {hitbox_errors}",
        f"- Contact sheet errors: {contact_sheet_errors}",
        (
            "- Issue severities: "
            f"P1={issue_counts.get('P1', 0)}, "
            f"P2={issue_counts.get('P2', 0)}, "
            f"P3={issue_counts.get('P3', 0)}"
        ),
    ]
    if route_total is not None:
        lines.append(
            f"- VisualRoute enum ids: {route_total}; expected full matrix excluding hub: {expected_full}",
        )
    lines.extend(
        [
            "",
            "## Full Route Matrices",
            "",
            (
                f"- Full 1280 screenshots: {count_png(root, 'screenshots/full/1280x720/*.png')}/{expected_full}; "
                f"READY: {count_logs(root, 'screenshots/full/1280x720/*.log', 'VISUAL_ROUTE_READY')}/{expected_full}"
            ),
            (
                f"- Full 1440 screenshots: {count_png(root, 'screenshots/full_1440/full/1440x900/*.png')}/{expected_full}; "
                f"READY: {count_logs(root, 'screenshots/full_1440/full/1440x900/*.log', 'VISUAL_ROUTE_READY')}/{expected_full}"
            ),
            (
                f"- Full clean 1920 screenshots: {count_png(root, 'screenshots/full_1920_clean/full/1920x1080/*.png')}/{expected_full}; "
                f"READY: {count_logs(root, 'screenshots/full_1920_clean/full/1920x1080/*.log', 'VISUAL_ROUTE_READY')}/{expected_full}; "
                f"window_id: {count_logs(root, 'screenshots/full_1920_clean/full/1920x1080/*.log', 'VISUAL_CAPTURE: window_id:')}/{expected_full}"
            ),
            (
                "- Strong hitbox screenshots: "
                f"{count_png(root, 'screenshots/hitbox_strong/*/1280x720/*.png')}/8; "
                f"hitbox enabled: {count_logs(root, 'screenshots/hitbox_strong/*/1280x720/*.log', 'HITBOX_DEBUG enabled=true')}/8"
            ),
            (
                "- Extra hitbox screenshots: "
                f"{count_png(root, 'screenshots/hitbox_extra/*/1280x720/*.png')}/8; "
                f"hitbox enabled: {count_logs(root, 'screenshots/hitbox_extra/*/1280x720/*.log', 'HITBOX_DEBUG enabled=true')}/8"
            ),
            f"- Route coverage rows OK: {coverage_ok}/{expected_full}; non-ok: {len(coverage_bad)}",
            f"- Required issue evidence errors: {issue_evidence_errors}",
            f"- Required core artifact errors: {required_artifact_errors}",
            f"- Screenshot dimension errors: {dimension_errors}",
            f"- Severity consistency errors: {severity_errors}",
            f"- Line reference errors: {line_reference_errors}",
            f"- Issue traceability errors: {traceability_errors}",
            f"- Issue quality errors: {issue_quality_errors}",
            f"- Hitbox coverage errors: {hitbox_errors}",
            f"- Contact sheet errors: {contact_sheet_errors}",
            "",
            "## PNG Dimensions",
            "",
        ]
    )
    for dim, count in sorted(dim_counts.items()):
        lines.append(f"- {dim}: {count}")
    lines.extend(["", "## Screenshot Groups", ""])
    for group, count in sorted(group_counts.items()):
        lines.append(f"- {group}: {count}")
    lines.extend(
        [
            "",
            "## Manifests",
            "",
            "- `artifact_manifest.csv`",
            "- `markdown_link_check.csv`",
            "- `route_coverage_check.csv`",
            "- `issue_evidence_check.csv`",
            "- `required_artifact_check.csv`",
            "- `screenshot_dimension_check.csv`",
            "- `severity_consistency_check.csv`",
            "- `line_reference_check.csv`",
            "- `issue_traceability_check.csv`",
            "- `issue_quality_check.csv`",
            "- `hitbox_coverage_check.csv`",
            "- `contact_sheet_check.csv`",
        ]
    )
    return "\n".join(lines) + "\n"


def build_status(
    *,
    root: Path,
    project_root: Path,
    manifest_rows: list[dict[str, str]],
    link_rows: list[dict[str, str]],
    coverage_rows: list[dict[str, str]],
    issue_rows: list[dict[str, str]],
    required_rows: list[dict[str, str]],
    dimension_rows: list[dict[str, str]],
    severity_rows: list[dict[str, str]],
    line_reference_rows_: list[dict[str, str]],
    traceability_rows: list[dict[str, str]],
    issue_quality_rows_: list[dict[str, str]],
    hitbox_rows: list[dict[str, str]],
    contact_sheet_rows_: list[dict[str, str]],
) -> dict[str, object]:
    png_count = sum(1 for row in manifest_rows if row["path"].endswith(".png"))
    jpg_count = sum(
        1
        for row in manifest_rows
        if row["path"].endswith(".jpg") or row["path"].endswith(".jpeg")
    )
    md_html_count = len(
        [p for p in root.rglob("*") if p.suffix.lower() in {".md", ".html"}]
    )
    broken_links = sum(1 for row in link_rows if row["exists"] != "1")
    route_errors = sum(1 for row in coverage_rows if row["status"] != "ok")
    coverage_ok = sum(1 for row in coverage_rows if row["status"] == "ok")
    issue_evidence_errors = sum(
        1 for row in issue_rows if row["required"] == "1" and row["status"] != "ok"
    )
    required_artifact_errors = sum(1 for row in required_rows if row["status"] != "ok")
    dimension_errors = sum(1 for row in dimension_rows if row["status"] != "ok")
    severity_errors = sum(1 for row in severity_rows if row["status"] != "ok")
    line_reference_errors = sum(
        1 for row in line_reference_rows_ if row["status"] != "ok"
    )
    traceability_errors = sum(1 for row in traceability_rows if row["status"] != "ok")
    issue_quality_errors = sum(
        1 for row in issue_quality_rows_ if row["status"] != "ok"
    )
    hitbox_errors = sum(1 for row in hitbox_rows if row["status"] != "ok")
    contact_sheet_errors = sum(
        1 for row in contact_sheet_rows_ if row["status"] != "ok"
    )
    issue_counts = issue_severity_counts(root)
    gallery_sections, gallery_refs, gallery_missing = gallery_stats(root)
    route_total, expected_without_hub = expected_route_count(project_root)
    expected_full = expected_without_hub or 59
    return {
        "artifact_root": str(root),
        "images": len(manifest_rows),
        "png_screenshots": png_count,
        "jpg_contact_sheets": jpg_count,
        "markdown_html_files": md_html_count,
        "local_links_assets_checked": len(link_rows),
        "broken_links": broken_links,
        "visual_route_enum_ids": route_total,
        "expected_full_routes_excluding_hub": expected_full,
        "route_coverage_ok": coverage_ok,
        "route_coverage_errors": route_errors,
        "gallery_route_sections": gallery_sections,
        "gallery_image_refs": gallery_refs,
        "gallery_missing": gallery_missing,
        "issue_backlog_rows": issue_backlog_rows(root),
        "issue_severity_counts": issue_counts,
        "issue_evidence_rows": len(issue_rows),
        "issue_evidence_errors": issue_evidence_errors,
        "required_artifact_rows": len(required_rows),
        "required_artifact_errors": required_artifact_errors,
        "screenshot_dimension_rows": len(dimension_rows),
        "screenshot_dimension_errors": dimension_errors,
        "severity_consistency_rows": len(severity_rows),
        "severity_consistency_errors": severity_errors,
        "line_reference_rows": len(line_reference_rows_),
        "line_reference_errors": line_reference_errors,
        "issue_traceability_rows": len(traceability_rows),
        "issue_traceability_errors": traceability_errors,
        "issue_quality_rows": len(issue_quality_rows_),
        "issue_quality_errors": issue_quality_errors,
        "hitbox_coverage_rows": len(hitbox_rows),
        "hitbox_coverage_errors": hitbox_errors,
        "contact_sheet_rows": len(contact_sheet_rows_),
        "contact_sheet_errors": contact_sheet_errors,
        "full_1280_png": count_png(root, "screenshots/full/1280x720/*.png"),
        "full_1280_ready": count_logs(
            root,
            "screenshots/full/1280x720/*.log",
            "VISUAL_ROUTE_READY",
        ),
        "full_1440_png": count_png(
            root,
            "screenshots/full_1440/full/1440x900/*.png",
        ),
        "full_1440_ready": count_logs(
            root,
            "screenshots/full_1440/full/1440x900/*.log",
            "VISUAL_ROUTE_READY",
        ),
        "full_1920_png": count_png(
            root,
            "screenshots/full_1920_clean/full/1920x1080/*.png",
        ),
        "full_1920_ready": count_logs(
            root,
            "screenshots/full_1920_clean/full/1920x1080/*.log",
            "VISUAL_ROUTE_READY",
        ),
        "full_1920_window_id": count_logs(
            root,
            "screenshots/full_1920_clean/full/1920x1080/*.log",
            "VISUAL_CAPTURE: window_id:",
        ),
        "strong_hitbox_png": count_png(
            root,
            "screenshots/hitbox_strong/*/1280x720/*.png",
        ),
        "strong_hitbox_enabled": count_logs(
            root,
            "screenshots/hitbox_strong/*/1280x720/*.log",
            "HITBOX_DEBUG enabled=true",
        ),
        "extra_hitbox_png": count_png(
            root,
            "screenshots/hitbox_extra/*/1280x720/*.png",
        ),
        "extra_hitbox_enabled": count_logs(
            root,
            "screenshots/hitbox_extra/*/1280x720/*.log",
            "HITBOX_DEBUG enabled=true",
        ),
        "ok": (
            broken_links == 0
            and route_errors == 0
            and gallery_missing == 0
            and issue_evidence_errors == 0
            and required_artifact_errors == 0
            and dimension_errors == 0
            and severity_errors == 0
            and line_reference_errors == 0
            and traceability_errors == 0
            and issue_quality_errors == 0
            and hitbox_errors == 0
            and contact_sheet_errors == 0
        ),
    }


def main() -> int:
    args = parse_args()
    root = args.artifact_root.resolve()
    project_root = args.project_root.resolve()
    if not root.exists():
        raise SystemExit(f"artifact root does not exist: {root}")

    manifest_rows = build_manifest(root)
    write_csv(
        root / "artifact_manifest.csv",
        manifest_rows,
        [
            "path",
            "kind",
            "group",
            "route",
            "resolution",
            "width",
            "height",
            "ready",
            "window_id",
            "hitbox_enabled",
        ],
    )

    link_rows = build_link_check(root, project_root)
    write_csv(
        root / "markdown_link_check.csv",
        link_rows,
        ["file", "line", "kind", "target", "resolved", "exists"],
    )

    coverage_rows = route_coverage_rows(root, project_root)
    write_csv(
        root / "route_coverage_check.csv",
        coverage_rows,
        [
            "route",
            "expected",
            "1280_png",
            "1280_ready",
            "1440_png",
            "1440_ready",
            "1920_png",
            "1920_ready",
            "1920_window_id",
            "status",
        ],
    )

    issue_rows = issue_evidence_rows(root)
    write_csv(
        root / "issue_evidence_check.csv",
        issue_rows,
        [
            "severity",
            "route",
            "column",
            "required",
            "evidence_path",
            "exists",
            "status",
        ],
    )

    dimension_rows = screenshot_dimension_rows(root)
    write_csv(
        root / "screenshot_dimension_check.csv",
        dimension_rows,
        [
            "path",
            "expected_width",
            "expected_height",
            "actual_width",
            "actual_height",
            "status",
        ],
    )

    severity_rows = severity_consistency_rows(root)
    write_csv(
        root / "severity_consistency_check.csv",
        severity_rows,
        [
            "route",
            "route_index_severity",
            "page_matrix_severity",
            "issue_backlog_severity",
            "status",
        ],
    )

    line_rows = line_reference_rows(root, project_root)
    write_csv(
        root / "line_reference_check.csv",
        line_rows,
        [
            "file",
            "line",
            "kind",
            "target",
            "resolved",
            "target_line",
            "line_count",
            "status",
        ],
    )

    traceability_rows = issue_traceability_rows(root)
    write_csv(
        root / "issue_traceability_check.csv",
        traceability_rows,
        [
            "severity",
            "route",
            "issue_owner_map",
            "claude_visual_fix_prompt",
            "report",
            "page_review_matrix",
            "status",
        ],
    )

    quality_rows = issue_quality_rows(root)
    write_csv(
        root / "issue_quality_check.csv",
        quality_rows,
        ["kind", "severity", "route", "expected", "actual", "status"],
    )

    hitbox_rows = hitbox_coverage_rows(root)
    write_csv(
        root / "hitbox_coverage_check.csv",
        hitbox_rows,
        ["group", "route", "png", "log", "ready", "hitbox_enabled", "status"],
    )

    contact_rows = contact_sheet_rows(root)
    write_csv(
        root / "contact_sheet_check.csv",
        contact_rows,
        ["contact_sheet", "exists", "width", "height", "status"],
    )

    required_rows = required_artifact_rows(root)
    write_csv(
        root / "required_artifact_check.csv",
        required_rows,
        ["artifact", "exists", "status"],
    )

    summary = build_summary(
        root=root,
        project_root=project_root,
        manifest_rows=manifest_rows,
        link_rows=link_rows,
        coverage_rows=coverage_rows,
        issue_rows=issue_rows,
        required_rows=required_rows,
        dimension_rows=dimension_rows,
        severity_rows=severity_rows,
        line_reference_rows_=line_rows,
        traceability_rows=traceability_rows,
        issue_quality_rows_=quality_rows,
        hitbox_rows=hitbox_rows,
        contact_sheet_rows_=contact_rows,
    )
    (root / "verification_summary.md").write_text(summary, encoding="utf-8")
    status = build_status(
        root=root,
        project_root=project_root,
        manifest_rows=manifest_rows,
        link_rows=link_rows,
        coverage_rows=coverage_rows,
        issue_rows=issue_rows,
        required_rows=required_rows,
        dimension_rows=dimension_rows,
        severity_rows=severity_rows,
        line_reference_rows_=line_rows,
        traceability_rows=traceability_rows,
        issue_quality_rows_=quality_rows,
        hitbox_rows=hitbox_rows,
        contact_sheet_rows_=contact_rows,
    )
    (root / "visual_acceptance_status.json").write_text(
        json.dumps(status, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        "visual audit: "
        f"images={status['images']} links={status['local_links_assets_checked']} "
        f"broken={status['broken_links']} route_errors={status['route_coverage_errors']} "
        f"gallery_missing={status['gallery_missing']} "
        f"issue_evidence_errors={status['issue_evidence_errors']} "
        f"required_artifact_errors={status['required_artifact_errors']} "
        f"screenshot_dimension_errors={status['screenshot_dimension_errors']} "
        f"severity_consistency_errors={status['severity_consistency_errors']} "
        f"line_reference_errors={status['line_reference_errors']} "
        f"issue_traceability_errors={status['issue_traceability_errors']} "
        f"issue_quality_errors={status['issue_quality_errors']} "
        f"hitbox_coverage_errors={status['hitbox_coverage_errors']} "
        f"contact_sheet_errors={status['contact_sheet_errors']}",
    )
    return 0 if status["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
