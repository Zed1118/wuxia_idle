#!/usr/bin/env python3
"""Small, dependency-free mutation probe for Dart source files.

The probe deliberately runs one mutant at a time, checks that every derived
test suite was loaded by Flutter's JSON reporter, and restores the exact source
bytes after every run.  It is a measurement tool, not a source rewriter.
"""

from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import os
import re
import signal
import subprocess
import sys
import tempfile
import time
from collections import defaultdict, deque
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple
from urllib.parse import unquote, urlparse


DEFAULT_TARGETS = (
    "lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart",
    "lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart",
)


@dataclasses.dataclass(frozen=True)
class Mutant:
    target: str
    start: int
    end: int
    line: int
    column: int
    operator_class: str
    operator: str
    variant_family: str
    original: str
    replacement: str

    @property
    def mutant_id(self) -> str:
        payload = (
            f"{self.target}\0{self.start}\0{self.end}\0{self.operator}"
            f"\0{self.replacement}"
        )
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:16]

    def as_dict(self) -> Dict[str, object]:
        value = dataclasses.asdict(self)
        value["mutant_id"] = self.mutant_id
        return value


def _code_mask(source: str) -> str:
    """Mask Dart comments and string literals while preserving offsets."""

    chars = list(source)
    masked = list(source)
    length = len(chars)
    index = 0
    block_depth = 0

    def hide(start: int, end: int) -> None:
        for offset in range(start, end):
            if masked[offset] not in "\r\n":
                masked[offset] = " "

    while index < length:
        if block_depth:
            if source.startswith("/*", index):
                hide(index, index + 2)
                block_depth += 1
                index += 2
            elif source.startswith("*/", index):
                hide(index, index + 2)
                block_depth -= 1
                index += 2
            else:
                hide(index, index + 1)
                index += 1
            continue

        if source.startswith("//", index):
            end = source.find("\n", index)
            if end == -1:
                end = length
            hide(index, end)
            index = end
            continue

        if source.startswith("/*", index):
            hide(index, index + 2)
            block_depth = 1
            index += 2
            continue

        raw_prefix = (
            chars[index] in "rR"
            and index + 1 < length
            and chars[index + 1] in "'\""
            and (index == 0 or not (chars[index - 1].isalnum() or chars[index - 1] == "_"))
        )
        quote_index = index + 1 if raw_prefix else index
        if chars[quote_index] not in "'\"":
            index += 1
            continue

        quote = chars[quote_index]
        triple = source.startswith(quote * 3, quote_index)
        delimiter = quote * (3 if triple else 1)
        cursor = quote_index + len(delimiter)
        while cursor < length:
            if not raw_prefix and chars[cursor] == "\\":
                cursor += 2
                continue
            if source.startswith(delimiter, cursor):
                cursor += len(delimiter)
                break
            cursor += 1
        hide(index, min(cursor, length))
        index = min(cursor, length)

    return "".join(masked)


def _line_column(source: str, offset: int) -> Tuple[int, int]:
    line = source.count("\n", 0, offset) + 1
    previous_newline = source.rfind("\n", 0, offset)
    column = offset + 1 if previous_newline == -1 else offset - previous_newline
    return line, column


def _make_mutant(
    target: str,
    source: str,
    start: int,
    end: int,
    operator_class: str,
    operator: str,
    variant_family: str,
    replacement: str,
) -> Mutant:
    line, column = _line_column(source, start)
    return Mutant(
        target=target,
        start=start,
        end=end,
        line=line,
        column=column,
        operator_class=operator_class,
        operator=operator,
        variant_family=variant_family,
        original=source[start:end],
        replacement=replacement,
    )


