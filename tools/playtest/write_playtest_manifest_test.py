#!/usr/bin/env python3
"""Tests for production playtest provenance manifests."""

import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from PIL import Image


MODULE_PATH = Path(__file__).with_name("write_playtest_manifest.py")
SPEC = importlib.util.spec_from_file_location("playtest_manifest", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
writer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(writer)


class WritePlaytestManifestTest(unittest.TestCase):
    def _fixture(self, root: Path) -> dict[str, Path]:
        scenario = root / "scenario.json"
        scenario.write_text(
            json.dumps({"id": "stage_01_03", "production_entry": True}),
            encoding="utf-8",
        )
        actions = root / "actions.jsonl"
        records = []
        for index, label in enumerate(writer.REQUIRED_CHECKPOINTS):
            records.append(
                {
                    "event": "action",
                    "action_type": "checkpoint",
                    "id": f"mark_{label}",
                    "label": label,
                    "sequence": index,
                    "epoch_ms": 1000 + index,
                    "window": {
                        "window_id": 7,
                        "bounds_points": {"x": 0, "y": 0, "width": 100, "height": 50},
                        "backing_scale": 2,
                    },
                }
            )
        records.append({"event": "complete", "action_count": 4})
        actions.write_text(
            "".join(json.dumps(record) + "\n" for record in records),
            encoding="utf-8",
        )
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
                "color=size=100x50:duration=1",
                "-pix_fmt",
                "yuv420p",
                "-y",
                str(video),
            ],
            check=True,
        )
        keyframes_dir = root / "keyframes"
        keyframes_dir.mkdir()
        keyframes = []
        for index, label in enumerate(writer.REQUIRED_CHECKPOINTS, start=1):
            png = keyframes_dir / f"{index:02d}_{label}.png"
            Image.new("RGB", (100, 50), (index, 2, 3)).save(png)
            keyframes.append(
                {
                    "label": label,
                    "action_id": f"mark_{label}",
                    "action_sequence": index - 1,
                    "action_epoch_ms": 1000 + index - 1,
                    "video_timestamp_ms": index * 10,
                    "png": png.name,
                    "png_sha256": writer.sha256(png),
                }
            )
        keyframes_index = keyframes_dir / "keyframes.json"
        keyframes_index.write_text(json.dumps(keyframes), encoding="utf-8")
        backup = root / "backup"
        backup.mkdir()
        hashes = []
        for slot in (1, 2, 3):
            save = backup / f"wuxia_save_slot{slot}.isar"
            save.write_bytes(bytes([slot]) * 16)
            hashes.append(f"{writer.sha256(save)}  {save}\n")
        before = root / "save_before.sha256"
        after = root / "save_after.sha256"
        before.write_text("".join(hashes), encoding="utf-8")
        after.write_text("".join(hashes), encoding="utf-8")
        return {
            "scenario": scenario,
            "actions": actions,
            "video": video,
            "keyframes": keyframes_index,
            "backup": backup,
            "before": before,
            "after": after,
        }

    def test_binds_media_actions_provenance_and_restored_saves(self) -> None:
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch)
            fixture = self._fixture(root)
            manifest = writer.build_manifest(
                capture_root=root,
                scenario_path=fixture["scenario"],
                actions_log=fixture["actions"],
                video=fixture["video"],
                keyframes_index=fixture["keyframes"],
                save_before=fixture["before"],
                save_after=fixture["after"],
                save_backup_dir=fixture["backup"],
                commit="a" * 40,
                provenance={"tree": "b" * 40, "head_tree": "c" * 40, "dirty": True},
                record_start_epoch_ms=900,
            )
            self.assertEqual(manifest["kind"], "production_playtest_capture")
            self.assertTrue(manifest["scenario"]["production_entry"])
            self.assertEqual(manifest["actions"]["window_sample_count"], 4)
            self.assertEqual(len(manifest["video"]["sha256"]), 64)
            self.assertEqual(
                [frame["label"] for frame in manifest["keyframes"]],
                list(writer.REQUIRED_CHECKPOINTS),
            )
            self.assertTrue(manifest["save_protection"]["restored"])
            self.assertTrue(manifest["dirty"])

    def test_save_residue_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch)
            fixture = self._fixture(root)
            fixture["after"].write_text(
                fixture["after"].read_text(encoding="utf-8").replace("a", "b", 1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "do not match the cold backup"):
                writer.build_manifest(
                    capture_root=root,
                    scenario_path=fixture["scenario"],
                    actions_log=fixture["actions"],
                    video=fixture["video"],
                    keyframes_index=fixture["keyframes"],
                    save_before=fixture["before"],
                    save_after=fixture["after"],
                    save_backup_dir=fixture["backup"],
                    commit="a" * 40,
                    provenance={"tree": "b" * 40, "head_tree": "b" * 40, "dirty": False},
                    record_start_epoch_ms=900,
                )


if __name__ == "__main__":
    unittest.main()
