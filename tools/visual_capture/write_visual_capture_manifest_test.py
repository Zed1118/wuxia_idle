import importlib.util
import tempfile
import unittest
from pathlib import Path

from PIL import Image


MODULE_PATH = Path(__file__).with_name("write_visual_capture_manifest.py")
SPEC = importlib.util.spec_from_file_location("capture_manifest", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
manifest_writer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(manifest_writer)


class CaptureManifestTest(unittest.TestCase):
    def test_binds_current_route_png_log_viewport_and_dpr(self) -> None:
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch)
            route = "phase0a_battle_playable"
            capture_dir = root / route / "1280x720"
            capture_dir.mkdir(parents=True)
            png = capture_dir / f"{route}.png"
            Image.new("RGB", (2560, 1440)).save(png)
            png.with_suffix(".log").write_text(
                "VISUAL_ROUTE_STATE: route=phase0a_battle_playable seed=42 tick=9\n"
                "VISUAL_CAPTURE: window_id:123\n",
                encoding="utf-8",
            )

            manifest = manifest_writer.build_manifest(root, "a" * 40)

            self.assertEqual(manifest["schema_version"], 3)
            capture = manifest["captures"][0]
            self.assertEqual(capture["route"], route)
            self.assertEqual(capture["viewport"], {"width": 1280, "height": 720})
            self.assertEqual(capture["dpr"], 2.0)
            self.assertEqual(capture["seed"], 42)
            self.assertEqual(capture["tick"], 9)
            self.assertEqual(capture["native_window_id"], 123)
            self.assertEqual(len(capture["png_sha256"]), 64)

    def test_rejects_log_route_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch)
            capture_dir = root / "phase0a_battle_playable" / "100x50"
            capture_dir.mkdir(parents=True)
            png = capture_dir / "phase0a_battle_playable.png"
            Image.new("RGB", (100, 50)).save(png)
            png.with_suffix(".log").write_text(
                "VISUAL_ROUTE_STATE: route=main_menu seed=x tick=1\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "route mismatch"):
                manifest_writer.build_manifest(root, "a" * 40)


if __name__ == "__main__":
    unittest.main()
