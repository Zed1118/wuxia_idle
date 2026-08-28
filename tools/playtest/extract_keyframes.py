#!/usr/bin/env python3
"""Extract checkpoint-bound PNG frames from a playtest recording."""

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from typing import Any


SAFE_LABEL = re.compile(r"^[a-z][a-z0-9_]*$")
DEFAULT_LABELS = ("entry", "first_contact", "skill_release", "settlement")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def video_duration_seconds(video: Path) -> float:
    result = subprocess.run(
        [
            "ffprobe",
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            str(video),
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    duration = float(result.stdout.strip())
    if duration <= 0:
        raise ValueError("recording duration must be positive")
    return duration


def checkpoint_actions(actions_log: Path) -> dict[str, dict[str, Any]]:
    checkpoints: dict[str, dict[str, Any]] = {}
    for line_number, raw_line in enumerate(
        actions_log.read_text(encoding="utf-8").splitlines(), start=1
    ):
        if not raw_line.strip():
            continue
        record = json.loads(raw_line)
        if record.get("event") != "action" or record.get("action_type") != "checkpoint":
            continue
        label = record.get("label")
        if not isinstance(label, str) or not SAFE_LABEL.fullmatch(label):
            raise ValueError(f"invalid checkpoint label at line {line_number}: {label!r}")
        if label in checkpoints:
            raise ValueError(f"duplicate checkpoint label in action log: {label}")
        if not isinstance(record.get("epoch_ms"), int):
            raise ValueError(f"checkpoint {label} is missing integer epoch_ms")
        checkpoints[label] = record
    return checkpoints


def extract_keyframes(
    *,
    video: Path,
    actions_log: Path,
    output_dir: Path,
    record_start_epoch_ms: int,
    labels: tuple[str, ...] = DEFAULT_LABELS,
) -> list[dict[str, Any]]:
    duration = video_duration_seconds(video)
    checkpoints = checkpoint_actions(actions_log)
    missing = [label for label in labels if label not in checkpoints]
    if missing:
        raise ValueError(f"missing required checkpoints: {', '.join(missing)}")
    output_dir.mkdir(parents=True, exist_ok=True)
    extracted: list[dict[str, Any]] = []
    for ordinal, label in enumerate(labels, start=1):
        checkpoint = checkpoints[label]
        source_seconds = (checkpoint["epoch_ms"] - record_start_epoch_ms) / 1000.0
        if source_seconds < 0 or source_seconds >= duration:
            raise ValueError(
                f"checkpoint {label} timestamp {source_seconds:.3f}s is outside "
                f"recording duration {duration:.3f}s"
            )
        destination = output_dir / f"{ordinal:02d}_{label}.png"
        subprocess.run(
            [
                "ffmpeg",
                "-hide_banner",
                "-loglevel",
                "error",
                "-ss",
                f"{source_seconds:.3f}",
                "-i",
                str(video),
                "-frames:v",
                "1",
                "-update",
                "1",
                "-y",
                str(destination),
            ],
            check=True,
        )
        if not destination.is_file() or destination.stat().st_size == 0:
            raise ValueError(f"ffmpeg did not produce keyframe {destination}")
        extracted.append(
            {
                "label": label,
                "action_id": checkpoint["id"],
                "action_sequence": checkpoint["sequence"],
                "action_epoch_ms": checkpoint["epoch_ms"],
                "video_timestamp_ms": round(source_seconds * 1000),
                "png": destination.name,
                "png_sha256": sha256(destination),
            }
        )
    return extracted


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--video", type=Path, required=True)
    parser.add_argument("--actions-log", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--record-start-epoch-ms", type=int, required=True)
    parser.add_argument(
        "--labels",
        default=",".join(DEFAULT_LABELS),
        help="Comma-separated checkpoint labels in extraction order.",
    )
    args = parser.parse_args()
    labels = tuple(item.strip() for item in args.labels.split(",") if item.strip())
    if not labels or any(not SAFE_LABEL.fullmatch(label) for label in labels):
        parser.error("--labels must contain safe lower_snake_case names")
    frames = extract_keyframes(
        video=args.video,
        actions_log=args.actions_log,
        output_dir=args.output_dir,
        record_start_epoch_ms=args.record_start_epoch_ms,
        labels=labels,
    )
    index_path = args.output_dir / "keyframes.json"
    index_path.write_text(json.dumps(frames, indent=2) + "\n", encoding="utf-8")
    print(f"KEYFRAMES extracted={len(frames)} index={index_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
