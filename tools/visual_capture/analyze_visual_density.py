#!/usr/bin/env python3
"""Generate second-pass visual density signals from screenshot artifacts."""

from __future__ import annotations

import csv
import math
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


@dataclass
class Metric:
    route: str
    severity: str
    variant: str
    image_path: Path
    width: int
    height: int
    bbox_left_pct: float
    bbox_top_pct: float
    bbox_right_pct: float
    bbox_bottom_pct: float
    bbox_width_pct: float
    bbox_height_pct: float
    edge_density: float
    bottom_edge_density: float
    light_low_contrast_ratio: float
    dark_empty_ratio: float
    left_dark_empty_ratio: float
    right_dark_empty_ratio: float
    active_left_pct: float
    active_right_pct: float
    active_width_pct: float
    signal: str
    note: str


VARIANT_COLUMNS = {
    "1280": "full_1280_png",
    "1440": "full_1440_png",
    "1920": "full_1920_png",
}


def pct(value: float) -> str:
    return f"{value:.3f}"


def load_routes(root: Path) -> list[dict[str, str]]:
    index = root / "route_screenshot_index.csv"
    with index.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def image_mask(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    arr = rgb.astype(np.float32)
    gray = arr.mean(axis=2)
    chroma = arr.max(axis=2) - arr.min(axis=2)

    corners = np.concatenate(
        [
            arr[:60, :60].reshape(-1, 3),
            arr[:60, -60:].reshape(-1, 3),
            arr[-60:, :60].reshape(-1, 3),
            arr[-60:, -60:].reshape(-1, 3),
        ]
    )
    bg = np.median(corners, axis=0)
    distance = np.sqrt(((arr - bg) ** 2).sum(axis=2))

    gx = np.zeros_like(gray)
    gy = np.zeros_like(gray)
    gx[:, 1:] = np.abs(gray[:, 1:] - gray[:, :-1])
    gy[1:, :] = np.abs(gray[1:, :] - gray[:-1, :])
    edges = np.maximum(gx, gy)

    mask = (distance > 24) | (edges > 22) | (chroma > 34)
    mask[:8, :] = False
    mask[-8:, :] = False
    mask[:, :8] = False
    mask[:, -8:] = False

    for _ in range(2):
        grown = mask.copy()
        grown[:-1, :] |= mask[1:, :]
        grown[1:, :] |= mask[:-1, :]
        grown[:, :-1] |= mask[:, 1:]
        grown[:, 1:] |= mask[:, :-1]
        mask = grown

    return mask, edges, gray


def bbox_from_mask(mask: np.ndarray) -> tuple[int, int, int, int]:
    ys, xs = np.where(mask)
    if len(xs) == 0 or len(ys) == 0:
        return 0, 0, 0, 0
    return int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)


