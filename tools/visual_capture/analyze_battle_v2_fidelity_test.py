import copy
import hashlib
import json
import subprocess
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
        path.parent.mkdir(parents=True, exist_ok=True)
        Image.new("RGBA", size, color).save(path)
        return path

    def _comparison_config(
        self,
        reference,
        *,
        reference_viewport=(100, 50),
        header_bottom=10,
        desk_top=40,
    ):
        config = copy.deepcopy(self.config)
        config["reference"] = {
            "path": str(reference),
            "sha256": hashlib.sha256(reference.read_bytes()).hexdigest(),
            "route": "battle_tap_live",
            "viewport": list(reference_viewport),
            "fit": "cover_center",
        }
        config["comparison"] = {
            "boundaries": {
                "header_bottom": header_bottom,
                "desk_top": desk_top,
            },
            "edge_threshold_low": 50.0,
            "edge_threshold_high": 150.0,
            "gates": {
                "mean_rgb_abs_max": {"header": 12.0, "field": 12.0, "desk": 12.0},
                "mae_max": {"header": 12.0, "field": 22.0, "desk": 14.0},
                "edge_iou_min": {"header": 0.22, "field": 0.12, "desk": 0.18},
                "anchor_error_max": 1.0,
            },
        }
        return config

    def test_config_is_single_source_for_report_thresholds(self):
        self.assertEqual(self.config["characters"]["alpha_threshold"], 16)
        self.assertEqual(self.config["characters"]["boss_area_ratio"], [1.25, 1.45])
        self.assertEqual(
            self.config["semantic_color"]["non_ultimate_area_max"], 0.08
        )
        self.assertEqual(self.config["contrast"]["body_min"], 4.5)
        self.assertEqual(self.config["reference"]["route"], "battle_tap_live")
        self.assertEqual(
            self.config["comparison"]["boundaries"],
            {"header_bottom": 60, "desk_top": 700},
        )
        self.assertEqual(
            self.config["layout"]["command_desk_horizontal"],
            {
                "focus": [0.15, 0.17],
                "skills": [0.49, 0.55],
                "pouch": [0.19, 0.21],
            },
        )

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
                            {
                                "id": "boss",
                                "path": str(boss),
                                "boss": True,
                                "side": "right",
                                "render_scale": 0.5,
                            }
                        ]
                    }
                }
            ]
        }
        manifest_path = self.root / "manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        output = self.root / "analysis"

        result = fidelity.analyze_manifest(
            manifest_path,
            self.config,
            output,
            require_reference_comparison=False,
        )
        capture = result["captures"][0]

        self.assertEqual(capture["png_pixels"], [200, 100])
        self.assertEqual(capture["dpr"], 2.0)
        self.assertAlmostEqual(capture["layout"]["header"], 0.065)
        self.assertAlmostEqual(capture["layout"]["skills"], 0.60)
        self.assertAlmostEqual(capture["boss_area_ratio"], 0.325)
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
            manifest_path,
            self.config,
            self.root / "analysis",
            require_reference_comparison=False,
        )
        capture = result["captures"][0]

        self.assertEqual(capture["semantic_color_method"], "full_content_approximate")
        self.assertIsNone(capture["boss_area_ratio"])
        self.assertIn("missing regions", capture["warnings"])

    def test_build_manifest_records_route_state_viewport_and_dpr(self):
        capture_root = self.root / "baseline"
        dynamic_dir = capture_root / "battle_v2_fast_forward_peak" / "1280x720"
        dynamic_dir.mkdir(parents=True)
        self._rgba(
            "baseline/battle_v2_fast_forward_peak/1280x720/battle_v2_fast_forward_peak.png",
            (2560, 1440),
        )
        (dynamic_dir / "battle_v2_fast_forward_peak.log").write_text(
            "flutter: VISUAL_ROUTE_STATE: route=battle_v2_fast_forward_peak "
            "seed=20260719 tick=1 steps=1 leftAlive=3 rightAlive=3 "
            "target=fastForwardPeak actions=3 peakActions=3\n"
            "flutter: VISUAL_FIDELITY_REGIONS: "
            '{"header":{"x":0,"y":0,"width":1280,"height":47},'
            '"battlefield":{"x":0,"y":47,"width":1280,"height":489},'
            '"command_desk":{"x":0,"y":536,"width":1280,"height":184}}\n'
            "VISUAL_CAPTURE: window_id:4172\n",
            encoding="utf-8",
        )
        # Suite captures are grouped by suite name, so route truth comes from
        # the PNG/log filename rather than the group directory.
        static_dir = capture_root / "battle" / "1440x900"
        static_dir.mkdir(parents=True)
        self._rgba(
            "baseline/battle/1440x900/battle_tap_preview.png",
            (2880, 1800),
        )
        (static_dir / "battle_tap_preview.log").write_text(
            "flutter: VISUAL_ROUTE_READY: battle_tap_preview\n",
            encoding="utf-8",
        )

        manifest = fidelity.build_manifest(capture_root, commit="abc123")

        self.assertEqual(manifest["commit"], "abc123")
        self.assertEqual(len(manifest["captures"]), 2)
        dynamic = next(
            item
            for item in manifest["captures"]
            if item["route"] == "battle_v2_fast_forward_peak"
        )
        self.assertEqual(dynamic["seed"], 20260719)
        self.assertEqual(dynamic["tick"], 1)
        self.assertEqual(dynamic["dpr"], 2.0)
        self.assertEqual(dynamic["viewport"], {"width": 1280, "height": 720})
        self.assertEqual(dynamic["native_window_id"], 4172)
        self.assertEqual(dynamic["capture_method"], "window_id")
        self.assertEqual(dynamic["regions"]["command_desk"]["y"], 536)
        self.assertEqual(
            dynamic["png_sha256"],
            hashlib.sha256((dynamic_dir / "battle_v2_fast_forward_peak.png").read_bytes()).hexdigest(),
        )
        self.assertEqual(manifest["capture_root"], str(capture_root.resolve()))
        static = next(
            item for item in manifest["captures"] if item["route"] == "battle_tap_preview"
        )
        self.assertEqual(static["seed"], "visual-route-host-fixture-20260627")
        self.assertIsNone(static["tick"])

    def test_build_manifest_rejects_log_route_mismatch(self):
        capture_root = self.root / "baseline"
        route_dir = capture_root / "battle_tap_live" / "100x50"
        route_dir.mkdir(parents=True)
        self._rgba(
            "baseline/battle_tap_live/100x50/battle_tap_live.png",
            (100, 50),
        )
        (route_dir / "battle_tap_live.log").write_text(
            "VISUAL_ROUTE_STATE: route=battle_audit_tower_14 seed=1 tick=0\n",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(ValueError, "route mismatch"):
            fidelity.build_manifest(capture_root, commit="abc123")

    def test_generated_manifest_can_be_analyzed_outside_capture_root(self):
        capture_root = self.root / "captures"
        route_dir = capture_root / "battle_v2_neutral_3v3" / "100x50"
        route_dir.mkdir(parents=True)
        self._rgba(
            "captures/battle_v2_neutral_3v3/100x50/battle_v2_neutral_3v3.png",
            (100, 50),
        )
        manifest = fidelity.build_manifest(capture_root, commit="abc123")
        manifest_dir = self.root / "evidence"
        manifest_dir.mkdir()
        manifest_path = manifest_dir / "fidelity_manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

        result = fidelity.analyze_manifest(
            manifest_path,
            self.config,
            manifest_dir / "analysis",
            require_reference_comparison=False,
        )

        self.assertEqual(len(result["captures"]), 1)
        self.assertEqual(result["captures"][0]["png_pixels"], [100, 50])

    def test_acceptance_analysis_rejects_current_identical_to_reference(self):
        reference = self._rgba("reference.png", (100, 50))
        config = self._comparison_config(reference)
        manifest = {
            "captures": [
                {
                    "id": "golden",
                    "route": "battle_tap_live",
                    "viewport": {"width": 100, "height": 50},
                    "png": str(reference),
                }
            ]
        }
        manifest_path = self.root / "manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

        with self.assertRaisesRegex(ValueError, "identical to reference"):
            fidelity.analyze_manifest(
                manifest_path,
                config,
                self.root / "analysis",
                require_reference_comparison=True,
            )

    def test_acceptance_analysis_rejects_lossless_reencode_of_reference(self):
        reference = self._rgba("reference.png", (100, 50))
        current = self.root / "current-reencoded.png"
        Image.open(reference).save(current, compress_level=0)
        self.assertNotEqual(
            hashlib.sha256(reference.read_bytes()).hexdigest(),
            hashlib.sha256(current.read_bytes()).hexdigest(),
        )
        config = self._comparison_config(reference)
        manifest = {
            "captures": [
                {
                    "id": "golden-reencoded",
                    "route": "battle_tap_live",
                    "viewport": {"width": 100, "height": 50},
                    "png": str(current),
                }
            ]
        }
        manifest_path = self.root / "manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

        with self.assertRaisesRegex(ValueError, "pixel-identical to reference"):
            fidelity.analyze_manifest(
                manifest_path,
                config,
                self.root / "analysis",
                require_reference_comparison=True,
            )

    def test_reference_comparison_writes_metrics_and_review_artifacts(self):
        reference = self._rgba("reference.png", (100, 50), (100, 100, 100, 255))
        current = self._rgba("current.png", (200, 100), (110, 110, 110, 255))
        config = self._comparison_config(reference)
        manifest = {
            "schema_version": 2,
            "commit": "abc123",
            "captures": [
                {
                    "id": "battle_tap_live_100x50",
                    "route": "battle_tap_live",
                    "viewport": {"width": 100, "height": 50},
                    "dpr": 2.0,
                    "png": str(current),
                    "regions": {
                        "header": {"x": 0, "y": 0, "width": 100, "height": 10},
                        "battlefield": {"x": 0, "y": 10, "width": 100, "height": 30},
                        "command_desk": {"x": 0, "y": 40, "width": 100, "height": 10},
                    },
                }
            ],
        }
        manifest_path = self.root / "manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        output = self.root / "analysis"

        result = fidelity.analyze_manifest(
            manifest_path,
            config,
            output,
            require_reference_comparison=True,
        )

        comparison = result["captures"][0]["comparison"]
        self.assertEqual(comparison["current_sha256"], hashlib.sha256(current.read_bytes()).hexdigest())
        self.assertAlmostEqual(comparison["regions"]["header"]["mae"], 10.0)
        self.assertEqual(comparison["regions"]["header"]["rgb_delta_mean"], [10.0, 10.0, 10.0])
        self.assertAlmostEqual(comparison["self_check"]["regions"]["field"]["mae"], 0.0)
        self.assertAlmostEqual(comparison["self_check"]["regions"]["field"]["edge_iou"], 1.0)
        for name in (
            "fidelity_metrics.json",
            "fidelity_report.md",
            "diff_full.png",
            "diff_header.png",
            "diff_field.png",
            "diff_desk.png",
            "reference_current_side_by_side.png",
        ):
            self.assertTrue((output / name).exists(), name)

    def test_wrong_route_and_shifted_boundary_fail_reference_gates(self):
        reference = self._rgba("reference.png", (100, 50), (100, 100, 100, 255))
        current = self._rgba("current.png", (100, 50), (105, 105, 105, 255))
        config = self._comparison_config(reference)
        manifest = {
            "captures": [
                {
                    "id": "wrong",
                    "route": "battle_audit_tower_14",
                    "viewport": {"width": 100, "height": 50},
                    "png": str(current),
                }
            ]
        }
        manifest_path = self.root / "wrong_manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "reference route"):
            fidelity.analyze_manifest(
                manifest_path,
                config,
                self.root / "wrong_analysis",
                require_reference_comparison=True,
            )

        manifest["captures"][0].update(
            {
                "id": "shifted",
                "route": "battle_tap_live",
                "regions": {
                    "header": {"x": 0, "y": 0, "width": 100, "height": 10},
                    "battlefield": {"x": 0, "y": 10, "width": 100, "height": 32},
                    "command_desk": {"x": 0, "y": 42, "width": 100, "height": 8},
                },
            }
        )
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        result = fidelity.analyze_manifest(
            manifest_path,
            config,
            self.root / "shifted_analysis",
            require_reference_comparison=True,
        )
        self.assertFalse(result["captures"][0]["comparison"]["gates"]["desk_anchor"])

    def test_before_after_roi_and_allowed_change_mask_are_auditable(self):
        before_pixels = np.zeros((10, 10, 4), dtype=np.uint8)
        before_pixels[:, :, 3] = 255
        current_pixels = before_pixels.copy()
        current_pixels[1, 1, :3] = 255
        current_pixels[8, 8, :3] = 255
        allowed_pixels = np.zeros((10, 10), dtype=np.uint8)
        allowed_pixels[1, 1] = 255
        before = self.root / "before.png"
        current = self.root / "current.png"
        allowed = self.root / "allowed.png"
        Image.fromarray(before_pixels).save(before)
        Image.fromarray(current_pixels).save(current)
        Image.fromarray(allowed_pixels).save(allowed)
        manifest = {
            "captures": [
                {
                    "id": "production_before_after",
                    "route": "battle_audit_tower_14",
                    "viewport": {"width": 10, "height": 10},
                    "png": str(current),
                    "baseline": {
                        "png": str(before),
                        "sha256": hashlib.sha256(before.read_bytes()).hexdigest(),
                        "allowed_change_mask": str(allowed),
                        "rois": {
                            "top_left": {"x": 0, "y": 0, "width": 5, "height": 5},
                            "bottom_right": {"x": 5, "y": 5, "width": 5, "height": 5},
                        },
                    },
                }
            ]
        }
        manifest_path = self.root / "manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

        result = fidelity.analyze_manifest(
            manifest_path,
            self.config,
            self.root / "analysis",
            require_reference_comparison=False,
        )

        baseline = result["captures"][0]["baseline_comparison"]
        self.assertEqual(baseline["changed_pixels_total"], 2)
        self.assertEqual(baseline["changed_pixels_allowed"], 1)
        self.assertEqual(baseline["changed_pixels_unexpected"], 1)
        self.assertEqual(baseline["rois"]["top_left"]["changed_pixels"], 1)
        self.assertEqual(baseline["rois"]["bottom_right"]["unexpected_pixels"], 1)
        for name in (
            "baseline_diff_full.png",
            "baseline_unexpected_diff.png",
            "baseline_current_side_by_side.png",
        ):
            self.assertTrue(
                (self.root / "analysis" / "comparisons" / "production_before_after" / name).exists(),
                name,
            )


class WorkTreeProvenanceTest(unittest.TestCase):
    """`commit` alone cannot prove which code produced a capture.

    A capture run usually happens on an edited-but-uncommitted tree, so
    `git rev-parse HEAD` names the *previous* state. These tests pin the
    working-tree tree id instead, and guard that computing it never
    disturbs the repository index the user is working in.
    """

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp.name) / "repo"
        self.repo.mkdir()
        self._git("init", "-q")
        self._git("config", "user.email", "test@example.com")
        self._git("config", "user.name", "test")
        (self.repo / ".gitignore").write_text("build/\n", encoding="utf-8")
        (self.repo / "tracked.txt").write_text("v1\n", encoding="utf-8")
        self._git("add", "-A")
        self._git("commit", "-q", "-m", "init")

    def tearDown(self):
        self.temp.cleanup()

    def _git(self, *args):
        return subprocess.run(
            ("git", "-C", str(self.repo)) + args,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()

    def test_clean_tree_matches_head_and_is_not_dirty(self):
        state = fidelity.work_tree_state(self.repo)
        self.assertEqual(state["tree"], self._git("rev-parse", "HEAD^{tree}"))
        self.assertEqual(state["head_tree"], state["tree"])
        self.assertFalse(state["dirty"])

    def test_uncommitted_edit_changes_tree_and_sets_dirty(self):
        clean = fidelity.work_tree_state(self.repo)
        (self.repo / "tracked.txt").write_text("v2\n", encoding="utf-8")
        dirty = fidelity.work_tree_state(self.repo)
        self.assertNotEqual(dirty["tree"], clean["tree"])
        self.assertEqual(dirty["head_tree"], clean["head_tree"])
        self.assertTrue(dirty["dirty"])

    def test_untracked_file_counts_but_gitignored_output_does_not(self):
        clean = fidelity.work_tree_state(self.repo)
        build_png = self.repo / "build" / "visual_acceptance" / "shot.png"
        build_png.parent.mkdir(parents=True)
        build_png.write_bytes(b"not-code")
        self.assertEqual(
            fidelity.work_tree_state(self.repo)["tree"],
            clean["tree"],
            "captures live under gitignored build/ and must not move the tree id",
        )

        (self.repo / "new_probe.dart").write_text("x", encoding="utf-8")
        state = fidelity.work_tree_state(self.repo)
        self.assertNotEqual(state["tree"], clean["tree"])
        self.assertTrue(state["dirty"])

    def test_computing_the_tree_never_touches_the_real_index(self):
        (self.repo / "tracked.txt").write_text("v2\n", encoding="utf-8")
        (self.repo / "new_probe.dart").write_text("x", encoding="utf-8")
        before = self._git("status", "--porcelain")
        fidelity.work_tree_state(self.repo)
        self.assertEqual(self._git("status", "--porcelain"), before)
        self.assertEqual(self._git("diff", "--cached", "--name-only"), "")

    def test_build_manifest_records_tree_provenance(self):
        capture_root = self.repo / "captures"
        shot_dir = capture_root / "battle_tap_live" / "100x50"
        shot_dir.mkdir(parents=True)
        Image.new("RGBA", (200, 100), (10, 10, 10, 255)).save(
            shot_dir / "battle_tap_live.png"
        )

        manifest = fidelity.build_manifest(
            capture_root, "commit-sha", tree="tree-sha", dirty=True
        )
        self.assertEqual(manifest["schema_version"], 3)
        self.assertEqual(manifest["commit"], "commit-sha")
        self.assertEqual(manifest["tree"], "tree-sha")
        self.assertTrue(manifest["dirty"])

    def test_build_manifest_leaves_tree_unknown_rather_than_claiming_clean(self):
        capture_root = self.repo / "captures"
        shot_dir = capture_root / "battle_tap_live" / "100x50"
        shot_dir.mkdir(parents=True)
        Image.new("RGBA", (200, 100), (10, 10, 10, 255)).save(
            shot_dir / "battle_tap_live.png"
        )

        manifest = fidelity.build_manifest(capture_root, "commit-sha")
        self.assertIsNone(manifest["tree"])
        self.assertIsNone(manifest["dirty"])


if __name__ == "__main__":
    unittest.main()