def _comparison_mutants(target: str, source: str, mask: str) -> Iterable[Mutant]:
    replacements = {
        ">=": (">", "comparison_gte_to_gt", "boundary"),
        "==": ("!=", "comparison_eq_to_ne", "equality"),
        "!=": ("==", "comparison_ne_to_eq", "equality"),
        ">": (">=", "comparison_gt_to_gte", "boundary"),
    }
    for match in re.finditer(r">=|==|!=|>", mask):
        token = match.group(0)
        start, end = match.span()
        if token == ">":
            previous = mask[start - 1] if start else ""
            following = mask[end] if end < len(mask) else ""
            if previous in "=>" or following in ">=":
                continue
            # Formatted comparisons have surrounding whitespace. This avoids
            # treating generic type closers such as List<String> as operators.
            if not (previous.isspace() or following.isspace()):
                continue
            line_start = mask.rfind("\n", 0, start) + 1
            prefix = mask[line_start:start]
            if re.search(
                r"(?:^|[\s(,:])(?:[A-Za-z_]\w*\.)*[A-Za-z_]\w*\s*"
                r"<[^<>;=(){}]+$",
                prefix,
            ):
                continue
        replacement, operator, family = replacements[token]
        yield _make_mutant(
            target,
            source,
            start,
            end,
            "comparison_flip",
            operator,
            family,
            replacement,
        )


def _boolean_mutants(target: str, source: str, mask: str) -> Iterable[Mutant]:
    for match in re.finditer(r"\b(?:true|false)\b", mask):
        original = match.group(0)
        replacement = "false" if original == "true" else "true"
        yield _make_mutant(
            target,
            source,
            match.start(),
            match.end(),
            "boolean_literal",
            f"boolean_{original}_to_{replacement}",
            original,
            replacement,
        )


_NUMBER_RE = re.compile(
    r"(?<![\w.])(?:0[xX][0-9A-Fa-f_]+|\d[\d_]*(?:\.\d[\d_]*)?"
    r"(?:[eE][+-]?\d[\d_]*)?)(?![\w.])"
)


def _numeric_replacements(token: str) -> Tuple[Optional[str], str]:
    clean = token.replace("_", "")
    if clean.lower().startswith("0x"):
        value = int(clean, 16)
        return (None if value == 0 else "0", hex(value + 1))
    if "." in clean or "e" in clean.lower():
        value = float(clean)
        incremented = value + 1.0
        increment = format(incremented, ".15g")
        if "." in clean and "." not in increment and "e" not in increment.lower():
            increment += ".0"
        return (None if value == 0 else "0.0", increment)
    value = int(clean, 10)
    return (None if value == 0 else "0", str(value + 1))


def _numeric_mutants(target: str, source: str, mask: str) -> Iterable[Mutant]:
    for match in _NUMBER_RE.finditer(mask):
        token = match.group(0)
        zero, increment = _numeric_replacements(token)
        if zero is not None:
            yield _make_mutant(
                target,
                source,
                match.start(),
                match.end(),
                "numeric_literal",
                "numeric_to_zero",
                "zero",
                zero,
            )
        yield _make_mutant(
            target,
            source,
            match.start(),
            match.end(),
            "numeric_literal",
            "numeric_increment",
            "increment",
            increment,
        )


def _condition_mutants(target: str, source: str, mask: str) -> Iterable[Mutant]:
    for match in re.finditer(r"\b(?:if|while)\b", mask):
        cursor = match.end()
        while cursor < len(mask) and mask[cursor].isspace():
            cursor += 1
        if cursor >= len(mask) or mask[cursor] != "(":
            continue
        depth = 0
        end = cursor
        while end < len(mask):
            if mask[end] == "(":
                depth += 1
            elif mask[end] == ")":
                depth -= 1
                if depth == 0:
                    break
            end += 1
        if depth != 0:
            continue
        condition_start = cursor + 1
        condition_end = end
        original = source[condition_start:condition_end]
        stripped = original.strip()
        for replacement in ("true", "false"):
            if stripped == replacement:
                continue
            yield _make_mutant(
                target,
                source,
                condition_start,
                condition_end,
                "condition_short_circuit",
                f"condition_to_{replacement}",
                replacement,
                replacement,
            )


def generate_mutants(target: str, source: str) -> List[Mutant]:
    mask = _code_mask(source)
    mutants: List[Mutant] = []
    mutants.extend(_comparison_mutants(target, source, mask))
    mutants.extend(_boolean_mutants(target, source, mask))
    mutants.extend(_numeric_mutants(target, source, mask))
    mutants.extend(_condition_mutants(target, source, mask))
    unique = {mutant.mutant_id: mutant for mutant in mutants}
    return sorted(
        unique.values(),
        key=lambda item: (item.start, item.operator_class, item.operator, item.replacement),
    )


