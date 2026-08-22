#!/usr/bin/env python3
"""Write provenance-bound manifests for current visual-route captures."""

import argparse
import hashlib
import json
import os
import re
import subprocess
import tempfile
from pathlib import Path
from typing import Any, Dict, Optional

from PIL import Image


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


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def work_tree_state(repo_root: Path) -> Dict[str, Any]:
    """Resolve the rendered working tree without touching the real index."""

    def git(*args: str, env: Optional[Dict[str, str]] = None) -> str:
        return subprocess.run(
            ("git", "-C", str(repo_root)) + args,
            check=True,
            capture_output=True,
            text=True,
            env=env,
        ).stdout.strip()

    head_tree = git("rev-parse", "HEAD^{tree}")
    with tempfile.TemporaryDirectory() as scratch:
        scratch_env = dict(os.environ)
        scratch_env["GIT_INDEX_FILE"] = str(Path(scratch) / "index")
        git("read-tree", "HEAD", env=scratch_env)
        git("add", "-A", env=scratch_env)
        tree = git("write-tree", env=scratch_env)
    return {"tree": tree, "head_tree": head_tree, "dirty": tree != head_tree}


def build_manifest(
    capture_root: Path,
    commit: str,
    tree: Optional[str] = None,
    dirty: Optional[bool] = None,
) -> Dict[str, Any]:
    capture_root = capture_root.resolve()
    captures = []
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
                f"{png_path} has inconsistent inferred DPR: {dpr_x:.4f} vs {dpr_y:.4f}"
            )

        log_path = png_path.with_suffix(".log")
        log_text = (
            log_path.read_text(encoding="utf-8", errors="replace")
            if log_path.exists()
            else ""
        )
        state_match = ROUTE_STATE_PATTERN.search(log_text)
        seed: Any = "visual-route-host-fixture-20260627"
        tick = None
        if state_match is not None:
            logged_route = state_match.group("route")
            if logged_route != route:
                raise ValueError(
                    f"{log_path} route mismatch: directory={route} log={logged_route}"
                )
            raw_seed = state_match.group("seed")
            seed = int(raw_seed) if raw_seed.isdigit() else raw_seed
            tick = int(state_match.group("tick"))
        capture_match = WINDOW_CAPTURE_PATTERN.search(log_text)
        native_window_id = None
        capture_method = None
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
                "id": f"{route}_{png_path.parent.name}",
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
        "schema_version": 3,
        "commit": commit,
        "tree": tree,
        "dirty": dirty,
        "capture_root": str(capture_root),
        "captures": captures,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-root", type=Path, required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--repo-root", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    tree = None
    dirty = None
    if args.repo_root is not None:
        state = work_tree_state(args.repo_root)
        tree = state["tree"]
        dirty = state["dirty"]
    manifest = build_manifest(args.capture_root, args.commit, tree, dirty)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
