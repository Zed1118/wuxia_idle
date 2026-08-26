# Mutation probe

`mutation_probe.py` is a dependency-free Dart source mutation probe. It was
built for a bounded first measurement of Phase 0A combat tests, not as a score
optimizer.

## Directed-test derivation

For a target production file, the probe parses every Dart `import`, `export`,
and `part` URI under `lib/` and `test/` (including conditional URIs). It adds an
edge for an exact source-path or `package:` source reference, then traverses the
reverse dependency graph from the target. Every reachable
`test/**/*_test.dart` is the directed subset.

This algorithm is deterministic and can be reproduced without a curated test
list:

```sh
python3 tools/mutation/mutation_probe.py map
python3 tools/mutation/mutation_probe.py test \
  --target lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart
```

The internal Flutter command uses the JSON reporter. The probe compares the
expected paths with reporter `suite` events, so a multi-path run that silently
omits a file is not accepted as green.

## Operators

- comparison flip: `>` to `>=`, `>=` to `>`, `==` to `!=`, and `!=` to `==`;
- boolean literal replacement: `true` and `false`;
- numeric literal replacement: non-zero `n` to `0`, and every `n` to `n + 1`;
- condition short-circuit: a complete `if` or `while` condition to `true` or
  `false`.

Strings and comments are masked before candidate generation. A single mutant
is written at a time. Exact original bytes are restored in the per-mutant
`finally` block and verified by SHA-256 at batch end.

## Bounded batch

```sh
python3 tools/mutation/mutation_probe.py run \
  --sample-per-operator 2 \
  --timeout 900 \
  --output /tmp/mutation-round1.json
```

Sampling is deterministic per target and operator class, round-robin across
variant families and ordered by a stable SHA-256 ID. Every excluded candidate
is emitted as `skipped_sampling`; it is never silently discarded.

Judgements are mutually exclusive:

- `killed`: one or more assertion failures in a derived suite;
- `survived`: all expected suites loaded and passed;
- `compile_or_crash`: compiler/load error, test error, or abnormal runner exit;
- `killed_by_non_target`: an assertion failure came from a suite outside the
  derived subset;
- `skipped_sampling`, `skipped_or_unable`, or `timeout`.

Compile/load failures and test errors never count as killed.

## Interruption recovery

`SIGINT` and `SIGTERM` trigger byte-for-byte restoration. After any forced
interruption, verify and restore before doing anything else:

```sh
git checkout -- \
  lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart \
  lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart
git status -sb
```

Do not commit while a batch is running.

## Probe tests

```sh
python3 -m unittest discover -s tools/mutation -p 'test_*.py'
```