_DIRECTIVE_RE = re.compile(r"\b(?:import|export|part)\s+(.+?);", re.DOTALL)
_URI_RE = re.compile(r"['\"]([^'\"]+)['\"]")


def _resolve_uri(root: Path, current: Path, uri: str, package_name: str) -> Optional[Path]:
    if uri.startswith(f"package:{package_name}/"):
        return (root / "lib" / uri.split("/", 1)[1]).resolve()
    if uri.startswith("dart:") or uri.startswith("package:"):
        return None
    if "://" in uri:
        return None
    return (current.parent / uri).resolve()


def derive_tests(root: Path, target: str, package_name: str) -> List[str]:
    """Return test files whose static dependency closure reaches target."""

    root = root.resolve()
    target_path = (root / target).resolve()
    dart_files = sorted((root / "lib").rglob("*.dart")) + sorted(
        (root / "test").rglob("*.dart")
    )
    known = {path.resolve() for path in dart_files}
    reverse: Dict[Path, Set[Path]] = defaultdict(set)
    exact_references = {
        target,
        f"package:{package_name}/{target[len('lib/'):]}",
    }

    for path in dart_files:
        resolved_path = path.resolve()
        source = path.read_text(encoding="utf-8")
        for directive in _DIRECTIVE_RE.finditer(source):
            for uri in _URI_RE.findall(directive.group(1)):
                dependency = _resolve_uri(root, resolved_path, uri, package_name)
                if dependency is not None and dependency in known:
                    reverse[dependency].add(resolved_path)
        # Source-contract tests sometimes read a production file as text
        # instead of importing it. Model that exact reference as an edge.
        if any(reference in source for reference in exact_references):
            reverse[target_path].add(resolved_path)

    reachable: Set[Path] = {target_path}
    queue = deque([target_path])
    while queue:
        dependency = queue.popleft()
        for importer in reverse.get(dependency, set()):
            if importer not in reachable:
                reachable.add(importer)
                queue.append(importer)

    test_root = (root / "test").resolve()
    selected = []
    for path in reachable:
        if path.name.endswith("_test.dart") and test_root in path.parents:
            selected.append(path.relative_to(root).as_posix())
    return sorted(selected)


def _package_name(root: Path) -> str:
    pubspec = (root / "pubspec.yaml").read_text(encoding="utf-8")
    match = re.search(r"(?m)^name:\s*([^\s#]+)", pubspec)
    if not match:
        raise RuntimeError("pubspec.yaml is missing a package name")
    return match.group(1)


def _normalize_suite_path(root: Path, value: str) -> str:
    if value.startswith("file:"):
        value = unquote(urlparse(value).path)
    path = Path(value)
    if not path.is_absolute():
        path = root / path
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def _test_command(target: str, timeout_seconds: int) -> str:
    return (
        "python3 tools/mutation/mutation_probe.py test "
        f"--target {target} --timeout {timeout_seconds}"
    )


