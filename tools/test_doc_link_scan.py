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
        extra_sources: dict[str, str] | None = None,
    ) -> dict:
        tracked = {source, *(tracked_targets or set()), *(extra_sources or {})}
        ignored = ignored_targets or set()

        with tempfile.TemporaryDirectory() as temp_dir:
            repo_root = Path(temp_dir)
            source_path = repo_root / source
            source_path.parent.mkdir(parents=True, exist_ok=True)
            source_path.write_text(content, encoding="utf-8")
            for rel, text in (extra_sources or {}).items():
                extra_path = repo_root / rel
                extra_path.parent.mkdir(parents=True, exist_ok=True)
                extra_path.write_text(text, encoding="utf-8")

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
        self.assertEqual(result["archival"], 0)
        self.assertEqual(result["skipped"], 0)

    def assert_dead_reference(self, result: dict, target: str) -> None:
        self.assertEqual(result["refs_total"], 1)
        self.assertEqual(result["alive"], 0)
        self.assertEqual(result["dead"], 1)
        self.assertEqual(result["ignored"], 0)
        self.assertEqual(result["archival"], 0)
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

    # -- 归档类单列(ARCHIVAL_DIRS) ----------------------------------------

    def test_dead_reference_in_archival_doc_is_archival_not_dead(self) -> None:
        """归档目录(docs/handoff)下文档里的失效引用 → archival,不计 dead。"""
        result = self.scan_fixture(
            "`lib/gone.dart`", source="docs/handoff/h1.md"
        )
        self.assertEqual(result["refs_total"], 1)
        self.assertEqual(result["alive"], 0)
        self.assertEqual(result["ignored"], 0)
        self.assertEqual(result["dead"], 0)
        self.assertEqual(result["archival"], 1)
        self.assertEqual(
            [row["target"] for row in result["archival_rows"]],
            ["lib/gone.dart"],
        )

    def test_dead_reference_pointing_at_archival_dir_stays_dead(self) -> None:
        """判据是「引用写在哪个文件里」,不是「引用指向哪个路径」:
        非归档文档里指向归档目录的死引用仍归 dead。"""
        result = self.scan_fixture(
            "`docs/handoff/gone.md`", source="docs/source.md"
        )
        self.assertEqual(result["refs_total"], 1)
        self.assertEqual(result["alive"], 0)
        self.assertEqual(result["ignored"], 0)
        self.assertEqual(result["dead"], 1)
        self.assertEqual(result["archival"], 0)
        self.assertEqual(
            [row["target"] for row in result["rows"]],
            ["docs/handoff/gone.md"],
        )

    def test_alive_reference_in_archival_doc_stays_alive(self) -> None:
        """归档类只收失效引用;归档文档里的存活引用不受影响。"""
        result = self.scan_fixture(
            "`lib/main.dart`", source="docs/handoff/h1.md",
            tracked_targets={"lib/main.dart"},
        )
        self.assert_alive_reference(result)

    def test_archival_split_conserves_dead_total(self) -> None:
        """守恒:同一份 fixture 下 dead + archival == 失效引用总数,
        且 refs_total == alive + dead + ignored + archival。"""
        result = self.scan_fixture(
            "`lib/gone_a.dart`",
            extra_sources={"docs/handoff/h1.md": "`lib/gone_b.dart`"},
        )
        self.assertEqual(result["refs_total"], 2)
        self.assertEqual(result["alive"], 0)
        self.assertEqual(result["ignored"], 0)
        self.assertEqual(result["dead"], 1)
        self.assertEqual(result["archival"], 1)
        self.assertEqual(result["dead"] + result["archival"], 2)
        self.assertEqual(
            result["refs_total"],
            result["alive"] + result["dead"]
            + result["ignored"] + result["archival"],
        )
        self.assertEqual(
            [row["target"] for row in result["rows"]], ["lib/gone_a.dart"]
        )
        self.assertEqual(
            [row["target"] for row in result["archival_rows"]], ["lib/gone_b.dart"]
        )


    # -- Bug C 文内引用截断(2026-08-18,与 Bug B 冒号截断同体例) ----------

    def test_space_section_suffix_stripped_to_alive_base(self) -> None:
        """已知扩展名后空格段名(`numbers.yaml jianghu`)截断至基底;
        基底 tracked → alive(剥而不验,与 #锚点口径一致)。"""
        result = self.scan_fixture(
            "`data/numbers.yaml jianghu`", tracked_targets={"data/numbers.yaml"}
        )
        self.assert_alive_reference(result)

    def test_section_marker_suffix_stripped_to_alive_base(self) -> None:
        """已知扩展名后 §章节(`backlog.md §十二`)同样截断至基底。"""
        result = self.scan_fixture(
            "`docs/spec/backlog.md §十二`",
            tracked_targets={"docs/spec/backlog.md"},
        )
        self.assert_alive_reference(result)

    def test_space_suffix_missing_base_stays_dead(self) -> None:
        """截断后基底不存在仍判死:截断不改变存在性语义,只去段名噪声。"""
        result = self.scan_fixture("`data/gone.yaml 段落`")
        self.assert_dead_reference(result, "data/gone.yaml")

    # -- 归档扩类(sessions/dispatch/superpowers/audit,2026-08-18 重拍) ---

    def test_dead_reference_in_extended_archival_dirs_is_archival(self) -> None:
        """四个历史目录与 handoff 同待遇:文内失效引用归 archival 不计 dead。"""
        for source in (
            "docs/sessions/s1.md",
            "docs/dispatch/d1.md",
            "docs/superpowers/plans/p1.md",
            "docs/audit/a1.md",
        ):
            with self.subTest(source=source):
                result = self.scan_fixture("`lib/gone.dart`", source=source)
                self.assertEqual(result["dead"], 0)
                self.assertEqual(result["archival"], 1)

    # -- EXCLUDE_FILES:audio 指南计划素材清单(与 PATH_MIGRATION_MAP 同构) --

    def test_audio_guide_is_excluded_from_scan(self) -> None:
        """`docs/audio_asset_generation_guide.md` 主体是未生成素材的计划清单,
        扫它必产计划性死链(同 PATH_MIGRATION_MAP 先例)→ 整文件排除。"""
        result = self.scan_fixture(
            "`assets/audio/sfx/never_generated.mp3`",
            source="docs/audio_asset_generation_guide.md",
        )
        self.assertEqual(result["scanned_files"], 0)
        self.assertEqual(result["refs_total"], 0)


if __name__ == "__main__":
    unittest.main()
