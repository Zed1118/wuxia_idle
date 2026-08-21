# Phase 0A stability fixes

## Goal

Prevent terminal outcome feedback from being dropped when the per-consume VFX
capacity is exhausted, and initialize the gather/clear skill slots from the
player's actual opening qi. Preserve all combat values, YAML, formulas, event
ordering, and non-target behavior.

Branch: `codex/phase0a-stability-0821`

## Acceptance checklist

- [x] Victory and defeat outcome seals are emitted even when ordinary VFX
      entries have filled the batch capacity.
- [x] The ordinary VFX capacity remains bounded and no post-terminal feedback
      is accepted.
- [x] Gather and clear slots use `availabilityOf` with production `openingQi`.
- [x] Existing numeric skill initialization and first-tick behavior remain
      unchanged.
- [x] Targeted tests and `flutter analyze --no-pub` pass.
- [x] No YAML, schema, save-version, formula, balance, or player-text changes.
- [x] Recovery notes and `PROGRESS.md` are current, and the branch is ready for
      a clean `[READY]` tip.

## Slices and recovery points

1. Establish isolated baseline and add focused failing tests.
2. Implement the two minimal fixes and review the diff.
3. Run targeted verification and analyze; run the batch-end full suite.
4. Update recovery/progress records, mark `[READY]`, merge locally, and clean
   the worktree.

Current recovery point: implementation and verification complete. Fresh
worktree setup required `flutter pub get` plus generated Isar/Riverpod outputs;
the corrected baseline was 38/38. The three focused regression assertions then
failed on the old implementation and now pass, with the focused suite at 41/41.
Expanded combat verification passed at 103/103, `flutter analyze --no-pub`
reported no issues, and the batch-end full suite passed at 5274/5274. Diff
review confirms no YAML, schema, save-version, formula, balance, or player-text
changes. Recovery notes and `PROGRESS.md` are current. Next: mark this commit
`[READY]`, fast-forward local main, verify the merge state, and remove the
worktree.
