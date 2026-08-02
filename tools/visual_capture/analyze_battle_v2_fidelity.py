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
import shutil
from pathlib import Path
from statistics import median
from typing import Any, Dict, List, Optional, Sequence, Tuple

import numpy as np
import cv2
from PIL import Image


DEFAULT_CONFIG = Path(__file__).with_name("battle_v2_fidelity_config.json")
REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_STATIC_SEED = "visual-route-host-fixture-20260627"
VIEWPORT_PATTERN = re.compile(r"^(?P<width>\d+)x(?P<height>\d+)$")
ROUTE_STATE_PATTERN = re.compile(
    r"VISUAL_ROUTE_STATE:\s+route=(?P<route>\S+)\s+"
    r"seed=(?P<seed>\S+)\s+tick=(?P<tick>\d+)"
)
WINDOW_CAPTURE_PATTERN = re.compile(
    r"VISUAL_CAPTURE:\s+(?P<method>window_id|existing_window_id):(?P<window_id>\d+)"
)
FALLBACK_CAPTURE_PATTERN = re.compile(r"VISUAL_CAPTURE:\s+fallback_region")
FIDELITY_REGIONS_PATTERN = re.compile(
    r"VISUAL_FIDELITY_REGIONS:\s+(?P<regions>\{[^\n]+\})"
)


def load_config(path: Path) -> Dict[str, Any]:
    config = json.loads(path.read_text(encoding="utf-8"))
    required = (
        "reference",
        "comparison",
        "baseline_diff",
        "layout",
        "characters",
        "semantic_color",
        "contrast",
    )
    missing = [key for key in required if key not in config]
    if missing:
        raise ValueError("config missing keys: " + ", ".join(missing))
    return config


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build_manifest(capture_root: Path, commit: str) -> Dict[str, Any]:
    """Discover visual captures and bind each image to its deterministic state."""
    capture_root = capture_root.resolve()
    captures: List[Dict[str, Any]] = []
    for png_path in sorted(capture_root.glob("*/*/*.png")):
        viewport_match = VIEWPORT_PATTERN.fullmatch(png_path.parent.name)
        if viewport_match is None:
            continue
        route = png_path.stem
        width = int(viewport_match.group("width"))
        height = int(viewport_match.group("height"))
        with Image.open(png_path) as image:
            pixel_width, pixel_height = image.size
        dpr_x = pixel_width / width
        dpr_y = pixel_height / height
        if abs(dpr_x - dpr_y) > 0.01:
            raise ValueError(
                "%s has inconsistent inferred DPR: %.4f vs %.4f"
                % (png_path, dpr_x, dpr_y)
            )

        log_path = png_path.with_suffix(".log")
        log_text = (
            log_path.read_text(encoding="utf-8", errors="replace")
            if log_path.exists()
            else ""
        )
        state_match = ROUTE_STATE_PATTERN.search(log_text)
        seed: Any = DEFAULT_STATIC_SEED
        tick: Optional[int] = None
        if state_match is not None:
            logged_route = state_match.group("route")
            if logged_route != route:
                raise ValueError(
                    "%s route mismatch: directory=%s log=%s"
                    % (log_path, route, logged_route)
                )
            raw_seed = state_match.group("seed")
            seed = int(raw_seed) if raw_seed.isdigit() else raw_seed
            tick = int(state_match.group("tick"))
        capture_match = WINDOW_CAPTURE_PATTERN.search(log_text)
        native_window_id: Optional[int] = None
        capture_method: Optional[str] = None
        if capture_match is not None:
            native_window_id = int(capture_match.group("window_id"))
            capture_method = capture_match.group("method")
        elif FALLBACK_CAPTURE_PATTERN.search(log_text):
            capture_method = "fallback_region"
        regions_match = FIDELITY_REGIONS_PATTERN.search(log_text)
        regions = (
            json.loads(regions_match.group("regions"))
            if regions_match is not None
            else None
        )
        captures.append(
            {
                "id": "%s_%s" % (route, png_path.parent.name),
                "route": route,
                "seed": seed,
                "tick": tick,
                "viewport": {"width": width, "height": height},
                "dpr": (dpr_x + dpr_y) / 2.0,
                "content_rect": {"x": 0, "y": 0, "width": width, "height": height},
                "png": str(png_path.relative_to(capture_root)),
                "png_sha256": _sha256(png_path),
                "log": str(log_path.relative_to(capture_root)),
                "log_sha256": _sha256(log_path) if log_path.exists() else None,
                "capture_method": capture_method,
                "native_window_id": native_window_id,
                "regions": regions,
            }
        )
    if not captures:
        raise ValueError("capture root contains no <route>/<WxH>/*.png captures")
    return {
        "schema_version": 2,
        "commit": commit,
        "capture_root": str(capture_root),
        "captures": captures,
    }


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