def run_test_subset(root: Path, tests: Sequence[str], timeout_seconds: int) -> Dict[str, object]:
    command = ["flutter", "test", "--no-pub", "-r", "json"] + list(tests)
    started = time.monotonic()
    try:
        completed = subprocess.run(
            command,
            cwd=str(root),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            errors="replace",
            timeout=timeout_seconds,
            check=False,
        )
        timed_out = False
        stdout = completed.stdout
        stderr = completed.stderr
        return_code = completed.returncode
    except subprocess.TimeoutExpired as error:
        timed_out = True
        stdout = error.stdout or ""
        stderr = error.stderr or ""
        if isinstance(stdout, bytes):
            stdout = stdout.decode("utf-8", "replace")
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", "replace")
        return_code = 124

    suites: Dict[int, str] = {}
    tests_by_id: Dict[int, Tuple[str, Optional[int]]] = {}
    failures: List[Dict[str, object]] = []
    parse_errors = 0
    for line in stdout.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            if line.strip():
                parse_errors += 1
            continue
        event_type = event.get("type")
        if event_type == "suite":
            suite = event.get("suite", {})
            if "id" in suite and "path" in suite:
                suites[int(suite["id"])] = _normalize_suite_path(root, str(suite["path"]))
        elif event_type == "testStart":
            test = event.get("test", {})
            if "id" in test:
                suite_id = test.get("suiteID")
                tests_by_id[int(test["id"])] = (
                    str(test.get("name", "<unnamed>")),
                    int(suite_id) if suite_id is not None else None,
                )
        elif event_type == "testDone" and event.get("result") in {"failure", "error"}:
            test_id = int(event.get("testID", -1))
            name, suite_id = tests_by_id.get(test_id, ("<unknown>", None))
            failures.append(
                {
                    "name": name,
                    "suite": suites.get(suite_id, "<unknown>"),
                    "result": event.get("result"),
                }
            )

    expected = set(tests)
    loaded = {path for path in suites.values() if path.startswith("test/")}
    missing = sorted(expected - loaded)
    unexpected = sorted(loaded - expected)
    assertion_failures = [item for item in failures if item["result"] == "failure"]
    errors = [item for item in failures if item["result"] == "error"]
    combined_output = stdout + "\n" + stderr
    compile_patterns = (
        "Failed to load",
        "Compilation failed",
        "Could not compile",
        "Target of URI hasn't been generated",
        "Error: The method",
        "Error: The getter",
        "Error: The argument type",
        "Error: A value of type",
        "Error: Expected",
    )
    compile_error = any(pattern in combined_output for pattern in compile_patterns)
    elapsed = time.monotonic() - started
    return {
        "flutter_command": command,
        "return_code": return_code,
        "timed_out": timed_out,
        "elapsed_seconds": round(elapsed, 3),
        "expected_suite_count": len(expected),
        "loaded_suite_count": len(loaded),
        "missing_suites": missing,
        "unexpected_suites": unexpected,
        "failure_count": len(failures),
        "assertion_failure_count": len(assertion_failures),
        "error_count": len(errors),
        "failures": failures,
        "compile_error_detected": compile_error,
        "json_parse_warning_count": parse_errors,
        "stderr_sha256": hashlib.sha256(stderr.encode("utf-8")).hexdigest(),
    }


def classify_test_result(result: Dict[str, object], expected_tests: Set[str]) -> str:
    if result["timed_out"]:
        return "timeout"
    if result["missing_suites"]:
        return "skipped_or_unable"
    failures = result["failures"]
    assert isinstance(failures, list)
    if result["compile_error_detected"] or result["error_count"]:
        return "compile_or_crash"
    if result["assertion_failure_count"]:
        killer_suites = {str(item["suite"]) for item in failures}
        if killer_suites - expected_tests:
            return "killed_by_non_target"
        return "killed"
    if result["return_code"] == 0:
        return "survived"
    return "compile_or_crash"


def select_mutants(mutants: Sequence[Mutant], per_operator: int) -> Set[str]:
    """Deterministically stratify by target, operator class, and variant family."""

    grouped: Dict[Tuple[str, str], List[Mutant]] = defaultdict(list)
    for mutant in mutants:
        grouped[(mutant.target, mutant.operator_class)].append(mutant)
    selected: Set[str] = set()
    for key in sorted(grouped):
        candidates = grouped[key]
        families: Dict[str, List[Mutant]] = defaultdict(list)
        for candidate in candidates:
            families[candidate.variant_family].append(candidate)
        for family in families:
            families[family].sort(
                key=lambda item: hashlib.sha256(item.mutant_id.encode("ascii")).hexdigest()
            )
        family_names = sorted(families)
        while len([item for item in selected if any(c.mutant_id == item for c in candidates)]) < per_operator:
            progressed = False
            for family in family_names:
                if not families[family]:
                    continue
                selected.add(families[family].pop(0).mutant_id)
                progressed = True
                current = sum(candidate.mutant_id in selected for candidate in candidates)
                if current >= per_operator:
                    break
            if not progressed:
                break
    return selected


def _require_clean_targets(root: Path, targets: Sequence[str]) -> None:
    completed = subprocess.run(
        ["git", "status", "--porcelain", "--"] + list(targets),
        cwd=str(root),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or "git status failed")
    if completed.stdout.strip():
        raise RuntimeError("target files are already dirty; refusing to mutate them")


