#!/usr/bin/env python3
"""Real Git regression tests for task registry evidence selection.

Run from the repository root:
    python3 -B tools/audit/test_task_registry_triage.py

Only ROOT/REGISTRY and reporting refs are replaced. Git operations are real;
each test creates an independent temporary repository and clears both caches.
Requires the same PyYAML dependency as task_registry_triage.py.
"""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock

import yaml

import task_registry_triage as triage


class TaskRegistryTriageGitFixtureTest(unittest.TestCase):
    def setUp(self):
        # Do not inherit a caller's Git worktree, index, identity or hooks.
        environment = {
            key: value for key, value in os.environ.items()
            if not key.startswith("GIT_")
        }
        environment.update({
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_TERMINAL_PROMPT": "0",
        })
        env_patch = mock.patch.dict(os.environ, environment, clear=True)
        env_patch.start()
        self.addCleanup(env_patch.stop)
        directory = tempfile.TemporaryDirectory(prefix="task-registry-triage-")
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name).resolve()
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.name", "registry fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "core.hooksPath", os.devnull)
        self.git("commit", "-q", "--allow-empty", "-m", "neutral base")
        self.base = self.git("rev-parse", "HEAD")

        self.git("switch", "-q", "-c", "source")
        (self.root / "patch.txt").write_text("patch a\n", encoding="utf-8")
        self.git("add", "patch.txt")
        self.git("commit", "-q", "-m", "neutral source a")
        self.source_a = self.git("rev-parse", "HEAD")
        (self.root / "second.txt").write_text("patch b\n", encoding="utf-8")
        self.git("add", "second.txt")
        self.git("commit", "-q", "-m", "neutral source b")
        self.source_b = self.git("rev-parse", "HEAD")

        self.git("switch", "-q", "main")
        self.git("commit", "-q", "--allow-empty", "-m", "neutral target context")
        self.context = self.git("rev-parse", "HEAD")
        self.git("cherry-pick", self.source_a)
        self.target = self.git("rev-parse", "HEAD")

        self.git("switch", "-q", "-c", "merge-only", self.base)
        self.git("merge", "--no-ff", "-m", "neutral merge", self.source_a)
        self.merge = self.git("rev-parse", "HEAD")
        self.git("switch", "-q", "main")

        # Prove this fixture contains different SHAs with the same patch, a
        # still-unintegrated patch and a unique merge; no historical refs.
        self.assertNotEqual(self.source_a, self.target)
        self.assertEqual(
            self.git("cherry", self.target, self.source_a),
            f"- {self.source_a}",
        )
        self.assertEqual(
            self.git("cherry", self.target, self.source_b).splitlines(),
            [f"- {self.source_a}", f"+ {self.source_b}"],
        )
        self.assertEqual(
            self.git("rev-list", "--count", "--merges",
                     f"{self.target}..{self.merge}"),
            "1",
        )
        for name, value in (
            ("ROOT", self.root), ("REGISTRY", "registry.yaml"),
            ("BASE", self.base), ("CHAIN", "main"),
        ):
            patcher = mock.patch.object(triage, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)
        self.clear_caches()
        self.addCleanup(self.clear_caches)

    @staticmethod
    def clear_caches():
        triage.resolve.cache_clear()
        triage.ancestor.cache_clear()

    def git(self, *args):
        return subprocess.run(
            ["git", *args], cwd=self.root, check=True,
            text=True, capture_output=True,
        ).stdout.strip()

    def evaluate(self, **fields):
        task = {
            "id": "CASE-UNIQUE-ID", "milestone": "M7",
            "status": "ready_reviewed", "branch": "none", **fields,
        }
        (self.root / "registry.yaml").write_text(
            yaml.safe_dump({"tasks": [task]}), encoding="utf-8",
        )
        self.clear_caches()
        result = triage.run(self.target)
        self.assertEqual(result["ready_reviewed_count"], 1)
        self.assertEqual(len(result["rows"]), 1)
        return result["rows"][0]

    def assert_integrated(self, row, method=None):
        self.assertEqual(row["judgement"], "已集成", row)
        if method is not None:
            self.assertEqual(row["method"], method, row)

    def assert_unknown(self, row, method=None):
        self.assertEqual(row["judgement"], "未能判定", row)
        if method is not None:
            self.assertEqual(row["method"], method, row)

    def assert_invalid(self, row, field):
        self.assertIn(
            {"field": field, "value": "not-a-valid-commit"},
            row["invalid_commit_clues"], row,
        )

    def test_top_singular_ancestor(self):
        self.assert_integrated(
            self.evaluate(integration_commit=self.target), "全部登记集成提交祖先",
        )

    def test_top_plural_all_ancestors(self):
        self.assert_integrated(self.evaluate(
            integration_commits=[self.target, self.context],
        ))

    def test_top_plural_partial_stays_unknown(self):
        self.assert_unknown(self.evaluate(
            integration_commits=[self.target, self.source_b],
        ))

    def test_top_invalid_retained(self):
        row = self.evaluate(
            integration_commits=[self.target, "not-a-valid-commit"],
        )
        self.assert_unknown(row)
        self.assert_invalid(row, "integration_commits")

    def test_nested_singular_ancestor(self):
        row = self.evaluate(evidence={"integration_commit": self.target})
        self.assert_integrated(row, "全部登记集成提交祖先")
        self.assertEqual(row["clues"]["evidence.integration_commit"], self.target)
        self.assertEqual(row["evidence"][0]["clue"], "evidence.integration_commit")

    def test_nested_plural_all_ancestors(self):
        self.assert_integrated(self.evaluate(evidence={
            "integration_commits": [self.target, self.context],
        }))

    def test_ch8_content_and_governance_all_ancestors(self):
        row = self.evaluate(evidence={
            "integration_content_commit": self.target,
            "integration_governance_commit": self.context,
        })
        self.assert_integrated(row, "全部登记集成提交祖先")
        self.assertEqual(
            {(entry["clue"], entry["sha"]) for entry in row["evidence"]},
            {("evidence.integration_content_commit", self.target),
             ("evidence.integration_governance_commit", self.context)},
        )

    def test_ch8_content_only_does_not_prove_governance(self):
        self.assert_unknown(self.evaluate(evidence={
            "integration_content_commit": self.target,
            "integration_governance_commit": self.source_b,
        }))

    def test_nested_plural_partial_stays_unknown(self):
        self.assert_unknown(self.evaluate(evidence={
            "integration_commits": [self.target, self.source_b],
        }))

    def test_top_and_nested_union_must_all_be_integrated(self):
        self.assert_unknown(self.evaluate(
            integration_commit=self.target,
            evidence={"integration_commits": [self.source_b]},
        ))

    def test_nested_invalid_retained(self):
        row = self.evaluate(evidence={
            "integration_commits": [self.target, "not-a-valid-commit"],
        })
        self.assert_unknown(row)
        self.assert_invalid(row, "evidence.integration_commits")

    def test_valid_top_cannot_hide_invalid_nested(self):
        row = self.evaluate(
            integration_commit=self.target,
            evidence={"integration_commit": "not-a-valid-commit"},
        )
        self.assert_unknown(row)
        self.assert_invalid(row, "evidence.integration_commit")

    def test_same_sha_paths_retained_and_evidence_deduplicated(self):
        row = self.evaluate(
            integration_commit=self.target,
            evidence={"integration_commit": self.target},
        )
        self.assert_integrated(row)
        self.assertEqual(row["clues"]["integration_commit"], self.target)
        self.assertIn("evidence.integration_commit", row["clues"])
        self.assertEqual(row["clues"]["evidence.integration_commit"], self.target)
        self.assertEqual([item["sha"] for item in row["evidence"]], [self.target])

    def test_source_commits_never_completion_proof(self):
        ignored = dict.fromkeys(
            ("base_commit", "governance_source_commit", "implementation_commit"),
            self.target,
        )
        self.assert_unknown(self.evaluate(**ignored, evidence=ignored))

    def test_arbitrary_commit_labels_not_completion_proof(self):
        self.assert_unknown(self.evaluate(evidence=dict.fromkeys(
            ("reviewer_implementation_commit", "exact_sha_ci_head",
             "baseline_exact_sha_ci_head"),
            self.target,
        )))

    def test_no_arbitrary_recursive_discovery(self):
        self.assert_unknown(self.evaluate(evidence={
            "notes": {"integration_commit": self.target},
        }))

    def test_endpoint_priority_preserved(self):
        row = self.evaluate(
            reviewed_candidate_commit=self.context, tip_commit=self.target,
            evidence={"integration_commits": [self.source_b]},
        )
        self.assert_integrated(row, "完成端点祖先")
        self.assertEqual(row["evidence"][0]["clue"], "reviewed_candidate_commit")
        self.assertEqual(row["evidence"][0]["sha"], self.context)

    def test_endpoint_proof_keeps_invalid_evidence_diagnostic(self):
        row = self.evaluate(
            tip_commit=self.target,
            evidence={"integration_commit": "not-a-valid-commit"},
        )
        self.assert_integrated(row, "完成端点祖先")
        self.assert_invalid(row, "evidence.integration_commit")

    def test_endpoint_whole_patch_id_equivalence_preserved(self):
        row = self.evaluate(tip_commit=self.source_a)
        self.assert_integrated(row, "全补丁等价")
        cherry = next(item for item in row["evidence"] if item["kind"] == "cherry")
        self.assertEqual(cherry["output"], [f"- {self.source_a}"])
        self.assertEqual(cherry["unique_merge_count"], 0)

    def test_endpoint_partial_patches_not_whole_equivalence(self):
        self.assert_unknown(self.evaluate(tip_commit=self.source_b))

    def test_unique_merge_prevents_patch_id_acceptance(self):
        self.assert_unknown(self.evaluate(tip_commit=self.merge))

    def test_pending_correction_veto_preserved(self):
        self.assert_unknown(self.evaluate(
            tip_commit=self.target, correction_commit=self.source_b,
        ), "后续修正未证实")

    def test_patch_id_correction_still_supported(self):
        row = self.evaluate(
            tip_commit=self.target, correction_commit=self.source_a,
        )
        self.assert_integrated(row, "完成端点祖先")
        correction = next(
            item for item in row["evidence"]
            if item.get("clue") == "correction_commit"
        )
        self.assertEqual(correction["kind"], "cherry")
        self.assertEqual(correction["output"], [f"- {self.source_a}"])
        self.assertEqual(correction["unique_merge_count"], 0)

    def test_invalid_correction_veto_and_diagnosis_preserved(self):
        row = self.evaluate(
            tip_commit=self.target, correction_commit="not-a-valid-commit",
        )
        self.assert_unknown(row, "后续修正未证实")
        self.assert_invalid(row, "correction_commit")


if __name__ == "__main__":
    unittest.main(verbosity=2)
