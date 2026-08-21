# Phase 0A Q/R typed behavior slice

## Goal

Replace production Q/R synthetic move definitions with two data-defined
`SkillDef` transition skills whose typed Phase 0A behavior flows through loader,
binding, intent, reducer events, damage resolution, settlement, and headless.

Branch: `codex/phase0a-qr-behavior-0821`

## Boundaries

- Keep Q/R hotkeys and caster-centered radial geometry.
- Q is pull-only; R is radial damage plus hit-stagger outcome.
- Unknown behavior/effect/geometry and unsupported combinations fail closed.
- Define but do not consume the future `break` effect; bindings reject it until
  the charge/interrupt slice owns the state transition.
- Do not change enemies, formulas, save schema, starter power-skill exposure,
  or mouse targeting.
- Legacy explicit adapter parameters remain for isolated fixtures only; the
  production mapper must use real skill behavior.

## Acceptance checklist

- [x] Focused old-behavior tests fail before implementation.
- [x] YAML loader produces immutable typed behavior for both transition skills.
- [x] Production mapping derives Q/R identity, qi, cooldown, and geometry from
      their real skills; fixed arena parameters are not the production source.
- [x] Reducer events and settlement preserve the real skill ids.
- [x] Q remains control-only and R keeps the existing DamageCalculator path.
- [x] Focused, analyze, profile, and full verification pass.
- [ ] Recovery records, `[READY]`, local merge, and worktree cleanup complete.

## Task slices

1. Add the fail-closed YAML behavior schema and real Q/R `SkillDef` rows.
2. Bind production mapping/input/damage to typed tactical skills while keeping
   an explicit legacy-fixture fallback.
3. Preserve real skill identity through reducer events and settlement.
4. Update count/target redlines, documentation, and focused coverage.
5. Run analyze, profile, end-to-end, and full-suite gates; freeze as `[READY]`.

## Delivery evidence

- Production path: `data/skills.yaml` → `SkillDef.fromYaml` →
  `Phase0aTacticalSkillBinding` → `Phase0aPlayerInputAdapter` → reducer
  started/applied events → damage/settlement/headless flow.
- Targeted verification: 103 focused tests passed; 94 regression tests passed;
  11 final schema/count/target redline tests passed; the real-skill Isar E2E
  test passed; the founder profile passed 2 tests (including its 1,500-run
  simulation).
- Static/full verification: `flutter analyze` reported no issues;
  `flutter test --reporter compact` passed 5,285/5,285; `git diff --check`
  passed.
- Redlines: no save schema, enemy, formula, online/offline, three-system lock,
  or anti-mainstream change. Player-facing names/descriptions and tactical
  values live in YAML; Dart contains only schema/binding validation.
- Residual risk: `break` is schema-only and deliberately rejected by Q/R
  binding until the charge/interrupt slice. Legacy fixed adapter parameters
  remain only as the documented isolated-fixture escape hatch. This slice is
  non-UI and therefore does not require a desktop visual smoke.

## Recovery point

Status: implementation and all verification gates complete, ready to commit and
merge. Started from local main `f43c5421`. Last completed: full suite passed
5,285/5,285 after correcting stale skill-count and AOE test contracts. Next:
create the `[READY]` commit, fast-forward local `main`, verify merged state, and
remove the worktree/branch. Blockers: none.
