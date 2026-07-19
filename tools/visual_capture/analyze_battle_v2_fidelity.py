#!/usr/bin/env python3
"""Measure reproducible Battle UI V2 fidelity evidence.

Exact layout and character metrics require diagnostic annotations/layers in the
manifest. When they are absent, the output says unavailable or approximate; it
never promotes a guessed value to an acceptance result.
"""

import argparse
import hashlib
import json
import re
from pathlib import Path
from statistics import median
from typing import Any, Dict, List, Optional, Sequence

import numpy as np
from PIL import Image


DEFAULT_CONFIG = Path(__file__).with_name("battle_v2_fidelity_config.json")


def load_config(path: Path) -> Dict[str, Any]:
    config = json.loads(path.read_text(encoding="utf-8"))
    required = ("reference", "layout", "characters", "semantic_color", "contrast")
    missing = [key for key in required if key not in config]
    if missing:
        raise ValueError("config missing keys: " + ", ".join(missing))
    return config


def alpha_bbox(rgba: np.ndarray, threshold: int) -> Optional[List[int]]:
    """Return [x, y, width, height] for alpha strictly greater than threshold."""
    if rgba.ndim != 3 or rgba.shape[2] < 4:
        raise ValueError("alpha_bbox expects an RGBA array")
    ys, xs = np.nonzero(rgba[:, :, 3] > threshold)
    if len(xs) == 0:
        return None
    x0, x1 = int(xs.min()), int(xs.max())
    y0, y1 = int(ys.min()), int(ys.max())
    return [x0, y0, x1 - x0 + 1, y1 - y0 + 1]


def _resolve_path(raw: str, base: Path) -> Path:
    path = Path(raw)
    return path if path.is_absolute() else (base / path).resolve()