def analyze_image(root: Path, row: dict[str, str], variant: str, column: str) -> Metric | None:
    rel = row.get(column, "")
    if not rel:
        return None
    image_path = root / rel
    if not image_path.exists():
        return None

    with Image.open(image_path) as img:
        rgb_image = img.convert("RGB")
        rgb = np.asarray(rgb_image)
    height, width = rgb.shape[:2]
    mask, edges, gray = image_mask(rgb)
    left, top, right, bottom = bbox_from_mask(mask)

    edge_mask = edges > max(18, float(edges.mean() + edges.std() * 0.75))
    edge_density = float(edge_mask.mean())
    bottom_edge_density = float(edge_mask[int(height * 0.78) :, :].mean())
    light_area = (gray > 118) & (gray < 230)
    light_low_contrast = light_area & (edges < 12)
    light_low_contrast_ratio = float(light_low_contrast.mean())
    low_edge = edges < 9
    dark_empty = (gray < 30) & low_edge
    dark_empty_ratio = float(dark_empty.mean())
    left_dark_empty_ratio = float(dark_empty[:, : width // 3].mean())
    right_dark_empty_ratio = float(dark_empty[:, width * 2 // 3 :].mean())

    active_area = edges[int(height * 0.06) :, :]
    active_threshold = max(20.0, float(np.percentile(active_area, 92)))
    active_edges = active_area > active_threshold
    col_weight = active_edges.sum(axis=0).astype(np.float64)
    if col_weight.sum() > 0:
        cumsum = np.cumsum(col_weight)
        total = cumsum[-1]
        active_left = int(np.searchsorted(cumsum, total * 0.05))
        active_right = int(np.searchsorted(cumsum, total * 0.95))
    else:
        active_left = left
        active_right = right
    active_left_pct = active_left / width
    active_right_pct = (width - active_right) / width
    active_width_pct = max(0.0, (active_right - active_left) / width)

    bbox_left_pct = left / width
    bbox_top_pct = top / height
    bbox_right_pct = (width - right) / width
    bbox_bottom_pct = (height - bottom) / height
    bbox_width_pct = (right - left) / width
    bbox_height_pct = (bottom - top) / height

    signals: list[str] = []
    if variant == "1920" and right_dark_empty_ratio > 0.72 and active_width_pct < 0.70:
        signals.append("wide_right_dark_empty")
    if variant == "1920" and left_dark_empty_ratio > 0.72 and active_width_pct < 0.70:
        signals.append("wide_left_dark_empty")
    if active_width_pct < 0.48 and dark_empty_ratio > 0.42:
        signals.append("narrow_active_content")
    if bbox_top_pct > 0.16:
        signals.append("late_first_screen_entry")
    if bottom_edge_density > edge_density * 1.7 and bottom_edge_density > 0.055:
        signals.append("bottom_hud_density")
    if light_low_contrast_ratio > 0.35:
        signals.append("paper_contrast_review")

    note = row.get("note", "")
    return Metric(
        route=row["route"],
        severity=row.get("severity", ""),
        variant=variant,
        image_path=image_path,
        width=width,
        height=height,
        bbox_left_pct=bbox_left_pct,
        bbox_top_pct=bbox_top_pct,
        bbox_right_pct=bbox_right_pct,
        bbox_bottom_pct=bbox_bottom_pct,
        bbox_width_pct=bbox_width_pct,
        bbox_height_pct=bbox_height_pct,
        edge_density=edge_density,
        bottom_edge_density=bottom_edge_density,
        light_low_contrast_ratio=light_low_contrast_ratio,
        dark_empty_ratio=dark_empty_ratio,
        left_dark_empty_ratio=left_dark_empty_ratio,
        right_dark_empty_ratio=right_dark_empty_ratio,
        active_left_pct=active_left_pct,
        active_right_pct=active_right_pct,
        active_width_pct=active_width_pct,
        signal=";".join(signals) if signals else "ok",
        note=note,
    )


def write_metrics(root: Path, metrics: list[Metric]) -> None:
    path = root / "second_pass_visual_metrics.csv"
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            [
                "route",
                "severity",
                "variant",
                "image",
                "width",
                "height",
                "bbox_left_pct",
                "bbox_top_pct",
                "bbox_right_pct",
                "bbox_bottom_pct",
                "bbox_width_pct",
                "bbox_height_pct",
                "edge_density",
                "bottom_edge_density",
                "light_low_contrast_ratio",
                "dark_empty_ratio",
                "left_dark_empty_ratio",
                "right_dark_empty_ratio",
                "active_left_pct",
                "active_right_pct",
                "active_width_pct",
                "signal",
                "note",
            ]
        )
        for m in metrics:
            writer.writerow(
                [
                    m.route,
                    m.severity,
                    m.variant,
                    m.image_path.relative_to(root).as_posix(),
                    m.width,
                    m.height,
                    pct(m.bbox_left_pct),
                    pct(m.bbox_top_pct),
                    pct(m.bbox_right_pct),
                    pct(m.bbox_bottom_pct),
                    pct(m.bbox_width_pct),
                    pct(m.bbox_height_pct),
                    pct(m.edge_density),
                    pct(m.bottom_edge_density),
                    pct(m.light_low_contrast_ratio),
                    pct(m.dark_empty_ratio),
                    pct(m.left_dark_empty_ratio),
                    pct(m.right_dark_empty_ratio),
                    pct(m.active_left_pct),
                    pct(m.active_right_pct),
                    pct(m.active_width_pct),
                    m.signal,
                    m.note,
                ]
            )


def signal_score(metric: Metric) -> tuple[int, float]:
    if metric.signal == "ok":
        return (0, 0.0)
    severity_weight = {"P1": 5, "P2": 4, "P3": 3, "PASS+": 1, "PASS": 1}.get(metric.severity, 1)
    signal_weight = len(metric.signal.split(";"))
    shape_weight = (
        max(metric.left_dark_empty_ratio, metric.right_dark_empty_ratio)
        + metric.dark_empty_ratio
        + (1.0 - metric.active_width_pct)
    )
    return (severity_weight + signal_weight, shape_weight)


def write_contact_sheet(root: Path, flagged: list[Metric]) -> Path | None:
    if not flagged:
        return None
    contact_dir = root / "contact_sheets"
    contact_dir.mkdir(parents=True, exist_ok=True)
    output = contact_dir / "second_pass_machine_flags.jpg"

    thumbs: list[tuple[Metric, Image.Image]] = []
    for metric in flagged[:12]:
        with Image.open(metric.image_path) as img:
            thumb = img.convert("RGB")
            thumb.thumbnail((420, 236))
            canvas = Image.new("RGB", (420, 286), (22, 20, 18))
            canvas.paste(thumb, ((420 - thumb.width) // 2, 0))
            draw = ImageDraw.Draw(canvas)
            label = f"{metric.route} [{metric.variant}] {metric.severity}"
            draw.text((10, 242), label[:56], fill=(235, 226, 207))
            draw.text((10, 264), metric.signal[:64], fill=(204, 164, 96))
            thumbs.append((metric, canvas))

    cols = 3
    rows = math.ceil(len(thumbs) / cols)
    sheet = Image.new("RGB", (cols * 420, rows * 286), (18, 16, 14))
    for idx, (_, thumb) in enumerate(thumbs):
        sheet.paste(thumb, ((idx % cols) * 420, (idx // cols) * 286))
    sheet.save(output, quality=88)
    return output


def write_report(root: Path, metrics: list[Metric], contact_sheet: Path | None) -> None:
    flagged = [m for m in metrics if m.signal != "ok"]
    by_signal: dict[str, int] = {}
    for metric in flagged:
        for signal in metric.signal.split(";"):
            by_signal[signal] = by_signal.get(signal, 0) + 1

    top = sorted(flagged, key=signal_score, reverse=True)[:20]
    path = root / "second_pass_visual_audit.md"
    lines = [
        "# 第二轮机器辅助视觉验收",
        "",
        "本报告读取第一轮已生成截图，计算内容边界、暗色空白、底部 HUD 密度和浅底低对比风险信号。它不是替代人工目检，而是用来发现遗漏页和安排后续复查。",
        "",
        "## 总览",
        "",
        f"- 输入截图矩阵：{len(metrics)} 张。",
        f"- 触发至少 1 个机器信号：{len(flagged)} 张。",
        f"- P1/P2/P3 问题页中触发机器信号：{sum(1 for m in flagged if m.severity in {'P1', 'P2', 'P3'})} 张。",
        f"- 输出指标：`second_pass_visual_metrics.csv`。",
    ]
    if contact_sheet:
        lines.append(f"- 风险拼图：`{contact_sheet.relative_to(root).as_posix()}`。")
    lines.extend(["", "## 信号计数", ""])
    for signal, count in sorted(by_signal.items(), key=lambda item: (-item[1], item[0])):
        lines.append(f"- `{signal}`：{count}")

    lines.extend(["", "## Top 20 复查候选", ""])
    lines.append("| route | severity | variant | signals | metrics | note |")
    lines.append("|---|---:|---:|---|---|---|")
    for metric in top:
        metrics_text = (
            f"active {metric.active_width_pct:.2f}, "
            f"dark L/R {metric.left_dark_empty_ratio:.2f}/{metric.right_dark_empty_ratio:.2f}, "
            f"dark {metric.dark_empty_ratio:.2f}, paper {metric.light_low_contrast_ratio:.2f}"
        )
        lines.append(
            "| "
            + " | ".join(
                [
                    metric.route,
                    metric.severity,
                    metric.variant,
                    f"`{metric.signal}`",
                    metrics_text,
                    metric.note.replace("|", "/"),
                ]
            )
            + " |"
        )

    lines.extend(
        [
            "",
            "## 结论",
            "",
            "- 机器信号与已登记 P1/P2/P3 基本重合时，说明第一轮人工分级没有明显漏掉高风险页面。",
            "- 若 PASS 页进入 Top 20，明早需要作为追加抽样页目检，确认它是设计留白还是新回归。",
            "- `paper_contrast_review` 只表示浅色平面较大，低对比最终仍以人工查看文字可读性为准。",
            "- `wide_*_dark_empty` 和 `narrow_active_content` 更适合定位宽屏空洞、列表靠边、主体过窄等布局风险。",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: analyze_visual_density.py <visual_acceptance_dir>", file=sys.stderr)
        return 2
    root = Path(sys.argv[1]).resolve()
    rows = load_routes(root)
    metrics: list[Metric] = []
    for row in rows:
        for variant, column in VARIANT_COLUMNS.items():
            metric = analyze_image(root, row, variant, column)
            if metric:
                metrics.append(metric)

    write_metrics(root, metrics)
    flagged = sorted([m for m in metrics if m.signal != "ok"], key=signal_score, reverse=True)
    contact_sheet = write_contact_sheet(root, flagged)
    write_report(root, metrics, contact_sheet)
    print(
        "second-pass visual audit: "
        f"metrics={len(metrics)} flagged={len(flagged)} "
        f"contact_sheet={contact_sheet.relative_to(root).as_posix() if contact_sheet else 'none'}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
