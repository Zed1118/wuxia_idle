#!/usr/bin/env python3
"""Fixed-fixture regression tests for tools/doc_link_scan.py."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest import mock

import doc_link_scan


class DocLinkScanFixtureTest(unittest.TestCase):
    def scan_fixture(
        self,
        content: str,
        *,
        source: str = "docs/source.md",
        tracked_targets: set[str] | None = None,
        ignored_targets: set[str] | None = None,
    ) -> dict:
        tracked = {source, *(tracked_targets or set())}
        ignored = ignored_targets or set()

        with tempfile.TemporaryDirectory() as temp_dir:
            repo_root = Path(temp_dir)
            source_path = repo_root / source
            source_path.parent.mkdir(parents=True, exist_ok=True)
            source_path.write_text(content, encoding="utf-8")

            with (
                mock.patch.object(doc_link_scan, "REPO_ROOT", repo_root),
                mock.patch.object(
                    doc_link_scan, "git_ls_files", return_value=sorted(tracked)
                ),
                mock.patch.object(
                    doc_link_scan,
                    "git_check_ignore",
                    side_effect=lambda paths: set(paths) & ignored,
                ),
            ):
                return doc_link_scan.scan()

    def assert_alive_reference(self, result: dict) -> None:
        self.assertEqual(result["refs_total"], 1)
        self.assertEqual(result["alive"], 1)
        self.assertEqual(result["dead"], 0)
        self.assertEqual(result["ignored"], 0)
        self.assertEqual(result["skipped"], 0)

    def assert_dead_reference(self, result: dict, target: str) -> None:
        self.assertEqual(result["refs_total"], 1)
        self.assertEqual(result["alive"], 0)
        self.assertEqual(result["dead"], 1)
        self.assertEqual(result["ignored"], 0)
        self.assertEqual(result["skipped"], 0)
        self.assertEqual([row["target"] for row in result["rows"]], [target])

    def test_backtick_existing_path_is_alive_reference(self) -> None:
        result = self.scan_fixture(
            "`lib/main.dart`", tracked_targets={"lib/main.dart"}
        )
        self.assert_alive_reference(result)

    def test_backtick_missing_path_is_dead_reference(self) -> None:
        result = self.scan_fixture("`lib/nope.dart`")
        self.assert_dead_reference(result, "lib/nope.dart")

    def test_markdown_existing_link_is_alive_reference(self) -> None:
        result = self.scan_fixture(
            "[说明](docs/GDD.md)", tracked_targets={"docs/GDD.md"}
        )
        self.assert_alive_reference(result)

    def test_markdown_missing_link_is_dead_reference(self) -> None:
        result = self.scan_fixture("[x](docs/nope.md)")
        self.assert_dead_reference(result, "docs/nope.md")

    def test_markdown_image_is_reference(self) -> None:
        result = self.scan_fixture(
            "![图](assets/x.png)", tracked_targets={"assets/x.png"}
        )
        self.assert_alive_reference(result)

    def test_fenced_backtick_path_is_not_collected(self) -> None:
        content = "```text\n`lib/a.dart`\n```"
        result = self.scan_fixture(content, tracked_targets={"lib/a.dart"})
        self.assertEqual(result["refs_total"], 0)
        self.assertEqual(result["alive"], 0)
        self.assertEqual(result["dead"], 0)
        self.assertEqual(result["ignored"], 0)
        self.assertEqual(result["skipped"], 0)

    def test_gitignored_target_is_ignored_not_dead(self) -> None:
        result = self.scan_fixture(
            "`build/foo.txt`", ignored_targets={"build/foo.txt"}
        )
        self.assertEqual(result["refs_total"], 1)
        self.assertEqual(result["alive"], 0)
        self.assertEqual(result["dead"], 0)
        self.assertEqual(result["ignored"], 1)
        self.assertEqual(result["skipped"], 0)
        self.assertEqual(
            [row["target"] for row in result["ignored_rows"]],
            ["build/foo.txt"],
        )

    def test_parent_relative_path_resolves_from_source_directory(self) -> None:
        result = self.scan_fixture(
            "`../tools/x.py`", tracked_targets={"tools/x.py"}
        )
        self.assert_alive_reference(result)

    def test_backtick_bracket_template_is_skipped_as_template(self) -> None:
        result = self.scan_fixture("`docs/[章节]/x.md`")
        self.assertEqual(result["refs_total"], 0)
        self.assertEqual(result["alive"], 0)
        self.assertEqual(result["dead"], 0)
        self.assertEqual(result["ignored"], 0)
        self.assertEqual(result["skipped"], 1)
        self.assertEqual(result["skipped_reasons"], {"template[]": 1})

    def test_markdown_link_uses_target_not_path_like_text(self) -> None:
        result = self.scan_fixture(
            "[见 lib/a.dart](docs/b.md)", tracked_targets={"docs/b.md"}
        )
        self.assert_alive_reference(result)


if __name__ == "__main__":
    unittest.main()