def _write_json(path: Path, payload: Dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(str(temporary), str(path))


def _common_context(root: Path, targets: Sequence[str], timeout_seconds: int) -> Dict[str, object]:
    package_name = _package_name(root)
    tests_by_target = {
        target: derive_tests(root, target, package_name) for target in targets
    }
    for target, tests in tests_by_target.items():
        if not tests:
            raise RuntimeError(f"no reproducible directed tests derived for {target}")
    return {
        "package_name": package_name,
        "tests_by_target": tests_by_target,
        "test_commands": {
            target: _test_command(target, timeout_seconds) for target in targets
        },
    }


def command_map(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    context = _common_context(root, args.target, args.timeout)
    print(json.dumps(context, ensure_ascii=False, indent=2))
    return 0


def command_list(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    mutants = []
    for target in args.target:
        source = (root / target).read_text(encoding="utf-8")
        mutants.extend(generate_mutants(target, source))
    counts: Dict[str, Dict[str, int]] = defaultdict(lambda: defaultdict(int))
    for mutant in mutants:
        counts[mutant.target][mutant.operator_class] += 1
    print(
        json.dumps(
            {
                "candidate_count": len(mutants),
                "counts": counts,
                "mutants": [mutant.as_dict() for mutant in mutants] if args.verbose else None,
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


def command_test(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    context = _common_context(root, [args.target], args.timeout)
    tests = context["tests_by_target"][args.target]
    result = run_test_subset(root, tests, args.timeout)
    result["judgement"] = classify_test_result(result, set(tests))
    result["target"] = args.target
    result["directional_test_command"] = _test_command(args.target, args.timeout)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["judgement"] == "survived" else 1


def command_run(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    targets = list(args.target)
    _require_clean_targets(root, targets)
    context = _common_context(root, targets, args.timeout)
    original_bytes = {target: (root / target).read_bytes() for target in targets}
    original_hashes = {
        target: hashlib.sha256(content).hexdigest()
        for target, content in original_bytes.items()
    }
    all_mutants: List[Mutant] = []
    for target in targets:
        all_mutants.extend(generate_mutants(target, original_bytes[target].decode("utf-8")))
    selected_ids = select_mutants(all_mutants, args.sample_per_operator)
    results: List[Dict[str, object]] = []
    baselines: Dict[str, Dict[str, object]] = {}
    started_at = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    interrupted = False

    def restore_all() -> None:
        for target, content in original_bytes.items():
            (root / target).write_bytes(content)

    old_handlers = {}

    def handle_signal(signum: int, _frame: object) -> None:
        nonlocal interrupted
        interrupted = True
        restore_all()
        raise KeyboardInterrupt(f"received signal {signum}")

    for signum in (signal.SIGINT, signal.SIGTERM):
        old_handlers[signum] = signal.getsignal(signum)
        signal.signal(signum, handle_signal)

    try:
        for target in targets:
            tests = context["tests_by_target"][target]
            baseline = run_test_subset(root, tests, args.timeout)
            baseline["judgement"] = classify_test_result(baseline, set(tests))
            baselines[target] = baseline
            if baseline["judgement"] != "survived":
                raise RuntimeError(
                    f"directed baseline is not green for {target}: {baseline['judgement']}"
                )

        for index, mutant in enumerate(all_mutants, start=1):
            base_record = mutant.as_dict()
            base_record["directional_test_command"] = context["test_commands"][mutant.target]
            if mutant.mutant_id not in selected_ids:
                base_record.update(
                    {
                        "failure_count": 0,
                        "assertion_failure_count": 0,
                        "error_count": 0,
                        "judgement": "skipped_sampling",
                        "note": "excluded by deterministic per-target/operator budget",
                    }
                )
                results.append(base_record)
                continue

            target_path = root / mutant.target
            original_source = original_bytes[mutant.target].decode("utf-8")
            if original_source[mutant.start:mutant.end] != mutant.original:
                base_record.update(
                    {
                        "failure_count": 0,
                        "assertion_failure_count": 0,
                        "error_count": 0,
                        "judgement": "skipped_or_unable",
                        "note": "source span no longer matches original token",
                    }
                )
                results.append(base_record)
                continue
            mutated = (
                original_source[:mutant.start]
                + mutant.replacement
                + original_source[mutant.end:]
            )
            try:
                target_path.write_text(mutated, encoding="utf-8")
                test_result = run_test_subset(
                    root,
                    context["tests_by_target"][mutant.target],
                    args.timeout,
                )
                judgement = classify_test_result(
                    test_result,
                    set(context["tests_by_target"][mutant.target]),
                )
                base_record.update(test_result)
                base_record["judgement"] = judgement
                base_record["run_index"] = index
                results.append(base_record)
                print(
                    f"[{len([r for r in results if r.get('judgement') != 'skipped_sampling'])}"
                    f"/{len(selected_ids)}] {mutant.mutant_id} "
                    f"{mutant.target}:{mutant.line} {mutant.operator} => {judgement}",
                    flush=True,
                )
            finally:
                target_path.write_bytes(original_bytes[mutant.target])
                restored_hash = hashlib.sha256(target_path.read_bytes()).hexdigest()
                if restored_hash != original_hashes[mutant.target]:
                    raise RuntimeError(f"failed to restore {mutant.target}")
    except KeyboardInterrupt:
        interrupted = True
        raise
    finally:
        restore_all()
        for signum, handler in old_handlers.items():
            signal.signal(signum, handler)
        restored_hashes = {
            target: hashlib.sha256((root / target).read_bytes()).hexdigest()
            for target in targets
        }
        payload = {
            "schema_version": 1,
            "started_at": started_at,
            "finished_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
            "interrupted": interrupted,
            "targets": targets,
            "derivation_rule": (
                "Parse every Dart import/export/part URI under lib/ and test/, "
                "add exact source-path reference edges, reverse-traverse from the "
                "mutated file, and select every reachable test/**/*_test.dart."
            ),
            "sampling_rule": (
                "For each target file and each of the four operator classes, "
                "select a deterministic SHA-256 ordered, variant-family round-robin "
                f"sample of at most {args.sample_per_operator}; record every other "
                "candidate as skipped_sampling."
            ),
            "sample_per_operator": args.sample_per_operator,
            "candidate_count": len(all_mutants),
            "selected_count": len(selected_ids),
            "tests_by_target": context["tests_by_target"],
            "test_commands": context["test_commands"],
            "original_sha256": original_hashes,
            "restored_sha256": restored_hashes,
            "restore_verified": original_hashes == restored_hashes,
            "baselines": baselines,
            "results": results,
        }
        _write_json(Path(args.output), payload)
    return 0


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="repository root")
    subparsers = parser.add_subparsers(dest="command", required=True)

    map_parser = subparsers.add_parser("map", help="show derived directed tests")
    map_parser.add_argument("--target", action="append", default=[])
    map_parser.add_argument("--timeout", type=int, default=900)
    map_parser.set_defaults(handler=command_map)

    list_parser = subparsers.add_parser("list", help="list mutation candidates")
    list_parser.add_argument("--target", action="append", default=[])
    list_parser.add_argument("--verbose", action="store_true")
    list_parser.set_defaults(handler=command_list)

    test_parser = subparsers.add_parser("test", help="run and verify one directed subset")
    test_parser.add_argument("--target", required=True)
    test_parser.add_argument("--timeout", type=int, default=900)
    test_parser.set_defaults(handler=command_test)

    run_parser = subparsers.add_parser("run", help="run a one-mutant-at-a-time batch")
    run_parser.add_argument("--target", action="append", default=[])
    run_parser.add_argument("--sample-per-operator", type=int, default=2)
    run_parser.add_argument("--timeout", type=int, default=900)
    run_parser.add_argument("--output", required=True)
    run_parser.set_defaults(handler=command_run)
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = _parser()
    args = parser.parse_args(argv)
    if hasattr(args, "target") and not args.target:
        args.target = list(DEFAULT_TARGETS)
    if getattr(args, "sample_per_operator", 1) < 1:
        parser.error("--sample-per-operator must be at least 1")
    return int(args.handler(args))


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, OSError, ValueError) as error:
        print(f"mutation probe error: {error}", file=sys.stderr)
        sys.exit(2)