def _reference_path(config: Dict[str, Any]) -> Path:
    path = Path(config["reference"]["path"])
    return path if path.is_absolute() else (REPO_ROOT / path).resolve()


def _resize_rgba(rgba: np.ndarray, size: Tuple[int, int]) -> np.ndarray:
    resampling = getattr(Image, "Resampling", Image).LANCZOS
    return np.asarray(
        Image.fromarray(rgba).resize(size, resampling),
        dtype=np.uint8,
    )


def _fit_cover_center(rgba: np.ndarray, size: Tuple[int, int]) -> np.ndarray:
    target_width, target_height = size
    source_height, source_width = rgba.shape[:2]
    scale = max(target_width / source_width, target_height / source_height)
    scaled_width = max(target_width, int(round(source_width * scale)))
    scaled_height = max(target_height, int(round(source_height * scale)))
    scaled = _resize_rgba(rgba, (scaled_width, scaled_height))
    x0 = (scaled_width - target_width) // 2
    y0 = (scaled_height - target_height) // 2
    return scaled[y0 : y0 + target_height, x0 : x0 + target_width]


def _srgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    normalized = rgb.astype(np.float32) / 255.0
    linear = np.where(
        normalized <= 0.04045,
        normalized / 12.92,
        ((normalized + 0.055) / 1.055) ** 2.4,
    )
    xyz = np.empty_like(linear)
    xyz[:, :, 0] = (
        0.4124564 * linear[:, :, 0]
        + 0.3575761 * linear[:, :, 1]
        + 0.1804375 * linear[:, :, 2]
    )
    xyz[:, :, 1] = (
        0.2126729 * linear[:, :, 0]
        + 0.7151522 * linear[:, :, 1]
        + 0.0721750 * linear[:, :, 2]
    )
    xyz[:, :, 2] = (
        0.0193339 * linear[:, :, 0]
        + 0.1191920 * linear[:, :, 1]
        + 0.9503041 * linear[:, :, 2]
    )
    xyz /= np.array([0.95047, 1.0, 1.08883], dtype=np.float32)
    delta = 6.0 / 29.0
    transformed = np.where(
        xyz > delta**3,
        np.cbrt(xyz),
        xyz / (3.0 * delta**2) + 4.0 / 29.0,
    )
    lab = np.empty_like(transformed)
    lab[:, :, 0] = 116.0 * transformed[:, :, 1] - 16.0
    lab[:, :, 1] = 500.0 * (transformed[:, :, 0] - transformed[:, :, 1])
    lab[:, :, 2] = 200.0 * (transformed[:, :, 1] - transformed[:, :, 2])
    return lab


def _edge_mask(rgb: np.ndarray, low: float, high: float) -> np.ndarray:
    gray = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY)
    return cv2.Canny(gray, low, high) > 0


def _edge_iou(
    reference: np.ndarray, current: np.ndarray, low: float, high: float
) -> float:
    reference_edges = _edge_mask(reference[:, :, :3], low, high)
    current_edges = _edge_mask(current[:, :, :3], low, high)
    union = np.logical_or(reference_edges, current_edges)
    if not union.any():
        return 1.0
    intersection = np.logical_and(reference_edges, current_edges)
    return float(intersection.sum() / union.sum())


def _comparison_regions(
    config: Dict[str, Any], width: int, height: int
) -> Dict[str, Tuple[slice, slice]]:
    reference_viewport = config["reference"]["viewport"]
    reference_height = float(reference_viewport[1])
    boundaries = config["comparison"]["boundaries"]
    header_bottom = int(
        round(float(boundaries["header_bottom"]) * height / reference_height)
    )
    desk_top = int(round(float(boundaries["desk_top"]) * height / reference_height))
    if not 0 < header_bottom < desk_top < height:
        raise ValueError(
            "comparison boundaries must satisfy 0 < header < desk < viewport height"
        )
    return {
        "header": (slice(0, header_bottom), slice(0, width)),
        "field": (slice(header_bottom, desk_top), slice(0, width)),
        "desk": (slice(desk_top, height), slice(0, width)),
    }