def _rgba(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGBA"), dtype=np.uint8)


def _safe_id(raw: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", raw)


def _ratio_in_band(value: Optional[float], band: Sequence[float]) -> Optional[bool]:
    if value is None:
        return None
    return float(band[0]) <= value <= float(band[1])


def _region_ratios(capture: Dict[str, Any]) -> Dict[str, Optional[float]]:
    regions = capture.get("regions")
    if not isinstance(regions, dict):
        return {
            "header": None,
            "battlefield": None,
            "command_desk": None,
            "focus": None,
            "skills": None,
            "pouch": None,
            "central_engagement": None,
        }
    viewport = capture["viewport"]
    viewport_height = float(viewport["height"])
    desk_width = float(regions.get("command_desk", {}).get("width", viewport["width"]))

    def height_ratio(name: str) -> Optional[float]:
        region = regions.get(name)
        return None if not region else float(region["height"]) / viewport_height

    def width_ratio(name: str) -> Optional[float]:
        region = regions.get(name)
        return None if not region else float(region["width"]) / desk_width

    engagement = regions.get("central_engagement")
    return {
        "header": height_ratio("header"),
        "battlefield": height_ratio("battlefield"),
        "command_desk": height_ratio("command_desk"),
        "focus": width_ratio("focus"),
        "skills": width_ratio("skills"),
        "pouch": width_ratio("pouch"),
        "central_engagement": None
        if not engagement
        else float(engagement["width"]) / float(viewport["width"]),
    }


def _semantic_mask(
    rgba: np.ndarray, saturation_min: float, value_min: float
) -> np.ndarray:
    rgb = rgba[:, :, :3].astype(np.float32) / 255.0
    maximum = rgb.max(axis=2)
    minimum = rgb.min(axis=2)
    delta = maximum - minimum
    saturation = np.divide(
        delta,
        maximum,
        out=np.zeros_like(delta),
        where=maximum > 0,
    )
    return (
        (rgba[:, :, 3] > 0)
        & (saturation >= saturation_min)
        & (maximum >= value_min)
    )


def _dark_percentile(rgba: np.ndarray, mask: np.ndarray) -> Optional[float]:
    if not mask.any():
        return None
    rgb = rgba[:, :, :3].astype(np.float32) / 255.0
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    return float(np.percentile(luminance[mask], 5))


def _character_metrics(
    capture: Dict[str, Any],
    manifest_base: Path,
    config: Dict[str, Any],
    mask_dir: Path,
    capture_id: str,
) -> List[Dict[str, Any]]:
    layers = capture.get("layers") or {}
    characters = layers.get("characters") or []
    threshold = int(config["characters"]["alpha_threshold"])
    metrics: List[Dict[str, Any]] = []
    for item in characters:
        path = _resolve_path(item["path"], manifest_base)
        rgba = _rgba(path)
        mask = rgba[:, :, 3] > threshold
        bbox = alpha_bbox(rgba, threshold)
        area = None if bbox is None else bbox[2] * bbox[3]
        item_id = str(item["id"])
        mask_path = mask_dir / (
            _safe_id(capture_id) + "_character_" + _safe_id(item_id) + ".png"
        )
        Image.fromarray(mask.astype(np.uint8) * 255).save(mask_path)
        metrics.append(
            {
                "id": item_id,
                "boss": bool(item.get("boss", False)),
                "side": item.get("side"),
                "bbox": bbox,
                "bbox_area": area,
                "dark_p05": _dark_percentile(rgba, mask),
                "mask": str(mask_path),
            }
        )
    return metrics


def _boss_area_ratio(characters: List[Dict[str, Any]]) -> Optional[float]:
    boss_areas = [c["bbox_area"] for c in characters if c["boss"] and c["bbox_area"]]
    player_areas = [
        c["bbox_area"]
        for c in characters
        if not c["boss"] and c.get("side") == "left" and c["bbox_area"]
    ]
    if not boss_areas or not player_areas:
        return None
    return float(max(boss_areas) / median(player_areas))


def _analyze_capture(
    capture: Dict[str, Any],
    manifest_base: Path,
    config: Dict[str, Any],
    mask_dir: Path,
) -> Dict[str, Any]:
    capture_id = str(capture.get("id") or capture["route"])
    png_path = _resolve_path(capture["png"], manifest_base)
    rgba = _rgba(png_path)
    pixel_height, pixel_width = rgba.shape[:2]
    viewport = capture["viewport"]
    dpr = capture.get("dpr")
    if dpr is None:
        dpr_x = pixel_width / float(viewport["width"])
        dpr_y = pixel_height / float(viewport["height"])
        if abs(dpr_x - dpr_y) > 0.01:
            raise ValueError(
                "%s has inconsistent inferred DPR: %.4f vs %.4f"
                % (capture_id, dpr_x, dpr_y)
            )
        dpr = (dpr_x + dpr_y) / 2.0
    dpr = float(dpr)
    layout = _region_ratios(capture)
    warnings: List[str] = []
    if not capture.get("regions"):
        warnings.append("missing regions")

    characters = _character_metrics(
        capture, manifest_base, config, mask_dir, capture_id
    )
    boss_ratio = _boss_area_ratio(characters)
    if not characters:
        warnings.append("missing character diagnostic layers")

    layers = capture.get("layers") or {}
    semantic_path = layers.get("semantic_ui")
    if semantic_path:
        semantic_rgba = _rgba(_resolve_path(semantic_path, manifest_base))
        semantic_method = "diagnostic_layer"
    else:
        semantic_rgba = rgba
        semantic_method = "full_content_approximate"
        warnings.append("missing semantic UI diagnostic layer")
    semantic_config = config["semantic_color"]
    semantic_mask = _semantic_mask(
        semantic_rgba,
        float(semantic_config["saturation_min"]),
        float(semantic_config["value_min"]),
    )
    semantic_area = float(semantic_mask.sum() / semantic_mask.size)
    semantic_mask_path = mask_dir / (
        _safe_id(capture_id) + "_semantic.png"
    )
    Image.fromarray(semantic_mask.astype(np.uint8) * 255).save(
        semantic_mask_path
    )

    vertical = config["layout"]["vertical"]
    horizontal = config["layout"]["command_desk_horizontal"]
    gates = {
        "header": _ratio_in_band(layout["header"], vertical["header"]),
        "battlefield": _ratio_in_band(
            layout["battlefield"], vertical["battlefield"]
        ),
        "command_desk": _ratio_in_band(
            layout["command_desk"], vertical["command_desk"]
        ),
        "focus": _ratio_in_band(layout["focus"], horizontal["focus"]),
        "skills": _ratio_in_band(layout["skills"], horizontal["skills"]),
        "pouch": _ratio_in_band(layout["pouch"], horizontal["pouch"]),
        "central_engagement": _ratio_in_band(
            layout["central_engagement"], config["layout"]["central_engagement"]
        ),
        "boss_area_ratio": _ratio_in_band(
            boss_ratio, config["characters"]["boss_area_ratio"]
        ),
        "semantic_color_area": semantic_area
        <= float(semantic_config["non_ultimate_area_max"]),
    }
    return {
        "id": capture_id,
        "route": capture["route"],
        "seed": capture.get("seed"),
        "tick": capture.get("tick"),
        "viewport": [int(viewport["width"]), int(viewport["height"])],
        "png": str(png_path),
        "png_pixels": [pixel_width, pixel_height],
        "dpr": dpr,
        "content_rect": capture.get(
            "content_rect",
            {"x": 0, "y": 0, "width": viewport["width"], "height": viewport["height"]},
        ),
        "layout": layout,
        "characters": characters,
        "boss_area_ratio": boss_ratio,
        "semantic_color_area": semantic_area,
        "semantic_color_method": semantic_method,
        "semantic_mask": str(semantic_mask_path),
        "gates": gates,
        "warnings": warnings,
    }


def _black_point_drift(captures: List[Dict[str, Any]]) -> Dict[str, Any]:
    values: Dict[str, List[float]] = {}
    for capture in captures:
        for character in capture["characters"]:
            value = character["dark_p05"]
            if value is not None:
                values.setdefault(character["id"], []).append(value)
    result: Dict[str, Any] = {}
    for character_id, samples in values.items():
        result[character_id] = {
            "samples": samples,
            "drift": max(samples) - min(samples) if len(samples) >= 2 else None,
        }
    return result


def _reference_status(config: Dict[str, Any]) -> Dict[str, Any]:
    reference = config["reference"]
    path = Path(reference["path"])
    if not path.exists():
        return {"path": str(path), "exists": False, "sha256": None, "matches": False}
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    return {
        "path": str(path),
        "exists": True,
        "sha256": digest,
        "matches": digest == reference["sha256"],
    }


def _score_markdown(result: Dict[str, Any]) -> str:
    lines = [
        "# Battle UI V2 fidelity score skeleton",
        "",
        "- commit: `%s`" % (result.get("commit") or "unknown"),
        "- reference SHA matches: `%s`" % result["reference"]["matches"],
        "- captures: `%d`" % len(result["captures"]),
        "",
        "## Objective measurements",
        "",
        "| capture | viewport | header | battlefield | desk | focus | skills | pouch | boss ratio | semantic color | warnings |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
    for capture in result["captures"]:
        layout = capture["layout"]

        def fmt(value: Optional[float]) -> str:
            return "—" if value is None else "%.3f" % value

        lines.append(
            "| `{id}` | {width}×{height} | {header} | {battlefield} | {desk} | "
            "{focus} | {skills} | {pouch} | {boss} | {semantic:.3f} ({method}) | {warnings} |".format(
                id=capture["id"],
                width=capture["viewport"][0],
                height=capture["viewport"][1],
                header=fmt(layout["header"]),
                battlefield=fmt(layout["battlefield"]),
                desk=fmt(layout["command_desk"]),
                focus=fmt(layout["focus"]),
                skills=fmt(layout["skills"]),
                pouch=fmt(layout["pouch"]),
                boss=fmt(capture["boss_area_ratio"]),
                semantic=capture["semantic_color_area"],
                method=capture["semantic_color_method"],
                warnings="; ".join(capture["warnings"]) or "—",
            )
        )
    lines.extend(
        [
            "",
            "## Human rubric (must be scored with reasons)",
            "",
            "- A 构图：__/20",
            "- B 人物：__/25",
            "- C 案台：__/25",
            "- D 材质：__/15",
            "- E HUD：__/10",
            "- F 动态：__/5",
            "- 合计：__/100（A～E 各自得分率均须 ≥80%）",
            "",
            "> This skeleton is evidence, not user style approval.",
        ]
    )
    return "\n".join(lines) + "\n"


def analyze_manifest(
    manifest_path: Path, config: Dict[str, Any], output: Path
) -> Dict[str, Any]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    captures = manifest.get("captures")
    if not isinstance(captures, list) or not captures:
        raise ValueError("manifest must contain a non-empty captures list")
    output.mkdir(parents=True, exist_ok=True)
    mask_dir = output / "masks"
    mask_dir.mkdir(parents=True, exist_ok=True)
    analyzed = [
        _analyze_capture(capture, manifest_path.parent, config, mask_dir)
        for capture in captures
    ]
    drift = _black_point_drift(analyzed)
    max_drift = float(config["characters"]["black_point_drift_max"])
    for item in drift.values():
        item["passes"] = None if item["drift"] is None else item["drift"] <= max_drift
    result = {
        "schema_version": 1,
        "commit": manifest.get("commit"),
        "manifest": str(manifest_path.resolve()),
        "reference": _reference_status(config),
        "captures": analyzed,
        "black_point_drift": drift,
        "thresholds": config,
    }
    (output / "metrics.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (output / "score.md").write_text(_score_markdown(result), encoding="utf-8")
    return result


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Measure Battle UI V2 layout, alpha boxes, boss scale and semantic color evidence."
    )
    parser.add_argument("--manifest", type=Path, help="Capture manifest JSON.")
    parser.add_argument(
        "--config", type=Path, default=DEFAULT_CONFIG, help="Single threshold config JSON."
    )
    parser.add_argument("--output", type=Path, help="Output directory for metrics, score and masks.")
    return parser


def main() -> int:
    parser = _parser()
    args = parser.parse_args()
    if args.manifest is None:
        parser.error("--manifest is required")
    if args.output is None:
        parser.error("--output is required")
    analyze_manifest(args.manifest, load_config(args.config), args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
