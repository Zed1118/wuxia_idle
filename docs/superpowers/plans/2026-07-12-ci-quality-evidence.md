# CI Quality Evidence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a measured line-coverage ratchet and a manual/scheduled Windows release artifact workflow without reducing existing PR test coverage.

**Architecture:** A small pure Dart LCOV parser owns coverage accounting while a thin CLI reads the versioned baseline and exits non-zero on regression. CI keeps its current full coverage run and invokes the CLI afterward. Windows release evidence lives in a separate workflow so PR feedback and unsigned release builds remain independent.

**Tech Stack:** Dart 3.11, Flutter 3.41.5, `flutter_test`, LCOV, GitHub Actions YAML, Ruby/Psych syntax verification.

---

## Branch and recovery protocol

- Branch: `codex/ci-quality-evidence`
- Worktree: `/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/ci-quality-evidence`
- Baseline: `main` at `62164693`
- Rejected-task registry: read; no conflict.

## CLAUDE.md §8.2 acceptance checklist

- [ ] Production wiring: `.github/workflows/ci.yml` invokes the ratchet after the real coverage run.
- [ ] Windows evidence: separate workflow builds Windows release on schedule/manual trigger and uploads an unsigned artifact.
- [ ] Targeted tests: parser, threshold, baseline and workflow contract tests pass.
- [ ] Real baseline: fresh `flutter test --coverage --no-pub` passes and the CLI accepts its LCOV result.
- [ ] Static/YAML checks: `flutter analyze --no-pub` and Ruby/Psych parsing pass.
- [ ] Redlines: no gameplay, YAML numbers, schema, GDD, CLAUDE, dependency or product-behavior changes.
- [ ] Residual risk: Windows runner execution, signing, upgrade install, audio, performance and beta are explicitly recorded.
- [ ] Hygiene: no generated coverage/build artifact committed; worktree clean.
- [ ] Ready signal: final tip begins with `[READY]`.

### Task 1: Specify coverage and workflow contracts with failing tests

**Files:**
- Create: `test/tools/coverage_ratchet_test.dart`
- Create: `test/tools/ci_workflow_contract_test.dart`
- Expected later create: `tool/coverage_ratchet.dart`
- Expected later create: `.github/coverage-ratchet.json`
- Expected later create: `.github/workflows/windows-release.yml`

- [ ] **Step 1: Write the failing coverage parser tests**

The test imports `../../tool/coverage_ratchet.dart` and asserts:

```dart
final summary = parseLcov('''
SF:lib/a.dart
DA:1,1
DA:2,0
end_of_record
''');
expect(summary.totalLines, 2);
expect(summary.coveredLines, 1);
expect(summary.percentage, 50);
```

Add cases for duplicate `SF+line` records taking max hits, generated suffix exclusion,
empty LCOV rejection, and `meetsMinimum` at/either side of the boundary.

- [ ] **Step 2: Write the failing workflow contract tests**

Read the three repository files and assert exact durable tokens:

```dart
expect(ci, contains('dart run tool/coverage_ratchet.dart'));
expect(windows, contains('flutter build windows --release --no-pub'));
expect(windows, contains('workflow_dispatch:'));
expect(windows, contains('schedule:'));
expect(windows, contains('actions/upload-artifact@v4'));
expect(baseline['lineCoverageMinimum'], isA<num>());
```

- [ ] **Step 3: Run RED**

Run:

```bash
flutter test --no-pub test/tools/coverage_ratchet_test.dart test/tools/ci_workflow_contract_test.dart
```

Expected: compile/file failures because the tool, baseline and Windows workflow do not exist.

- [ ] **Step 4: Commit test contract**

```bash
git add test/tools/coverage_ratchet_test.dart test/tools/ci_workflow_contract_test.dart
git commit -m "定义 CI 质量证据契约"
```

### Task 2: Implement the LCOV ratchet

**Files:**
- Create: `tool/coverage_ratchet.dart`
- Create: `.github/coverage-ratchet.json`
- Test: `test/tools/coverage_ratchet_test.dart`

- [ ] **Step 1: Implement the pure parser**

Create these public types/functions:

```dart
class CoverageSummary {
  const CoverageSummary({required this.coveredLines, required this.totalLines});
  final int coveredLines;
  final int totalLines;
  double get percentage => coveredLines * 100 / totalLines;
  bool meetsMinimum(double minimum) => percentage + 1e-9 >= minimum;
}

bool isGeneratedCoveragePath(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.mocks.dart');
```

Implement `parseLcov` with this exact state model: keep `String? currentSource`, iterate
`LineSplitter.split(source)`, update `currentSource` on `SF:`, ignore `DA:` until a non-generated
source exists, parse the first two comma-separated fields as line/hits, and store hits in
`Map<String, int>` keyed by `'$currentSource:$line'` using `max(oldHits, hits)`. Throw
`FormatException` when the map is empty; otherwise count values greater than zero and return
`CoverageSummary`.

- [ ] **Step 2: Implement CLI I/O and exit behavior**

`main(List<String> args)` reads defaults:

```text
coverage/lcov.info
.github/coverage-ratchet.json
```

