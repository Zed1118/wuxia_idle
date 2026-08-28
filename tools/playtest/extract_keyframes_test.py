#!/usr/bin/env python3
"""Tests for checkpoint-bound video frame extraction."""

import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from PIL import Image


MODULE_PATH = Path(__file__).with_name("extract_keyframes.py")
SPEC = importlib.util.spec_from_file_location("extract_keyframes", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
extractor = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(extractor)


class ExtractKeyframesTest(unittest.TestCase):
    def _fixture(self, root: Path) -> tuple[Path, Path, int]:
        video = root / "recording.mov"
        subprocess.run(
            [
                "ffmpeg",
                "-hide_banner",
                "-loglevel",
                "error",
                "-f",
                "lavfi",
                "-i",
                "testsrc=size=160x90:rate=10:duration=5",
                "-pix_fmt",
                "yuv420p",
                "-y",
                str(video),
            ],
            check=True,
        )
        start = 1_700_000_000_000
        log = root / "actions.jsonl"
        records = []
        for sequence, label in enumerate(extractor.DEFAULT_LABELS):
            records.append(
                {
                    "event": "action",
                    "action_type": "checkpoint",
                    "id": f"mark_{label}",
                    "label": label,
                    "sequence": sequence,
                    "epoch_ms": start + 500 + sequence * 1000,
                }
            )
        log.write_text(
            "".join(json.dumps(record) + "\n" for record in records),
            encoding="utf-8",
        )
        return video, log, start

    def test_extracts_four_named_nonempty_pngs(self) -> None:
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch)
            video, log, start = self._fixture(root)
            frames = extractor.extract_keyframes(
                video=video,
                actions_log=log,
                output_dir=root / "frames",
                record_start_epoch_ms=start,
            )
            self.assertEqual([frame["label"] for frame in frames], list(extractor.DEFAULT_LABELS))
            self.assertEqual([frame["video_timestamp_ms"] for frame in frames], [500, 1500, 2500, 3500])
            for frame in frames:
                png = root / "frames" / frame["png"]
                with Image.open(png) as image:
                    self.assertEqual(image.size, (160, 90))
                self.assertEqual(len(frame["png_sha256"]), 64)

    def test_missing_required_checkpoint_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch)
            video, log, start = self._fixture(root)
            lines = log.read_text(encoding="utf-8").splitlines()
            log.write_text("\n".join(lines[:-1]) + "\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "missing required checkpoints: settlement"):
                extractor.extract_keyframes(
                    video=video,
                    actions_log=log,
                    output_dir=root / "frames",
                    record_start_epoch_ms=start,
                )


if __name__ == "__main__":
    unittest.main()