def _region_metrics(
    reference: np.ndarray,
    current: np.ndarray,
    regions: Dict[str, Tuple[slice, slice]],
    edge_threshold_low: float,
    edge_threshold_high: float,
) -> Dict[str, Dict[str, Any]]:
    metrics: Dict[str, Dict[str, Any]] = {}
    reference_lab = _srgb_to_lab(reference[:, :, :3])
    current_lab = _srgb_to_lab(current[:, :, :3])
    for name, selection in regions.items():
        reference_region = reference[selection][:, :, :3]
        current_region = current[selection][:, :, :3]
        signed = current_region.astype(np.float32) - reference_region.astype(np.float32)
        delta_lab = current_lab[selection] - reference_lab[selection]
        metrics[name] = {
            "rgb_delta_mean": [
                float(value) for value in signed.mean(axis=(0, 1)).tolist()
            ],
            "lab_delta_mean": [
                float(value) for value in delta_lab.mean(axis=(0, 1)).tolist()
            ],
            "delta_e_mean": float(np.linalg.norm(delta_lab, axis=2).mean()),
            "mae": float(np.abs(signed).mean()),
            "edge_iou": _edge_iou(
                reference[selection],
                current[selection],
                edge_threshold_low,
                edge_threshold_high,
            ),
        }
    return metrics


def _anchor_metrics(
    capture: Dict[str, Any],
    config: Dict[str, Any],
    viewport_height: int,
) -> Dict[str, Optional[float]]:
    regions = capture.get("regions")
    if not isinstance(regions, dict):
        return {"header_bottom_error": None, "desk_top_error": None}
    reference_height = float(config["reference"]["viewport"][1])
    boundaries = config["comparison"]["boundaries"]
    expected_header = (
        float(boundaries["header_bottom"]) * viewport_height / reference_height
    )
    expected_desk = float(boundaries["desk_top"]) * viewport_height / reference_height
    header = regions.get("header")
    desk = regions.get("command_desk")
    actual_header = None if not header else float(header.get("y", 0)) + float(header["height"])
    actual_desk = None if not desk else float(desk["y"])
    return {
        "header_bottom_error": None
        if actual_header is None
        else abs(actual_header - expected_header),
        "desk_top_error": None if actual_desk is None else abs(actual_desk - expected_desk),
    }


def _comparison_gates(
    metrics: Dict[str, Dict[str, Any]],
    anchors: Dict[str, Optional[float]],
    config: Dict[str, Any],
) -> Dict[str, bool]:
    thresholds = config["comparison"]["gates"]
    gates: Dict[str, bool] = {}
    for name, values in metrics.items():
        gates["%s_rgb" % name] = all(
            abs(value) <= float(thresholds["mean_rgb_abs_max"][name])
            for value in values["rgb_delta_mean"]
        )
        gates["%s_mae" % name] = values["mae"] <= float(
            thresholds["mae_max"][name]
        )
        gates["%s_edge_iou" % name] = values["edge_iou"] >= float(
            thresholds["edge_iou_min"][name]
        )
    anchor_max = float(thresholds["anchor_error_max"])
    gates["header_anchor"] = (
        anchors["header_bottom_error"] is not None
        and anchors["header_bottom_error"] <= anchor_max
    )
    gates["desk_anchor"] = (
        anchors["desk_top_error"] is not None
        and anchors["desk_top_error"] <= anchor_max
    )
    gates["all_machine_gates"] = all(gates.values())
    return gates


