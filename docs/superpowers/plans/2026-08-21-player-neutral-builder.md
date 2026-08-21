# Player neutral builder batch

## Goal

Extract the persistent-player combat fact derivation into an engine-neutral
`PlayerCombatantSnapshotBuilder`. Production player assembly must no longer use
`BattleCharacter.fromCharacter -> Legacy3v3CombatantAdapter.toSnapshot`.

Branch: `codex/player-neutral-builder-0821`

## Frozen scope

- Preserve active/exact roster selection, occupancy filtering, fallback, order,
  fail-fast behavior, Isar reads, and auto-fill writeback order.
- Preserve every player snapshot field, skill selection/fallback, usage counts,
  injury modifiers, founder buff, forging, resonance, and synergy behavior.
- Keep `BattleCharacter.fromCharacter` as a legacy-compatible entry point, but
  make it delegate neutral fact derivation to the new builder.
- Do not change YAML, formulas, balance values, production consumers, or legacy
  adapter team-cap behavior.

## Acceptance checklist

- [x] Production player assembler imports neither `battle_state.dart` nor the
  legacy adapter and contains no `BattleCharacter.fromCharacter` call.
- [x] Neutral builder has no `teamSide` or `slotIndex` input.
- [x] Legacy factory keeps team/slot validation and field-equivalent output.
- [x] Direct builder tests cover the full snapshot field contract and legacy
  fallback behavior.
- [x] Exact roster can assemble more than three neutral snapshots in order.
- [ ] Targeted tests, `flutter analyze`, and batch-end verification pass.
- [ ] Recovery pointers are updated and the branch tip is marked `[READY]`.

## Slices and recovery points

1. Add the neutral builder and direct contract tests.
2. Delegate the legacy factory and reconnect production player assembly.
3. Add source/roster regression gates and run targeted verification.
4. Update `PROGRESS.md` and `docs/sessions/NEXT.md`, then run final verification.

Current recovery point: slices 1–3 implemented; targeted 71/71 passed. Next run
analyze, review the final diff, update progress pointers, and verify the batch.
