#!/usr/bin/env python3
"""Run the opt-in Flutter test-host benchmark with reproducible local evidence.

No game application or existing database is opened. The Dart entrypoint creates
and removes its own temporary Isar directory for each legal founder profile.
This is debug/JIT engineering throughput, never a release-performance promise.
"""

import argparse
import contextlib
import datetime
import hashlib
import json
import itertools
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import time
import uuid


ROOT = Path(__file__).resolve().parents[1]


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def source_hashes():
    paths = set()
    for folder in ("lib", "data", "test", "tool"):
        paths.update(p for p in (ROOT / folder).rglob("*") if p.is_file()
                     and "__pycache__" not in p.parts
                     and not p.is_relative_to(ROOT / "test/tools/output"))
    paths.update(ROOT / p for p in ("pubspec.yaml", "pubspec.lock", "build.yaml", "analysis_options.yaml"))
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(paths)}


def command_output(args):
    result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, check=True)
    return result.stdout.strip()


def validate_report(path, metadata):
    """Reconcile actual measured rows, not just a successful test process."""
    report = json.loads(path.read_text())
    assert report["schema_version"] == 1 and report["run_id"] == metadata["run_id"]
    assert report["source"] == metadata["source"]
    key = report["comparison_key"]
    assert all(key[k] == v for k, v in metadata["comparison_key"].items())
    assert key["config"] == metadata["config"]
    manifest = key["manifest"]
    assert len(manifest) == len(set(manifest)) == 174
    assert sum(x.startswith("mainline/") for x in manifest) == 105
    assert {x for x in manifest if x.startswith("tower/")} == {f"tower/tower_{i}/default" for i in range(1, 50)}
    assert {x for x in manifest if x.startswith("lightFoot/")} == {
        f"lightFoot/stage_light_foot_{i:02d}/default" for i in range(1, 6)}
    assert {x for x in manifest if x.startswith("massBattle/")} == {
        f"massBattle/stage_mass_battle_{i:02d}/{formation}"
        for i in range(1, 6) for formation in ("yanXing", "baGua", "fengShi")}
    assert len({x.split("/")[1] for x in manifest}) == 164
    profiles = key["profile_ids"]
    assert set(profiles) == {f"{s}/mountain_wanderer/balanced_seed/20260820"
                             for s in ("gang_meng", "ling_qiao", "yin_rou")}
    config = metadata["config"]
    expected = set(itertools.product(profiles, manifest,
                                     config["seeds"], range(config["repetitions"]), ("sync", "async")))
    rows = report["runs"]
    actual = [(r["profile_id"], r["case_id"], r["seed"], r["repetition"], r["mode"]) for r in rows]
    assert len(actual) == len(set(actual)) == len(expected) and set(actual) == expected
    grouped = {}
    for row in rows:
        kind, content_id, variant = row["case_id"].split("/")
        assert row["content_id"] == content_id
        assert row["formation"] == (variant if kind == "massBattle" else None)
        if kind == "mainline":
            route = "typed_mainline"
            assert variant == "default"
        elif kind == "tower":
            route = "typed_tower" if int(content_id.removeprefix("tower_")) <= 7 else "legacy_tower"
            assert variant == "default"
        elif kind == "lightFoot":
            route = "legacy_light_foot"
        else:
            assert kind == "massBattle"
            route = "legacy_mass_battle"
        assert row["route"] == route
        assert row["outcome"] in ("victory", "defeat", "ongoing")
        assert row["timed_out"] == (row["outcome"] == "ongoing") == (row["settlement"] is None)
        assert 0 < row["simulated_ticks"] <= key["max_simulation_ticks"]
        assert row["simulated_seconds"] == row["simulated_ticks"] * key["fixed_delta_seconds"]
        assert row["simulation_microseconds"] > 0 and row["assembly_microseconds"] > 0
        wave = row["wave_state"]
        if route.startswith("legacy_"):
            assert isinstance(wave, dict) and wave["waves"] and all(wave["waves"])
            actor_ids = [actor for roster in wave["waves"] for actor in roster]
            assert len(actor_ids) == len(set(actor_ids))
            started, cleared = wave["started_wave_indices"], wave["cleared_wave_indices"]
            assert 1 <= len(started) <= len(wave["waves"])
            assert started == list(range(1, len(started) + 1))
            assert cleared == list(range(1, len(cleared) + 1))
            assert len(cleared) == len(started) - (row["outcome"] != "victory")
            if row["outcome"] == "victory":
                assert len(cleared) == len(wave["waves"])
            if kind == "massBattle":
                policy = wave["transition_policy"]
                assert set(policy) == {"heal_player_to_full", "qi_recovery_pct", "reset_attack_cooldown",
                                       "reset_skill_cooldowns", "intermission_seconds"}
                assert all(type(policy[k]) is bool for k in ("heal_player_to_full", "reset_attack_cooldown", "reset_skill_cooldowns"))
                assert 0 <= policy["qi_recovery_pct"] <= 1 and policy["intermission_seconds"] >= 0
            elif kind == "lightFoot":
                assert len(wave["waves"]) == 1 and wave["transition_policy"] is None
        group_id = (f"{route}/{variant}/{row['mode']}" if kind == "massBattle"
                    else f"{route}/{row['mode']}")
        grouped.setdefault(group_id, []).append(row)
    summaries = {g["id"]: g for g in report["groups"]}
    assert len(summaries) == len(report["groups"]) == len(grouped) == 14
    for identity, samples in grouped.items():
        summary = summaries[identity]
        ticks = sum(r["simulated_ticks"] for r in samples)
        micros = sum(r["simulation_microseconds"] for r in samples)
        completed = sum(not r["timed_out"] for r in samples)
        assert summary["attempts"] == len(samples)
        assert summary["completed_battles"] == completed
        assert summary["timeouts"] == len(samples) - completed
        assert summary["simulated_ticks"] == ticks and summary["simulation_microseconds"] == micros
        assert abs(summary["simulated_ticks_per_second"] - ticks * 1e6 / micros) < 1e-7
        assert abs(summary["completed_battles_per_second"] - completed * 1e6 / micros) < 1e-7
    assert report["correctness"]["same_seed_equal"] is True
    assert report["correctness"]["compared_pairs"] == (174 * 3 * len(config["seeds"]) *
                                                      (2 * (config["warmups"] + config["repetitions"]) - 1))
    return {"rows": len(rows), "groups": len(grouped), "unique_inputs": len(expected),
            "compared_pairs": report["correctness"]["compared_pairs"]}


