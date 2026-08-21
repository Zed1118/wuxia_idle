# Phase 0A Boss phase runtime batch

## Goal

Freeze the Ch2–Ch21/tower Boss capability matrix, then carry HP-threshold Boss
phase transitions and phase-unlocked skills through production mapping, the
neutral reducer, enemy AI, and the headless runner. This batch deliberately does
not implement `chargeSkillId` or `chargeCounter`.

Branch: `codex/phase0a-boss-phase-0821`

## Frozen capability matrix

- Preflight scope: 100 Ch2–Ch21 mainline stages plus 49 tower floors.
- Current explicit Boss phase/charge skip group: 24 entries = 19 stages + 5
  tower floors.
- The 24 entries are all coupled to charge semantics: every phase-bearing entry
  has `onEnterMechanic: chargeCounter`, and all 19 stages also have a top-level
  `chargeSkillId`.
- Latent overlaps remain behind higher-priority skip reasons: 8 stages + tower
  32 have vulnerability; tower 42 has guardian + charge; tower 49 has guardian
  + vulnerability.
- Therefore this slice adds a reusable phase capability but does not reclassify
  any coupled production entry as fully eligible. The manifest must remain
  fail-closed until charge semantics land.

## Frozen scope

- Add immutable Phase 0A runtime fields for phase index, phase definitions,
  unlocked enemy skill ids, enemy skill cooldowns, and enemy auto-ultimate.
- Initialize those fields only from `CombatantSnapshot` data already resolved by
  `EnemyCombatantSnapshotAssembler`; do not query repositories in the reducer.
- Advance across one or multiple HP thresholds after player damage, once per
  phase, and emit deterministic phase-transition events.
- Pre-resolve phase skill bindings in the production mapper. Enemy AI may cast
  unlocked power/ultimate skills using existing qi/cooldown values and stable
  highest-power/id tie-breaking; damage must still go through
  `DamageCalculator.calculateResolved`.
- Carry the same behavior through interactive production flow and headless flow.
- Keep `chargeSkillId`, `chargeCounter`, vulnerability, guardian, lifesteal,
  active stagger, YAML, formulas, balance values, and legacy consumers out of
  scope.

## Acceptance checklist

- [x] Production wiring: `StageDef/TowerFloorDef -> EnemyCombatantSnapshotAssembler
  -> Phase0aStageContentMapper -> Phase0aProductionFlowAssembler -> reducer/AI ->
  headless` carries phase state and unlocked skills without fixture-only wiring.
- [x] Reducer advances exactly once per crossed threshold, supports crossing
  multiple thresholds in one hit, does not transition dead/non-phase actors, and
  preserves deterministic event sequence/state equality.
- [x] Enemy AI consumes only currently unlocked phase skills, respects qi and
  cooldown, and keeps no-phase/basic-only behavior unchanged.
- [x] Enemy phase-skill damage uses the existing calculator; no second formula,
  Chinese player text, or numeric combat defaults are added in Dart.
- [x] Capability manifest remains fail-closed for every entry that still has
  top-level charge or `chargeCounter`; no degraded run is reported as eligible.
- [x] Targeted tests cover model/reducer, mapper, production flow, headless, and
  manifest classification with per-file pass evidence; `flutter analyze` passes.
- [x] Red-line impact: no YAML/schema/save version/formula/balance/UI changes; no
  impact to three-system locks, online=offline, or anti-mainstream rules.
- [x] Residual risks explicitly retain charge/interrupt, vulnerability,
  guardian, six-person subjective Gate, and Windows Gate.
- [x] Main review checks actual diff, production evidence, debug noise, temporary
  files, and Chinese verb-object commit messages; branch tip is clean `[READY]`.

## Slices and recovery points

1. Freeze capability matrix and runtime/API boundaries.
2. Add phase runtime model, reducer transitions, and events with unit tests.
3. Add enemy phase-skill binding/AI/calculator path and production mapper tests.
4. Exercise production flow/headless, keep manifest fail-closed, and run targeted
   verification.
5. Update recovery pointers, run analyze/full verification, mark `[READY]`, and
   merge locally to `main`.

Current recovery point: implementation and main-agent diff review complete.
Production tower 7 proves threshold -> unlock -> AI cast through the neutral
flow/headless loop; no-phase enemies retain the old qi/cooldown path and the
149-entry manifest remains fail-closed. Verification: targeted 67/67,
`flutter analyze --no-pub` 0 issues, full `flutter test --no-pub -r compact`
5271/5271. Next: commit this recovery update, mark `[READY]`, then locally merge
to `main` and rerun merge-state analyze plus the focused production chain. No
blockers.
