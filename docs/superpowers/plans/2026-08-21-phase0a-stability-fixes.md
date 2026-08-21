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
- [ ] Targeted tests and `flutter analyze --no-pub` pass.
- [ ] No YAML, schema, save-version, formula, balance, or player-text changes.
- [ ] Recovery notes, `PROGRESS.md`, a clean `[READY]` tip, local main merge,
      and merge-state verification are complete.

## Slices and recovery points

1. Establish isolated baseline and add focused failing tests.
2. Implement the two minimal fixes and review the diff.
3. Run targeted verification and analyze; run the batch-end full suite.
4. Update recovery/progress records, mark `[READY]`, merge locally, and clean
   the worktree.

Current recovery point: implementation and focused diff review complete. Fresh
worktree setup required `flutter pub get` plus generated Isar/Riverpod outputs;
the corrected baseline was 38/38. The three focused regression assertions then
failed on the old implementation and now pass, with the focused suite at 41/41.
Next: commit the implementation, run the broader targeted set plus analyze/full
verification, then update `PROGRESS.md` and mark the branch `[READY]`.
