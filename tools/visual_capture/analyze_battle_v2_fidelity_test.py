import json
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

import analyze_battle_v2_fidelity as fidelity


class BattleV2FidelityTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.config = fidelity.load_config(
            Path(__file__).with_name("battle_v2_fidelity_config.json")
        )

    def tearDown(self):
        self.temp.cleanup()

    def _rgba(self, name, size, color=(120, 110, 90, 255)):
        path = self.root / name
        Image.new("RGBA", size, color).save(path)
        return path

    def test_config_is_single_source_for_report_thresholds(self):
        self.assertEqual(self.config["characters"]["alpha_threshold"], 16)
        self.assertEqual(self.config["characters"]["boss_area_ratio"], [1.25, 1.45])
        self.assertEqual(
            self.config["semantic_color"]["non_ultimate_area_max"], 0.08
        )
        self.assertEqual(self.config["contrast"]["body_min"], 4.5)

    def test_alpha_bbox_uses_strict_threshold(self):
        rgba = np.zeros((6, 8, 4), dtype=np.uint8)
        rgba[2:5, 3:7, 3] = 17
        rgba[0, 0, 3] = 16
        self.assertEqual(fidelity.alpha_bbox(rgba, 16), [3, 2, 4, 3])

    def test_manifest_measures_regions_dpr_boss_and_semantic_mask(self):
        screen = self._rgba("screen.png", (200, 100))
        player = self._rgba("player.png", (10, 10), (40, 40, 40, 255))
        boss = self._rgba("boss.png", (10, 13), (40, 40, 40, 255))
        semantic = np.zeros((100, 200, 4), dtype=np.uint8)
        semantic[:10, :20] = (255, 0, 0, 255)
        semantic_path = self.root / "semantic.png"
        Image.fromarray(semantic).save(semantic_path)
        manifest = {
            "schema_version": 1,
            "commit": "abc123",
            "captures": [
                {
                    "id": "s1_100x50",
                    "route": "battle_v2_neutral_3v3",
                    "seed": 20260719,
                    "tick": 0,
                    "viewport": {"width": 100, "height": 50},
                    "png": str(screen),
                    "regions": {
                        "header": {"x": 0, "y": 0, "width": 100, "height": 3.25},
                        "battlefield": {"x": 0, "y": 3.25, "width": 100, "height": 34},
                        "command_desk": {"x": 0, "y": 37.25, "width": 100, "height": 12.5},
                        "focus": {"x": 0, "y": 0, "width": 19, "height": 12.5},
                        "skills": {"x": 19, "y": 0, "width": 60, "height": 12.5},
                        "pouch": {"x": 79, "y": 0, "width": 21, "height": 12.5}
                    },
                    "layers": {
                        "semantic_ui": str(semantic_path),
                        "characters": [
                            {"id": "player", "path": str(player), "boss": False, "side": "left"},
                            {"id": "boss", "path": str(boss), "boss": True, "side": "right"}
                        ]
                    }
                }
            ]
        }
        manifest_path = self.root / "manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        output = self.root / "analysis"

        result = fidelity.analyze_manifest(manifest_path, self.config, output)
        capture = result["captures"][0]

        self.assertEqual(capture["png_pixels"], [200, 100])
        self.assertEqual(capture["dpr"], 2.0)
        self.assertAlmostEqual(capture["layout"]["header"], 0.065)
        self.assertAlmostEqual(capture["layout"]["skills"], 0.60)
        self.assertAlmostEqual(capture["boss_area_ratio"], 1.3)
        self.assertAlmostEqual(capture["semantic_color_area"], 0.01)
        self.assertEqual(capture["semantic_color_method"], "diagnostic_layer")
        self.assertTrue((output / "masks" / "s1_100x50_semantic.png").exists())

    def test_missing_diagnostic_layers_are_not_reported_as_exact(self):
        screen = self._rgba("screen.png", (128, 72), (255, 0, 0, 255))
        manifest = {
            "captures": [
                {
                    "id": "fallback",
                    "route": "battle_v2_neutral_3v3",
                    "viewport": {"width": 128, "height": 72},
                    "png": str(screen)
                }
            ]
        }
        manifest_path = self.root / "manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

        result = fidelity.analyze_manifest(
            manifest_path, self.config, self.root / "analysis"
        )
        capture = result["captures"][0]

        self.assertEqual(capture["semantic_color_method"], "full_content_approximate")
        self.assertIsNone(capture["boss_area_ratio"])
        self.assertIn("missing regions", capture["warnings"])


if __name__ == "__main__":
    unittest.main()