def _safe_id(raw: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", raw)


def _save_comparison_artifacts(
    reference: np.ndarray,
    current: np.ndarray,
    regions: Dict[str, Tuple[slice, slice]],
    output: Path,
) -> Dict[str, str]:
    output.mkdir(parents=True, exist_ok=True)
    absolute_diff = np.abs(
        current[:, :, :3].astype(np.int16) - reference[:, :, :3].astype(np.int16)
    ).astype(np.uint8)
    diff_rgba = np.dstack(
        [absolute_diff, np.full(absolute_diff.shape[:2], 255, dtype=np.uint8)]
    )
    artifacts: Dict[str, str] = {}

    full_path = output / "diff_full.png"
    Image.fromarray(diff_rgba).save(full_path)
    artifacts["diff_full"] = str(full_path)
    for name, selection in regions.items():
        path = output / ("diff_%s.png" % name)
        Image.fromarray(diff_rgba[selection]).save(path)
        artifacts["diff_%s" % name] = str(path)

    side_by_side = np.concatenate([reference, current], axis=1)
    side_by_side_path = output / "reference_current_side_by_side.png"
    Image.fromarray(side_by_side).save(side_by_side_path)
    artifacts["side_by_side"] = str(side_by_side_path)
    return artifacts


def _compare_to_reference(
    capture: Dict[str, Any],
    current_rgba: np.ndarray,
    current_path: Path,
    config: Dict[str, Any],
    artifact_dir: Path,
) -> Dict[str, Any]:
    reference_path = _reference_path(config)
    reference_rgba = _rgba(reference_path)
    viewport = capture["viewport"]
    logical_size = (int(viewport["width"]), int(viewport["height"]))
    current_logical = _resize_rgba(current_rgba, logical_size)
    fit = config["reference"].get("fit", "cover_center")
    if fit != "cover_center":
        raise ValueError("unsupported reference fit: %s" % fit)
    reference_logical = _fit_cover_center(reference_rgba, logical_size)
    current_sha256 = _sha256(current_path)
    reference_sha256 = _sha256(reference_path)
    if current_sha256 == reference_sha256:
        raise ValueError(
            "%s current image is identical to reference; acceptance comparison rejected"
            % capture.get("id", capture["route"])
        )
    if np.array_equal(current_logical, reference_logical):
        raise ValueError(
            "%s current image is pixel-identical to reference; acceptance comparison rejected"
            % capture.get("id", capture["route"])
        )

    regions = _comparison_regions(config, *logical_size)
    edge_threshold_low = float(config["comparison"]["edge_threshold_low"])
    edge_threshold_high = float(config["comparison"]["edge_threshold_high"])
    metrics = _region_metrics(
        reference_logical,
        current_logical,
        regions,
        edge_threshold_low,
        edge_threshold_high,
    )
    self_metrics = _region_metrics(
        reference_logical,
        reference_logical,
        regions,
        edge_threshold_low,
        edge_threshold_high,
    )
    anchors = _anchor_metrics(capture, config, logical_size[1])
    gates = _comparison_gates(metrics, anchors, config)
    artifacts = _save_comparison_artifacts(
        reference_logical, current_logical, regions, artifact_dir
    )
    return {
        "reference_path": str(reference_path),
        "reference_sha256": reference_sha256,
        "current_path": str(current_path),
        "current_sha256": current_sha256,
        "fit": fit,
        "logical_size": list(logical_size),
        "regions": metrics,
        "anchors": anchors,
        "gates": gates,
        "self_check": {
            "regions": self_metrics,
            "passes": all(
                values["mae"] == 0.0
                and values["edge_iou"] == 1.0
                and all(channel == 0.0 for channel in values["rgb_delta_mean"])
                for values in self_metrics.values()
            ),
        },
        "artifacts": artifacts,
    }


def _compare_to_baseline(
    capture: Dict[str, Any],
    current_rgba: np.ndarray,
    current_path: Path,
    capture_base: Path,
    config: Dict[str, Any],
    artifact_dir: Path,
) -> Dict[str, Any]:
    baseline = capture["baseline"]
    before_path = _resolve_path(str(baseline["png"]), capture_base)
    expected_sha256 = baseline.get("sha256")
    actual_sha256 = _sha256(before_path)
    if expected_sha256 is not None and expected_sha256 != actual_sha256:
        raise ValueError(
            "%s baseline hash mismatch: manifest=%s actual=%s"
            % (capture.get("id", capture["route"]), expected_sha256, actual_sha256)
        )
    before_rgba = _rgba(before_path)
    if before_rgba.shape != current_rgba.shape:
        raise ValueError(
            "%s baseline/current pixel dimensions differ: %s vs %s"
            % (
                capture.get("id", capture["route"]),
                before_rgba.shape,
                current_rgba.shape,
            )
        )
    threshold = int(config["baseline_diff"]["changed_pixel_threshold"])
    absolute = np.abs(
        current_rgba.astype(np.int16) - before_rgba.astype(np.int16)
    ).astype(np.uint8)
    changed = absolute.max(axis=2) > threshold
    allowed = np.zeros(changed.shape, dtype=bool)
    allowed_path_value = baseline.get("allowed_change_mask")
    allowed_path: Optional[Path] = None
    if allowed_path_value:
        allowed_path = _resolve_path(str(allowed_path_value), capture_base)
        allowed_pixels = np.asarray(Image.open(allowed_path).convert("L"), dtype=np.uint8)
        if allowed_pixels.shape != changed.shape:
            raise ValueError(
                "%s allowed-change mask dimensions differ: %s vs %s"
                % (
                    capture.get("id", capture["route"]),
                    allowed_pixels.shape,
                    changed.shape,
                )
            )
        allowed = allowed_pixels > 0
    unexpected = np.logical_and(changed, np.logical_not(allowed))

    roi_metrics: Dict[str, Dict[str, Any]] = {}
    pixel_height, pixel_width = changed.shape
    for name, rect in (baseline.get("rois") or {}).items():
        x = int(rect["x"])
        y = int(rect["y"])
        width = int(rect["width"])
        height = int(rect["height"])
        if x < 0 or y < 0 or width <= 0 or height <= 0 or x + width > pixel_width or y + height > pixel_height:
            raise ValueError("%s baseline ROI %s is outside the image" % (capture.get("id", capture["route"]), name))
        selection = (slice(y, y + height), slice(x, x + width))
        roi_metrics[name] = {
            "rect": {"x": x, "y": y, "width": width, "height": height},
            "changed_pixels": int(changed[selection].sum()),
            "allowed_pixels": int(np.logical_and(changed[selection], allowed[selection]).sum()),
            "unexpected_pixels": int(unexpected[selection].sum()),
        }

    artifact_dir.mkdir(parents=True, exist_ok=True)
    diff_rgb = absolute[:, :, :3]
    diff_rgba = np.dstack(
        [diff_rgb, np.full(changed.shape, 255, dtype=np.uint8)]
    )
    unexpected_rgba = np.zeros_like(diff_rgba)
    unexpected_rgba[:, :, 0] = unexpected.astype(np.uint8) * 255
    unexpected_rgba[:, :, 3] = 255
    full_path = artifact_dir / "baseline_diff_full.png"
    unexpected_path = artifact_dir / "baseline_unexpected_diff.png"
    side_by_side_path = artifact_dir / "baseline_current_side_by_side.png"
    Image.fromarray(diff_rgba).save(full_path)
    Image.fromarray(unexpected_rgba).save(unexpected_path)
    Image.fromarray(np.concatenate([before_rgba, current_rgba], axis=1)).save(
        side_by_side_path
    )

    total_pixels = int(changed.size)
    changed_total = int(changed.sum())
    changed_allowed = int(np.logical_and(changed, allowed).sum())
    changed_unexpected = int(unexpected.sum())
    return {
        "before_path": str(before_path),
        "before_sha256": actual_sha256,
        "current_path": str(current_path),
        "current_sha256": _sha256(current_path),
        "allowed_change_mask": None if allowed_path is None else str(allowed_path),
        "changed_pixel_threshold": threshold,
        "total_pixels": total_pixels,
        "changed_pixels_total": changed_total,
        "changed_pixels_allowed": changed_allowed,
        "changed_pixels_unexpected": changed_unexpected,
        "changed_ratio": changed_total / total_pixels,
        "unexpected_ratio": changed_unexpected / total_pixels,
        "rois": roi_metrics,
        "artifacts": {
            "diff_full": str(full_path),
            "unexpected_diff": str(unexpected_path),
            "side_by_side": str(side_by_side_path),
        },
    }


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
        source_area = None if bbox is None else bbox[2] * bbox[3]
        render_scale = float(item.get("render_scale", 1.0))
        area = (
            None
            if source_area is None
            else source_area * render_scale * render_scale
        )
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
                "source_bbox_area": source_area,
                "render_scale": render_scale,
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
    capture_base: Path,
    config: Dict[str, Any],
    mask_dir: Path,
    comparison_dir: Path,
) -> Dict[str, Any]:
    capture_id = str(capture.get("id") or capture["route"])
    png_path = _resolve_path(capture["png"], capture_base)
    recorded_sha256 = capture.get("png_sha256")
    actual_sha256 = _sha256(png_path)
    if recorded_sha256 is not None and actual_sha256 != recorded_sha256:
        raise ValueError(
            "%s capture hash mismatch: manifest=%s actual=%s"
            % (capture_id, recorded_sha256, actual_sha256)
        )
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
        capture, capture_base, config, mask_dir, capture_id
    )
    boss_ratio = _boss_area_ratio(characters)
    if not characters:
        warnings.append("missing character diagnostic layers")

    layers = capture.get("layers") or {}
    semantic_path = layers.get("semantic_ui")
    if semantic_path:
        semantic_rgba = _rgba(_resolve_path(semantic_path, capture_base))
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
    result = {
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
    if capture["route"] == config["reference"].get("route"):
        result["comparison"] = _compare_to_reference(
            capture,
            rgba,
            png_path,
            config,
            comparison_dir / _safe_id(capture_id),
        )
    else:
        result["comparison"] = None
    if capture.get("baseline"):
        result["baseline_comparison"] = _compare_to_baseline(
            capture,
            rgba,
            png_path,
            capture_base,
            config,
            comparison_dir / _safe_id(capture_id),
        )
    else:
        result["baseline_comparison"] = None
    return result


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
    path = _reference_path(config)
    if not path.exists():
        return {"path": str(path), "exists": False, "sha256": None, "matches": False}
    digest = _sha256(path)
    return {
        "path": str(path),
        "exists": True,
        "sha256": digest,
        "matches": digest == reference["sha256"],
        "route": reference.get("route"),
        "viewport": reference.get("viewport"),
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
    comparisons = [
        capture for capture in result["captures"] if capture.get("comparison")
    ]
    lines.extend(["", "## Reference/current comparison", ""])
    if not comparisons:
        lines.append("- unavailable: manifest has no capture for the configured reference route")
    for capture in comparisons:
        comparison = capture["comparison"]
        lines.extend(
            [
                "### `%s`" % capture["id"],
                "",
                "- reference/current distinct: `true`",
                "- reference self-check: `%s`" % comparison["self_check"]["passes"],
                "- all machine gates: `%s`" % comparison["gates"]["all_machine_gates"],
                "- header anchor error: `%s`" % comparison["anchors"]["header_bottom_error"],
                "- desk anchor error: `%s`" % comparison["anchors"]["desk_top_error"],
                "",
                "| region | RGB delta | LAB delta | Delta E | MAE | edge IoU |",
                "|---|---|---|---:|---:|---:|",
            ]
        )
        for name, values in comparison["regions"].items():
            lines.append(
                "| %s | %s | %s | %.3f | %.3f | %.3f |"
                % (
                    name,
                    ", ".join("%.3f" % value for value in values["rgb_delta_mean"]),
                    ", ".join("%.3f" % value for value in values["lab_delta_mean"]),
                    values["delta_e_mean"],
                    values["mae"],
                    values["edge_iou"],
                )
            )
    baseline_comparisons = [
        capture
        for capture in result["captures"]
        if capture.get("baseline_comparison")
    ]
    lines.extend(["", "## Before/after ROI audit", ""])
    if not baseline_comparisons:
        lines.append("- unavailable: manifest has no baseline comparison entries")
    for capture in baseline_comparisons:
        baseline = capture["baseline_comparison"]
        lines.extend(
            [
                "### `%s`" % capture["id"],
                "",
                "- changed pixels: `%d`" % baseline["changed_pixels_total"],
                "- allowed changed pixels: `%d`" % baseline["changed_pixels_allowed"],
                "- unexpected changed pixels: `%d`" % baseline["changed_pixels_unexpected"],
                "",
                "| ROI | changed | allowed | unexpected |",
                "|---|---:|---:|---:|",
            ]
        )
        for name, values in baseline["rois"].items():
            lines.append(
                "| %s | %d | %d | %d |"
                % (
                    name,
                    values["changed_pixels"],
                    values["allowed_pixels"],
                    values["unexpected_pixels"],
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
            "- 合计：__/100（A～E 各自得分率均须 ≥90%）",
            "",
            "> This skeleton is evidence, not user style approval.",
        ]
    )
    return "\n".join(lines) + "\n"


def analyze_manifest(
    manifest_path: Path,
    config: Dict[str, Any],
    output: Path,
    require_reference_comparison: bool = True,
) -> Dict[str, Any]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    captures = manifest.get("captures")
    if not isinstance(captures, list) or not captures:
        raise ValueError("manifest must contain a non-empty captures list")
    reference = _reference_status(config)
    if not reference["exists"]:
        raise ValueError("reference image does not exist: %s" % reference["path"])
    if not reference["matches"]:
        raise ValueError(
            "reference SHA-256 mismatch: expected=%s actual=%s"
            % (config["reference"]["sha256"], reference["sha256"])
        )
    reference_route = config["reference"].get("route")
    matching_routes = [
        capture for capture in captures if capture.get("route") == reference_route
    ]
    if require_reference_comparison and not matching_routes:
        actual_routes = sorted(
            {str(capture.get("route", "<missing>")) for capture in captures}
        )
        raise ValueError(
            "manifest does not contain reference route %s; got %s"
            % (reference_route, ", ".join(actual_routes))
        )

    raw_capture_root = manifest.get("capture_root")
    capture_base = (
        manifest_path.parent
        if raw_capture_root is None
        else _resolve_path(str(raw_capture_root), manifest_path.parent)
    )
    output.mkdir(parents=True, exist_ok=True)
    mask_dir = output / "masks"
    mask_dir.mkdir(parents=True, exist_ok=True)
    comparison_dir = output / "comparisons"
    comparison_dir.mkdir(parents=True, exist_ok=True)
    analyzed = [
        _analyze_capture(
            capture,
            capture_base,
            config,
            mask_dir,
            comparison_dir,
        )
        for capture in captures
    ]
    drift = _black_point_drift(analyzed)
    max_drift = float(config["characters"]["black_point_drift_max"])
    for item in drift.values():
        item["passes"] = None if item["drift"] is None else item["drift"] <= max_drift
    result = {
        "schema_version": 2,
        "commit": manifest.get("commit"),
        "manifest": str(manifest_path.resolve()),
        "capture_root": str(capture_base.resolve()),
        "reference": reference,
        "captures": analyzed,
        "black_point_drift": drift,
        "thresholds": config,
    }
    serialized_result = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    report = _score_markdown(result)
    (output / "fidelity_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (output / "fidelity_metrics.json").write_text(
        serialized_result, encoding="utf-8"
    )
    (output / "fidelity_report.md").write_text(report, encoding="utf-8")
    # Preserve the previous filenames for existing local workflows.
    (output / "metrics.json").write_text(serialized_result, encoding="utf-8")
    (output / "score.md").write_text(report, encoding="utf-8")

    compared = [capture for capture in analyzed if capture.get("comparison")]
    if compared:
        target_viewport = list(config["reference"]["viewport"])
        primary = next(
            (
                capture
                for capture in compared
                if capture["viewport"] == target_viewport
            ),
            compared[0],
        )
        for artifact_path in primary["comparison"]["artifacts"].values():
            source = Path(artifact_path)
            shutil.copyfile(source, output / source.name)
    return result


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Measure Battle UI V2 layout, alpha boxes, boss scale and semantic color evidence."
    )
    parser.add_argument("--manifest", type=Path, help="Capture manifest JSON.")
    parser.add_argument("--capture-root", type=Path, help="Capture root used to generate a manifest.")
    parser.add_argument("--commit", help="Commit recorded in a generated manifest.")
    parser.add_argument("--write-manifest", type=Path, help="Destination for a generated manifest.")
    parser.add_argument(
        "--config", type=Path, default=DEFAULT_CONFIG, help="Single threshold config JSON."
    )
    parser.add_argument("--output", type=Path, help="Output directory for metrics, score and masks.")
    parser.add_argument(
        "--diagnostics-only",
        action="store_true",
        help="Allow manifests without the configured reference route; reference-route captures are still compared.",
    )
    return parser


def main() -> int:
    parser = _parser()
    args = parser.parse_args()
    if args.capture_root is not None:
        if args.write_manifest is None:
            parser.error("--write-manifest is required with --capture-root")
        manifest = build_manifest(args.capture_root, args.commit or "unknown")
        args.write_manifest.parent.mkdir(parents=True, exist_ok=True)
        args.write_manifest.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    if args.manifest is not None:
        if args.output is None:
            parser.error("--output is required with --manifest")
        analyze_manifest(
            args.manifest,
            load_config(args.config),
            args.output,
            require_reference_comparison=not args.diagnostics_only,
        )
    elif args.capture_root is None:
        parser.error("--manifest or --capture-root is required")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