It prints covered/total/percentage/minimum. Missing files, malformed baseline and regression
write a concise stderr message and set `exitCode = 1`.

- [ ] **Step 3: Add provisional versioned baseline**

Create valid JSON with `lineCoverageMinimum: 0.0`, `sampledAt: 2026-07-12`, and a note that
Task 4 replaces the provisional value with the freshly measured percentage minus 0.05 points.
The provisional zero may not be the final committed value.

- [ ] **Step 4: Run GREEN**

```bash
flutter test --no-pub test/tools/coverage_ratchet_test.dart
```

Expected: all parser/threshold tests pass.

- [ ] **Step 5: Commit parser slice**

```bash
git add tool/coverage_ratchet.dart .github/coverage-ratchet.json test/tools/coverage_ratchet_test.dart
git commit -m "增加覆盖率渐进门禁工具"
```

### Task 3: Wire CI and Windows release evidence

**Files:**
- Modify: `.github/workflows/ci.yml`
- Create: `.github/workflows/windows-release.yml`
- Test: `test/tools/ci_workflow_contract_test.dart`

- [ ] **Step 1: Wire ratchet after coverage generation**

Add to the existing test job before artifact upload:

```yaml
      - name: Enforce line coverage ratchet
        run: dart run tool/coverage_ratchet.dart
```

- [ ] **Step 2: Add the Windows workflow**

Use `workflow_dispatch` and weekly cron, `windows-latest`, pinned Flutter 3.41.5, build_runner,
analyze, `flutter build windows --release --no-pub`, and artifact upload of
`build/windows/x64/runner/Release/` with `retention-days: 14`.

- [ ] **Step 3: Run workflow GREEN tests**

```bash
flutter test --no-pub test/tools/ci_workflow_contract_test.dart
ruby -e 'require "yaml"; ARGV.each { |f| YAML.safe_load_file(f, aliases: true) }' \
  .github/workflows/ci.yml .github/workflows/windows-release.yml
```

Expected: tests and YAML parsing exit zero.

- [ ] **Step 4: Commit workflow slice**

```bash
git add .github/workflows/ci.yml .github/workflows/windows-release.yml test/tools/ci_workflow_contract_test.dart
git commit -m "接入覆盖率与 Windows 发布证据"
```

### Task 4: Measure and lock the real baseline

**Files:**
- Modify: `.github/coverage-ratchet.json`
- Modify: `docs/superpowers/plans/2026-07-12-ci-quality-evidence.md`

- [ ] **Step 1: Generate fresh coverage**

```bash
flutter test --coverage --no-pub
```

Expected: full suite succeeds and creates `coverage/lcov.info`.

- [ ] **Step 2: Measure with the new parser**

Run the tool once against provisional zero, record its printed percentage, then set
`lineCoverageMinimum` to `floor(percentage * 20) / 20 - 0.05` (two decimals). This rounds down
to a 0.05-point grid and reserves one 0.05-point tolerance step without inventing a target.

- [ ] **Step 3: Prove pass and prove failure**

```bash
dart run tool/coverage_ratchet.dart
```

Expected: exit zero at the committed baseline. A unit test already proves a value below the
threshold fails; do not mutate the committed baseline solely for a shell demonstration.

- [ ] **Step 4: Ensure coverage is untracked/ignored**

```bash
git status --short
git check-ignore -v coverage/lcov.info
```

Expected: no coverage artifact is staged or untracked.

- [ ] **Step 5: Commit measured baseline and recovery point**

```bash
git add .github/coverage-ratchet.json docs/superpowers/plans/2026-07-12-ci-quality-evidence.md
git commit -m "锁定当前覆盖率渐进基线"
```

### Task 5: Final verification and freeze

**Files:**
- Modify: `docs/superpowers/plans/2026-07-12-ci-quality-evidence.md`

- [ ] **Step 1: Run fresh targeted and static checks**

```bash
flutter test --no-pub test/tools/coverage_ratchet_test.dart test/tools/ci_workflow_contract_test.dart
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed tool test/tools
git diff --check
```

- [ ] **Step 2: Re-run the ratchet against the fresh full coverage file**

```bash
dart run tool/coverage_ratchet.dart
```

- [ ] **Step 3: Update recovery evidence**

Record status, last completed action, exact commands/results, external Windows limitations,
and no gameplay/redline impact in this plan.

- [ ] **Step 4: Commit and freeze**

```bash
git add docs/superpowers/plans/2026-07-12-ci-quality-evidence.md
git commit -m "更新 CI 质量证据恢复点"
git commit --allow-empty -m "[READY] 完成 CI 质量与 Windows 发布证据"
git status --short --branch
```

## Current recovery point

- Status: plan complete; implementation not started.
- Last completed: design committed at `8bd0ec98`; diagnostic-file exclusion disproved by
  1–3 second per-file measurements; full main suite passed in 237525 ms.
- Next: Task 1, write the two failing contract test files and observe RED.
- Verification: worktree setup generated 114 ignored outputs; baseline analyze 0 issue.
- Blockers: none. Windows execution is an external verification item, not a local blocker.
