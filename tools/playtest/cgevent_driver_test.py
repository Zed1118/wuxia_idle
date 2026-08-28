#!/usr/bin/env python3
"""Behavior tests for the standalone CGEvent scenario driver."""

import json
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(__file__).with_name("cgevent_driver.swift")


class CgEventDriverTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.scratch = tempfile.TemporaryDirectory()
        cls.binary = Path(cls.scratch.name) / "cgevent_driver"
        subprocess.run(
            ["swiftc", str(SOURCE), "-o", str(cls.binary)],
            check=True,
            cwd=ROOT,
        )

    @classmethod
    def tearDownClass(cls) -> None:
        cls.scratch.cleanup()

    def _scenario(self, actions: list[dict]) -> Path:
        path = Path(self.scratch.name) / f"scenario_{len(list(Path(self.scratch.name).glob('scenario_*')))}.json"
        path.write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "id": "driver_test",
                    "recording_max_seconds": 30,
                    "actions": actions,
                }
            ),
            encoding="utf-8",
        )
        return path

    def test_validate_accepts_all_supported_action_types(self) -> None:
        scenario = self._scenario(
            [
                {"id": "click", "type": "click", "x": 0.25, "y": 0.75},
                {"id": "key", "type": "key", "key": "w", "hold_ms": 120},
                {"id": "scroll", "type": "scroll", "delta_y": -8},
                {"id": "wait", "type": "wait", "duration_ms": 10},
                {"id": "mark", "type": "checkpoint", "label": "entry"},
            ]
        )
        result = subprocess.run(
            [str(self.binary), "validate", "--scenario", str(scenario)],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("VALID scenario=driver_test actions=5", result.stdout)

    def test_validate_rejects_degenerate_click_coordinate(self) -> None:
        scenario = self._scenario(
            [{"id": "bad", "type": "click", "x": 1.01, "y": 0.5}]
        )
        result = subprocess.run(
            [str(self.binary), "validate", "--scenario", str(scenario)],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires x/y in 0...1", result.stderr)

    def test_source_refreshes_window_inside_action_loop(self) -> None:
        source = SOURCE.read_text(encoding="utf-8")
        loop = source.index("for (index, action) in scenario.actions.enumerated()")
        refresh = source.index("let window = targetWindow", loop)
        dispatch = source.index("switch action.type", refresh)
        self.assertLess(loop, refresh)
        self.assertLess(refresh, dispatch)
        self.assertNotIn("cachedWindow", source)


if __name__ == "__main__":
    unittest.main()
