#!/usr/bin/env python3
"""Write provenance, media, action, and save-bound playtest manifests."""

import argparse
import hashlib
import importlib.util
import json
import subprocess
from pathlib import Path
from typing import Any


REQUIRED_CHECKPOINTS = ("entry", "first_contact", "skill_release", "settlement")
VISUAL_MANIFEST_PATH = (
    Path(__file__).resolve().parents[1]
    / "visual_capture"
    / "write_visual_capture_manifest.py"
)
VISUAL_SPEC = importlib.util.spec_from_file_location(
    "visual_capture_manifest", VISUAL_MANIFEST_PATH
)
assert VISUAL_SPEC is not None and VISUAL_SPEC.loader is not None
visual_manifest = importlib.util.module_from_spec(VISUAL_SPEC)
VISUAL_SPEC.loader.exec_module(visual_manifest)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(path: Path, root: Path) -> str:
    return str(path.resolve().relative_to(root.resolve()))


def parse_shasum(path: Path) -> dict[str, str]:
    slots: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if not raw_line.strip():
            continue
        digest, raw_name = raw_line.split(maxsplit=1)
        name = Path(raw_name.strip()).name
        if len(digest) != 64:
            raise ValueError(f"invalid SHA256 in {path}: {digest}")
        slots[name] = digest
    expected = {f"wuxia_save_slot{slot}.isar" for slot in (1, 2, 3)}
    if set(slots) != expected:
        raise ValueError(f"{path} must contain exactly the three save slots")
    return slots


def video_metadata(video: Path) -> dict[str, Any]:
    result = subprocess.run(
        [
            "ffprobe",
            "-v",
            "error",
            "-select_streams",
            "v:0",
            "-show_entries",
            "stream=codec_name,width,height:format=duration",
            "-of",
            "json",
            str(video),
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    data = json.loads(result.stdout)
    if not data.get("streams"):
        raise ValueError("recording contains no video stream")
    stream = data["streams"][0]
    return {
        "codec": stream["codec_name"],
        "width": int(stream["width"]),
        "height": int(stream["height"]),
        "duration_seconds": float(data["format"]["duration"]),
    }


def read_actions(path: Path) -> list[dict[str, Any]]:
    actions = []
    completed = False
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if not raw_line.strip():
            continue
        record = json.loads(raw_line)
        if record.get("event") == "action":
            actions.append(record)
        elif record.get("event") == "complete":
            completed = True
    if not actions or not completed:
        raise ValueError("action log must contain actions and a complete record")
    sequences = [record.get("sequence") for record in actions]
    if sequences != list(range(len(actions))):
        raise ValueError("action log sequence must be contiguous from zero")
    for record in actions:
        window = record.get("window")
        if not isinstance(window, dict) or not {
            "window_id",
            "bounds_points",
            "backing_scale",
        }.issubset(window):
            raise ValueError("every action must include refreshed window bounds and scale")
    return actions


def build_manifest(
    *,
    capture_root: Path,
    scenario_path: Path,
    actions_log: Path,
    video: Path,
    keyframes_index: Path,
    save_before: Path,
    save_after: Path,
    save_backup_dir: Path,
    commit: str,
    provenance: dict[str, Any],
    record_start_epoch_ms: int,
) -> dict[str, Any]:
    capture_root = capture_root.resolve()
    scenario = json.loads(scenario_path.read_text(encoding="utf-8"))
    actions = read_actions(actions_log)
    keyframes = json.loads(keyframes_index.read_text(encoding="utf-8"))
    labels = [frame.get("label") for frame in keyframes]
    if labels != list(REQUIRED_CHECKPOINTS):
        raise ValueError(
            "keyframes must contain entry, first_contact, skill_release, settlement in order"
        )
    enriched_keyframes = []
    for frame in keyframes:
        png = keyframes_index.parent / frame["png"]
        if not png.is_file() or sha256(png) != frame.get("png_sha256"):
            raise ValueError(f"keyframe SHA mismatch: {png}")
        enriched = dict(frame)
        enriched["png"] = relative(png, capture_root)
        enriched_keyframes.append(enriched)

    before = parse_shasum(save_before)
    after = parse_shasum(save_after)
    backup = {
        path.name: sha256(path)
        for path in sorted(save_backup_dir.glob("wuxia_save_slot[123].isar"))
    }
    if before != backup or after != backup:
        raise ValueError("save slots do not match the cold backup before and after capture")

    video_info = video_metadata(video)
    return {
        "schema_version": 1,
        "kind": "production_playtest_capture",
        "scenario": {
            "id": scenario["id"],
            "production_entry": scenario.get("production_entry") is True,
            "path": relative(scenario_path, capture_root),
            "sha256": sha256(scenario_path),
        },
        "commit": commit,
        "tree": provenance["tree"],
        "head_tree": provenance["head_tree"],
        "dirty": provenance["dirty"],
        "capture_root": str(capture_root),
        "record_start_epoch_ms": record_start_epoch_ms,
        "window_bounds_policy": "CGWindow bounds and display scale refreshed before every action",
        "actions": {
            "count": len(actions),
            "log": relative(actions_log, capture_root),
            "log_sha256": sha256(actions_log),
            "window_sample_count": len(actions),
        },
        "video": {
            "path": relative(video, capture_root),
            "sha256": sha256(video),
            **video_info,
        },
        "keyframes": enriched_keyframes,
        "save_protection": {
            "restored": True,
            "before": before,
            "after": after,
            "cold_backup": backup,
            "cold_backup_dir": str(save_backup_dir.resolve()),
            "before_record": relative(save_before, capture_root),
            "after_record": relative(save_after, capture_root),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-root", type=Path, required=True)
    parser.add_argument("--scenario", type=Path, required=True)
    parser.add_argument("--actions-log", type=Path, required=True)
    parser.add_argument("--video", type=Path, required=True)
    parser.add_argument("--keyframes-index", type=Path, required=True)
    parser.add_argument("--save-before", type=Path, required=True)
    parser.add_argument("--save-after", type=Path, required=True)
    parser.add_argument("--save-backup-dir", type=Path, required=True)
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--record-start-epoch-ms", type=int, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    provenance = visual_manifest.work_tree_state(args.repo_root)
    commit = subprocess.run(
        ["git", "-C", str(args.repo_root), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    manifest = build_manifest(
        capture_root=args.capture_root,
        scenario_path=args.scenario,
        actions_log=args.actions_log,
        video=args.video,
        keyframes_index=args.keyframes_index,
        save_before=args.save_before,
        save_after=args.save_after,
        save_backup_dir=args.save_backup_dir,
        commit=commit,
        provenance=provenance,
        record_start_epoch_ms=args.record_start_epoch_ms,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(
        f"PLAYTEST_MANIFEST captures={len(manifest['keyframes'])} "
        f"dirty={str(manifest['dirty']).lower()} output={args.output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
