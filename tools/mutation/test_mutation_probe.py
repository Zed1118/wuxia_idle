import tempfile
import sys
import time
import unittest
from pathlib import Path

import mutation_probe


class MutationGenerationTest(unittest.TestCase):
    def test_generates_all_four_operator_classes_without_strings_or_comments(self):
        source = """
bool decide(int n) {
  // if (n > 999) return false;
  final label = 'n == 8';
  if (n > 1 && true) return n == 2;
  while (n >= 3) return false;
  return n != 4;
}
"""
        mutants = mutation_probe.generate_mutants("lib/sample.dart", source)
        classes = {mutant.operator_class for mutant in mutants}
        self.assertEqual(
            classes,
            {
                "comparison_flip",
                "boolean_literal",
                "numeric_literal",
                "condition_short_circuit",
            },
        )
        originals = {mutant.original for mutant in mutants}
        self.assertNotIn("999", originals)
        self.assertNotIn("8", originals)

    def test_numeric_operator_has_zero_and_increment_variants(self):
        mutants = mutation_probe.generate_mutants("lib/sample.dart", "final n = 7;\n")
        replacements = {mutant.replacement for mutant in mutants}
        self.assertEqual(replacements, {"0", "8"})

    def test_condition_operator_replaces_entire_nested_condition(self):
        source = "if ((a > 0) && ready()) { return; }\n"
        mutants = mutation_probe.generate_mutants("lib/sample.dart", source)
        conditions = [
            mutant for mutant in mutants if mutant.operator_class == "condition_short_circuit"
        ]
        self.assertEqual({item.replacement for item in conditions}, {"true", "false"})
        self.assertTrue(all(item.original == "(a > 0) && ready()" for item in conditions))

    def test_generic_type_closer_is_not_a_comparison_candidate(self):
        source = "Map<String, double> values = {};\nif (value > 0) return;\n"
        mutants = mutation_probe.generate_mutants("lib/sample.dart", source)
        comparisons = [
            mutant for mutant in mutants if mutant.operator_class == "comparison_flip"
        ]
        self.assertEqual(len(comparisons), 1)
        self.assertEqual(comparisons[0].original, ">")
        self.assertEqual(comparisons[0].line, 2)


class DirectedTestMappingTest(unittest.TestCase):
    def test_reverse_import_closure_and_source_reference_are_reproducible(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "lib").mkdir()
            (root / "test").mkdir()
            (root / "lib" / "target.dart").write_text("bool value = true;\n")
            (root / "lib" / "consumer.dart").write_text(
                "import 'target.dart';\n", encoding="utf-8"
            )
            (root / "test" / "consumer_test.dart").write_text(
                "import 'package:demo/consumer.dart';\n", encoding="utf-8"
            )
            (root / "test" / "source_test.dart").write_text(
                "const path = 'lib/target.dart';\n", encoding="utf-8"
            )
            (root / "test" / "unrelated_test.dart").write_text(
                "void main() {}\n", encoding="utf-8"
            )
            selected = mutation_probe.derive_tests(root, "lib/target.dart", "demo")
            self.assertEqual(
                selected,
                ["test/consumer_test.dart", "test/source_test.dart"],
            )


class SamplingTest(unittest.TestCase):
    def test_sampling_is_stable_and_covers_every_operator_class(self):
        source = """
bool f(int n) {
  if (n > 1 && true) return n == 2;
  if (n >= 3 && false) return n != 4;
  return true;
}
"""
        mutants = mutation_probe.generate_mutants("lib/sample.dart", source)
        first = mutation_probe.select_mutants(mutants, 2)
        second = mutation_probe.select_mutants(mutants, 2)
        self.assertEqual(first, second)
        selected_classes = {
            mutant.operator_class for mutant in mutants if mutant.mutant_id in first
        }
        self.assertEqual(
            selected_classes,
            {
                "comparison_flip",
                "boolean_literal",
                "numeric_literal",
                "condition_short_circuit",
            },
        )


class ClassificationTest(unittest.TestCase):
    def test_test_error_never_counts_as_killed(self):
        result = {
            "timed_out": False,
            "missing_suites": [],
            "failures": [
                {"name": "crashes", "suite": "test/a_test.dart", "result": "error"}
            ],
            "compile_error_detected": False,
            "error_count": 1,
            "assertion_failure_count": 0,
            "return_code": 1,
        }
        self.assertEqual(
            mutation_probe.classify_test_result(result, {"test/a_test.dart"}),
            "compile_or_crash",
        )

    def test_assertion_from_expected_suite_counts_as_killed(self):
        result = {
            "timed_out": False,
            "missing_suites": [],
            "failures": [
                {"name": "guards behavior", "suite": "test/a_test.dart", "result": "failure"}
            ],
            "compile_error_detected": False,
            "error_count": 0,
            "assertion_failure_count": 1,
            "return_code": 1,
        }
        self.assertEqual(
            mutation_probe.classify_test_result(result, {"test/a_test.dart"}),
            "killed",
        )

    def test_assertion_from_unexpected_suite_is_separate(self):
        result = {
            "timed_out": False,
            "missing_suites": [],
            "failures": [
                {"name": "unrelated", "suite": "test/b_test.dart", "result": "failure"}
            ],
            "compile_error_detected": False,
            "error_count": 0,
            "assertion_failure_count": 1,
            "return_code": 1,
        }
        self.assertEqual(
            mutation_probe.classify_test_result(result, {"test/a_test.dart"}),
            "killed_by_non_target",
        )


class ProcessTimeoutTest(unittest.TestCase):
    @unittest.skipUnless(mutation_probe.os.name == "posix", "POSIX process-group behavior")
    def test_timeout_terminates_child_process_holding_output_pipes(self):
        command = [
            sys.executable,
            "-c",
            (
                "import subprocess, sys, time; "
                "subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)']); "
                "print('ready', flush=True); time.sleep(60)"
            ),
        ]
        started = time.monotonic()
        stdout, _stderr, return_code, timed_out = mutation_probe._run_command(
            command, Path.cwd(), 1
        )
        elapsed = time.monotonic() - started
        self.assertTrue(timed_out)
        self.assertEqual(return_code, 124)
        self.assertIn("ready", stdout)
        self.assertLess(elapsed, 7)


if __name__ == "__main__":
    unittest.main()