@contextlib.contextmanager
def benchmark_lock(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a+b") as handle:
        print(f"Waiting for shared verification lock: {path}", flush=True)
        if os.name == "nt":
            import msvcrt
            if path.stat().st_size == 0:
                handle.write(b"0")
                handle.flush()
            handle.seek(0)
            msvcrt.locking(handle.fileno(), msvcrt.LK_LOCK, 1)
        else:
            import fcntl
            fcntl.flock(handle, fcntl.LOCK_EX)
        try:
            yield
        finally:
            if os.name == "nt":
                handle.seek(0)
                msvcrt.locking(handle.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(handle, fcntl.LOCK_UN)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    if not __debug__:
        parser.error("Python optimization disables report assertions; run without -O/PYTHONOPTIMIZE")
    parser.add_argument("--output-dir", type=Path, required=True, help="New evidence directory outside the repository")
    parser.add_argument("--machine-id", required=True, help="Stable identity for this measurement machine")
    parser.add_argument("--repetitions", type=int, default=3)
    parser.add_argument("--warmups", type=int, default=1)
    parser.add_argument("--seeds", default="0,73")
    args = parser.parse_args()
    output = args.output_dir.expanduser().resolve()
    if output.exists() or output.is_relative_to(ROOT):
        parser.error("--output-dir must be new and outside the repository")
    if args.repetitions < 1 or args.warmups < 1 or not args.machine_id.strip():
        parser.error("repetitions/warmups must be positive and machine-id nonempty")
    try:
        seeds = [int(value) for value in args.seeds.split(",")]
    except ValueError:
        parser.error("seeds must be comma-separated integers")
    if not seeds or len(seeds) != len(set(seeds)):
        parser.error("seeds must be nonempty and unique")
    flutter = shutil.which("flutter")
    if not flutter:
        parser.error("flutter must be on PATH")
    output.mkdir(parents=True)
    with benchmark_lock(Path.home() / ".claude/locks/wuxia_full_test.lock"):
        before = source_hashes()
        version = json.loads(command_output([flutter, "--version", "--machine"]))
        hardware = {"machine_id": args.machine_id, "architecture": platform.machine(),
                    "processor": platform.processor(), "logical_processors": os.cpu_count()}
        if sys.platform == "darwin":
            for name in ("hw.model", "machdep.cpu.brand_string", "hw.memsize"):
                hardware[name] = command_output(["sysctl", "-n", name])
        benchmark_files = ["tool/phase0a_headless_benchmark.dart", "tool/run_phase0a_headless_benchmark.py",
                           "test/support/phase0a_ch1_founder_profile.dart",
                           "test/support/phase0a_production_headless_benchmark.dart"]
        metadata = {
            "schema_version": 1, "run_id": str(uuid.uuid4()),
            "config": {"repetitions": args.repetitions, "warmups": args.warmups, "seeds": seeds},
            "source": {"head": command_output(["git", "rev-parse", "HEAD"]),
                       "status": command_output(["git", "status", "--porcelain"]),
                       "source_sha256": digest(before)},
            "comparison_key": {
                "benchmark_version": 2, "execution_mode": "flutter_tester_debug_jit",
                "hardware": hardware, "os": platform.platform(),
                "flutter_framework_revision": version["frameworkRevision"],
                "flutter_engine_revision": version["engineRevision"],
                "dart_sdk_version": version["dartSdkVersion"],
                "pubspec_lock_sha256": before["pubspec.lock"],
                "data_sha256": digest({k: v for k, v in before.items() if k.startswith("data/")}),
                "definition_decoder_sha256": digest({k: v for k, v in before.items() if k.startswith("lib/data/")}),
                "benchmark_input_sha256": digest({k: before[k] for k in benchmark_files}),
            },
        }
        (output / "source-hashes.json").write_text(json.dumps(before, indent=2))
        metadata_file = output / "metadata.json"
        metadata_file.write_text(json.dumps(metadata, indent=2))
        env = os.environ.copy()
        env["PHASE0A_BENCHMARK_METADATA"] = str(metadata_file)
        env["PHASE0A_BENCHMARK_OUTPUT"] = str(output / "benchmark.json")
        command = [flutter, "test", "--no-pub", "--concurrency=1", "--reporter=json",
                   "tool/phase0a_headless_benchmark.dart"]
        started = datetime.datetime.now().astimezone().isoformat()
        clock = time.monotonic()
        print(f"Benchmark started: {started}; evidence: {output}", flush=True)
        with (output / "test-events.jsonl").open("w") as log:
            run = subprocess.run(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
        elapsed = time.monotonic() - clock
        after = source_hashes()
        changes = [k for k in sorted(before.keys() | after.keys()) if before.get(k) != after.get(k)]
        events = []
        for line in (output / "test-events.jsonl").read_text().splitlines():
            try:
                events.append(json.loads(line))
            except ValueError:
                continue
        errors = [e for e in events if e.get("type") == "error"]
        completions = [e for e in events if e.get("type") == "done"]
        tests = [e for e in events if e.get("type") == "testDone" and not e.get("hidden")]
        complete = (run.returncode == 0 and not changes and not errors and len(completions) == 1
                    and completions[0].get("success") is True and len(tests) == 1
                    and tests[0].get("result") == "success" and not tests[0].get("skipped")
                    and (output / "benchmark.json").is_file())
        report_audit = None
        if complete:
            try:
                report_audit = validate_report(output / "benchmark.json", metadata)
            except (AssertionError, KeyError, TypeError, ValueError) as error:
                complete = False
                errors.append({"type": "report_audit", "error": repr(error)})
        # Do not leave a comparable success artifact behind after source drift.
        if not complete and (output / "benchmark.json").exists():
            (output / "benchmark.json").rename(output / "benchmark-invalid.json")
        summary = {"validated_complete": complete, "command": command, "started": started,
                   "wall_seconds": elapsed, "exit_code": run.returncode,
                   "shared_lock_held": True, "source_changes": changes, "errors": errors,
                   "source_sha256": digest(before), "output": str(output), "report_audit": report_audit}
        (output / "verification.json").write_text(json.dumps(summary, indent=2))
        print(json.dumps(summary), flush=True)
        return 0 if complete else 1


if __name__ == "__main__":
    sys.exit(main())
