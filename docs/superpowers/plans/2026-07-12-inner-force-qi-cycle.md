# Inner Force and Qi Cycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split persistent inner force from combat qi, replace spend-down damage with a bounded generate/spend loop, protect old saves, and surface the new semantics consistently across combat, retreat, failure states, and UI.

**Architecture:** Keep `Character.internalForce/internalForceMax` as the persistent cultivation axis and add only the persistent disorder state needed for failure recovery. Replace battle-only `maxInternalForce/currentInternalForce` with immutable `internalForce/maxQi/currentQi` snapshots; make `SkillDef.qiDelta` the single source for generation and cost, and centralize school bonus application in a pure qi resolver used by the default strategy. Keep balance knobs in `numbers.yaml`, migrate 0.35 saves to 0.36 by filling persistent inner force to the old cap, and reuse existing injury/residue recovery paths for bounded inner-breath disorder.

**Tech Stack:** Flutter Desktop, Dart, Riverpod 3, Isar Community, YAML configuration, `flutter_test`.

**Status (2026-07-13 independently rechecked):** Implementation is merged into `main`; fresh full suite 3849 pass / 0 fail and static analysis clean. The earlier 4935 count and branch-handoff note were stale.

---

## Scope and fixed baseline

- **Design source:** `docs/superpowers/specs/2026-07-12-inner-force-qi-cycle-design.md`
- **Execution branch:** `codex/inner-force-qi-cycle`
- **Worktree:** `.worktrees/inner-force-qi-cycle`
- **Initial balance baseline (configurable, not hard-coded in Dart):** base qi 100; ordinary opening qi 40; normal attacks `qiDelta: +20`; power skills `qiDelta: -30`; ultimates `qiDelta: -60`; joint skill `qiDelta: -50`; school event bonus +5; chain-wave recovery 25%; qi cap range 80-140; opening qi cap 80; gain multiplier cap 1.50; cost reduction cap 20%.
- **Persistent inner force:** actual `Character.internalForce` drives damage; `internalForceMax` remains the realm/lineage/level cap; neither is spent in combat.
- **Blood:** remove inner force from the max-HP formula and compensate through realm base HP + constitution coefficient in YAML while preserving the 20,000 hard cap.
- **Failure:** `innerBreathDisorderHoursRemaining` replaces permanent inner-force loss; duration is capped, battle completion subtracts configured hours, retreat/offline recovery subtracts elapsed hours.

## File map

**Create**

- `lib/features/battle/domain/qi_cycle.dart` — pure clamp, skill delta, school bonus, opening/chain recovery, and effective-inner-force calculations.
- `test/features/battle/domain/qi_cycle_test.dart` — boundary and one-trigger-per-action contracts.
- `test/data/inner_force_qi_migration_test.dart` — 0.35 → 0.36 protective migration.

**Modify**

- `data/numbers.yaml`, `lib/data/numbers_config.dart` — qi/disorder/blood-balance configuration and red lines.
- `data/skills.yaml`, `data/encounter_skills.yaml`, `lib/data/defs/skill_def.dart` — explicit `qiDelta`, remove combat dependence on `internalForceCost`.
- `lib/data/defs/technique_def.dart`, selected entries in `data/techniques.yaml` — bounded qi profile hooks for representative heart methods.
- `lib/core/domain/character.dart`, `lib/data/isar_setup.dart` — disorder persistence and save 0.36 migration.
- `lib/features/battle/domain/{battle_state,battle_ai,damage_calculator,derived_stats}.dart` and strategies/setup — resource split, AI gates, damage and HP semantics, chain carry.
- `lib/features/dispel/application/dispel_service.dart`, `lib/features/inner_demon/application/inner_demon_service.dart`, `lib/features/injury`, `lib/features/seclusion/application/seclusion_service.dart` — disorder application/recovery instead of permanent force loss.
- Battle/character/technique/retreat/codex presentation and `lib/shared/strings.dart` — terminology and feedback.
- `GDD.md`, `CLAUDE.md`, `PROGRESS.md` — truth-source synchronization.

## Task 1: Add qi and disorder configuration with pure resolver

**Files:**
- Create: `lib/features/battle/domain/qi_cycle.dart`
- Create: `test/features/battle/domain/qi_cycle_test.dart`
- Modify: `data/numbers.yaml`
- Modify: `lib/data/numbers_config.dart`
- Test: `test/data/game_repository_test.dart`

- [ ] **Step 1: Write failing pure-domain tests**

Add tests for opening qi, positive/negative delta clamping, overflow discard, school bonus once per action, cost-reduction cap, chain recovery, and disorder effective-force multiplier:

```dart
test('opening qi is bounded by max and opening cap', () {
  expect(QiCycle.openingQi(maxQi: 100, openingQi: 40, openingCap: 80), 40);
});

test('normal gain over cap is discarded', () {
  expect(QiCycle.applyDelta(currentQi: 95, maxQi: 100, delta: 20), 100);
});

test('one action receives at most one school bonus', () {
  expect(
    QiCycle.schoolBonus(
      school: TechniqueSchool.lingQiao,
      event: const QiActionEvent(critical: true, dodged: true),
      bonus: 5,
    ),
    5,
  );
});
```

- [ ] **Step 2: Run RED**

Run: `flutter test --no-pub test/features/battle/domain/qi_cycle_test.dart`

Expected: compile failure because `QiCycle`, `QiActionEvent`, and config types do not exist.

- [ ] **Step 3: Add YAML and parsed immutable config**

Add `combat.qi` and `conditions.inner_breath_disorder` sections. Parse them into `QiConfig` and `InnerBreathDisorderConfig`, validate all caps and ratios at load time, and expose them through `NumbersConfig`.

- [ ] **Step 4: Implement the pure resolver**

`QiCycle` must contain no repository, Isar, widget, or random dependencies. Its public API must include `openingQi`, `applyDelta`, `effectiveCost`, `schoolBonus`, `recoverBetweenWaves`, and `effectiveInnerForce`.

- [ ] **Step 5: Run GREEN and repository schema tests**

Run: `flutter test --no-pub test/features/battle/domain/qi_cycle_test.dart test/data/game_repository_test.dart`

Expected: all pass; invalid qi cap fixtures throw `StateError`.

- [ ] **Step 6: Commit**

```bash
git add data/numbers.yaml lib/data/numbers_config.dart \
  lib/features/battle/domain/qi_cycle.dart \
  test/features/battle/domain/qi_cycle_test.dart test/data/game_repository_test.dart
git commit -m "增加真气循环数值模型"
```

## Task 2: Make every skill explicitly generate, spend, or preserve qi

**Files:**
- Modify: `lib/data/defs/skill_def.dart`
- Modify: `data/skills.yaml`
- Modify: `data/encounter_skills.yaml`
- Modify: `lib/data/game_repository.dart`
- Modify: skill fixtures across `test/data` and `test/features`
- Test: `test/data/defs/defs_test.dart`
- Test: `test/data/skill_qi_redline_test.dart`

- [ ] **Step 1: Write RED parser and coverage tests**

Require every production skill to contain an integer `qiDelta`; assert normal attacks are positive, ultimates/joint skills are negative, no delta exceeds configured gain/cost bounds, and at least one zero-delta fixture parses as neutral.

```dart
expect(SkillDef.fromYaml({...base, 'qiDelta': 20}).qiDelta, 20);
expect(() => SkillDef.fromYaml(base), throwsA(isA<TypeError>()));
```

- [ ] **Step 2: Run RED**

Run: `flutter test --no-pub test/data/defs/defs_test.dart test/data/skill_qi_redline_test.dart`

Expected: missing `qiDelta` API and production coverage failures.

- [ ] **Step 3: Replace the definition field**

Replace `SkillDef.internalForceCost` with `qiDelta`. Add derived getters only for presentation and decisions:

```dart
bool get generatesQi => qiDelta > 0;
bool get spendsQi => qiDelta < 0;
int get qiCost => qiDelta < 0 ? -qiDelta : 0;
```

- [ ] **Step 4: Migrate all production skill YAML explicitly**

Write `qiDelta` on every entry: normal +20, power -30, ultimate -60, joint -50 as the initial baseline. Preserve explicit room for neutral skills by allowing zero in schema; do not infer delta from `SkillType` at runtime.

- [ ] **Step 5: Update test fixtures mechanically and run GREEN**

Run: `flutter test --no-pub test/data test/features/cultivation test/features/cangjingge`

Expected: all parser, loadout, codex, and red-line tests pass.

- [ ] **Step 6: Commit**

```bash
git add data/skills.yaml data/encounter_skills.yaml lib/data/defs/skill_def.dart \
  lib/data/game_repository.dart test
git commit -m "显式标记招式产气与耗气"
```

## Task 3: Split battle snapshots into permanent inner force and combat qi

**Files:**
- Modify: `lib/features/battle/domain/battle_state.dart`
- Modify: `lib/features/battle/domain/damage_calculator.dart`
- Modify: `lib/features/battle/domain/derived_stats.dart`
- Modify: `lib/features/battle/application/stage_battle_setup.dart`
- Modify: enemy/mirror setup paths
- Test: `test/combat/battle_state_test.dart`
- Test: `test/combat/damage_calculator_test.dart`
- Test: `test/features/battle/enter_full_internal_force_test.dart` (rename semantics/file if practical)

- [ ] **Step 1: Write RED snapshot tests**

Assert `BattleCharacter.fromCharacter` stores `internalForce == character.internalForce`, creates bounded opening qi from `QiConfig`, and max HP no longer changes when only inner force changes.

- [ ] **Step 2: Run RED**

Run: `flutter test --no-pub test/combat/battle_state_test.dart test/combat/damage_calculator_test.dart test/features/battle/enter_full_internal_force_test.dart`

Expected: missing `internalForce/maxQi/currentQi` fields and old HP assertion mismatch.

- [ ] **Step 3: Replace battle-only fields**

Replace `maxInternalForce/currentInternalForce` with:

```dart
final int internalForce;
final int maxQi;
final int currentQi;
```

Update constructor, `copyWith`, equality/debug output, player setup, enemy setup, inner-demon mirror, light-foot and mass-battle strategies. Do not keep production getters with old names.

- [ ] **Step 4: Decouple damage and HP**

Pass `BattleCharacter.internalForce` into `DamageCalculator`. Remove `c.internalForce * maxHpFormula.internalForceFactor` from `CharacterDerivedStats.maxHp`; replace the YAML formula with realm base HP plus constitution/equipment compensation, preserving the existing 20,000 clamp.

- [ ] **Step 5: Run GREEN and balance probes**

Run: `flutter test --no-pub test/combat test/features/battle/application/stage_battle_setup_test.dart test/balance/full_build_damage_redline_test.dart`

Expected: damage still scales with persistent inner force; spending qi cannot lower subsequent damage; HP remains within red lines.

- [ ] **Step 6: Commit**

```bash
git add lib/features/battle lib/features/inner_demon data/numbers.yaml test/combat test/features/battle test/balance
git commit -m "拆分永久内力与战斗真气"
```

## Task 4: Apply qi deltas, school bonuses, AI gates, and chain recovery

**Files:**
- Modify: `lib/features/battle/domain/battle_ai.dart`
- Modify: `lib/features/battle/domain/strategy/default_ground_strategy.dart`
- Modify: light-foot/mass-battle strategies
- Modify: sweep/tower multi-wave carry paths
- Test: `test/features/battle/domain/qi_combat_loop_test.dart`
- Test: `test/features/battle/domain/battle_ai_test.dart`
- Test: continuous battle tests

- [ ] **Step 1: Write RED combat-loop tests**

Cover opening 40 → normal +20 → ultimate -60, overflow discard, insufficient-qi rejection, no deduction when an action is not executed, one school bonus per action, both attacker/defender gang-meng gain, yin-rou effect gain, ling-qiao critical/dodge gain, and wave recovery/carry.

- [ ] **Step 2: Run RED**

Run: `flutter test --no-pub test/features/battle/domain/qi_combat_loop_test.dart test/features/battle/domain/battle_ai_test.dart`

Expected: AI still reads inner-force cost and strategy still spends current inner force.

- [ ] **Step 3: Gate AI on qi without breaking tactics**

Use `skill.qiCost <= actor.currentQi` in `_canUse`. Keep manual request, interrupt, heal/control, boss phase, and target-selection precedence. Near cap, prefer a usable spender only inside the existing normal power-skill tier; never override interrupt or other tactical policies solely to clear qi.

- [ ] **Step 4: Apply one action-level qi resolution**

After targets resolve, calculate base `skill.qiDelta` plus at most one actor school bonus and at most one defender school bonus per affected defender action. Clamp through `QiCycle.applyDelta`; write `currentQi` once for the actor and once per eligible defender.

- [ ] **Step 5: Carry and recover between waves**

Ordinary stage setup uses configured partial opening qi. Multi-wave/sweep/tower continuation takes the previous `currentQi`, clamps it to the next snapshot max, then applies the configured 25% recovery once per completed wave.

- [ ] **Step 6: Run GREEN and determinism tests**

Run: `flutter test --no-pub test/features/battle test/features/sweep test/features/tower`

Expected: all pass; identical seed/action sequences produce identical qi and outcomes.

- [ ] **Step 7: Commit**

```bash
git add lib/features/battle lib/features/sweep lib/features/tower test/features/battle test/features/sweep test/features/tower
git commit -m "接入招式运气与流派产气循环"
```

## Task 5: Add bounded heart-method qi profiles

**Files:**
- Modify: `lib/data/defs/technique_def.dart`
- Modify: `data/techniques.yaml`
- Modify: `lib/features/battle/domain/battle_state.dart`
- Test: `test/data/technique_qi_profile_test.dart`
- Test: `test/features/battle/technique_qi_profile_wire_test.dart`

- [ ] **Step 1: Write RED profile tests**

Add optional `qiProfile` with `maxBonus`, `openingBonus`, `gainPct`, and `costReductionPct`; test defaults, configured parsing, caps, and player snapshot wiring.

- [ ] **Step 2: Run RED**

Run: `flutter test --no-pub test/data/technique_qi_profile_test.dart test/features/battle/technique_qi_profile_wire_test.dart`

Expected: missing profile model and no battle wiring.

- [ ] **Step 3: Add the bounded profile type**

Clamp final max qi to 80-140, opening qi to 80, gain multiplier to 1.50, and cost reduction to 20%. Profile values are immutable YAML data and never persisted separately.

- [ ] **Step 4: Configure representative production heart methods**

Give at least one heart method per school a distinct bounded profile: gang-meng opening bonus, yin-rou gain bonus, ling-qiao modest max-qi bonus. Leave all unspecified methods at zero profile for zero regression.

- [ ] **Step 5: Run GREEN and commit**

Run: `flutter test --no-pub test/data/technique_qi_profile_test.dart test/features/battle/technique_qi_profile_wire_test.dart test/data/game_repository_test.dart`

```bash
git add lib/data/defs/technique_def.dart data/techniques.yaml lib/features/battle/domain/battle_state.dart test
git commit -m "增加心法真气循环差异"
```

## Task 6: Protect persistent inner force and migrate saves to 0.36

**Files:**
- Modify: `lib/core/domain/character.dart`
- Modify: `lib/data/isar_setup.dart`
- Create: `test/data/inner_force_qi_migration_test.dart`
- Modify: `lib/features/dispel/application/dispel_service.dart`
- Modify: `lib/features/inner_demon/application/inner_demon_service.dart`
- Modify: battle-resolution callers
- Test: dispel/inner-demon/battle-resolution suites

- [ ] **Step 1: Write RED migration and penalty tests**

Seed 0.35 saves with `internalForce < internalForceMax`, reopen, and assert 0.36 sets actual force to the cap and initializes disorder safely. Assert dispel, boss defeat, and inner-demon failure leave actual force unchanged and apply capped disorder instead.

- [ ] **Step 2: Run RED**

Run: `flutter test --no-pub -j1 test/data/inner_force_qi_migration_test.dart test/features/inner_demon test/features/dispel`

Expected: version is 0.35 and penalties still reduce `Character.internalForce`.

- [ ] **Step 3: Add persistent disorder and migration**

Add `double innerBreathDisorderHoursRemaining = 0`. Bump save version to `0.36.0`; for every old character set `internalForce = internalForceMax`, migrate any remaining inner-demon residue to `max(disorder, residue)`, then clear the old residue compatibility field after consumers move.

- [ ] **Step 4: Replace permanent-force penalties**

Dispel, boss defeat, and inner-demon failure add/refresh configured disorder duration up to the cap. Preserve existing cultivation-progress penalties unless the approved design explicitly replaced only the inner-force component.

- [ ] **Step 5: Run build runner and GREEN**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test --no-pub -j1 test/data/inner_force_qi_migration_test.dart test/features/dispel test/features/inner_demon test/features/battle/application
```

Expected: migration is idempotent; repeated penalties never exceed the disorder cap.

- [ ] **Step 6: Commit**

```bash
git add lib/core/domain/character.dart lib/data/isar_setup.dart lib/features/dispel \
  lib/features/inner_demon lib/features/battle/application test/data test/features
git commit -m "保护永久内力并迁移内息紊乱"
```

## Task 7: Recover disorder through battle, retreat, and offline time

**Files:**
- Modify: battle resolution service
- Modify: `lib/features/seclusion/application/seclusion_service.dart`
- Modify: offline presence/settlement path
- Modify: item-use/status paths that reference inner-demon residue
- Test: `test/features/battle/application/inner_breath_disorder_recovery_test.dart`
- Test: `test/features/seclusion/inner_breath_disorder_recovery_test.dart`
- Test: offline settlement tests

- [ ] **Step 1: Write RED recovery tests**

Assert a completed valid battle subtracts configured recovery hours, immediate exit does not, retreat and ordinary offline settlement subtract real elapsed hours, inner force can continue growing while disorder recovers, and multi-wave failure applies a penalty only once.

- [ ] **Step 2: Run RED**

Run: `flutter test --no-pub test/features/battle/application/inner_breath_disorder_recovery_test.dart test/features/seclusion/inner_breath_disorder_recovery_test.dart`

- [ ] **Step 3: Implement shared recovery helper and wire callers**

Use one pure clamp helper for `max(0, remaining - recoveredHours)`. Battle recovery occurs only after a resolved win/loss with at least one action; retreat/offline recovery uses the same elapsed interval already settled for rewards, never a second clock.

- [ ] **Step 4: Run GREEN and commit**

Run: `flutter test --no-pub test/features/battle/application test/features/seclusion test/features/inventory`

```bash
git add lib/features/battle/application lib/features/seclusion lib/features/inventory test/features
git commit -m "接入内息紊乱双通道恢复"
```

## Task 8: Update battle, character, heart-method, retreat, and codex presentation

**Files:**
- Modify: `lib/shared/strings.dart`
- Modify: battle avatar/bottom bar/skill popup/log presentation
- Modify: character panels and status views
- Modify: technique panels
- Modify: retreat preview/result
- Modify: codex entries/data
- Test: related widget tests at 1280×720 and 1440×900

- [ ] **Step 1: Write RED widget/text tests**

Assert battle shows `真气`, skill tiles show `产气 +N` / `耗气 N` / `中性`, character panel shows actual/cap inner force, retreat shows only inner-force growth, and disorder shows actual/effective values and both recovery routes.

- [ ] **Step 2: Run RED**

Run: `flutter test --no-pub test/features/battle/presentation test/features/character_panel test/features/cangjingge test/features/seclusion/presentation`

- [ ] **Step 3: Implement terminology and restrained feedback**

Rename production labels and accessibility semantics; replace blue inner-force bar semantics with qi while keeping the restrained ink-wash palette. Show small signed qi feedback through existing popup infrastructure; do not add a new screen.

- [ ] **Step 4: Update codex and help content**

Add separate inner-force and qi explanations in approved narrative/data sinks; keep Chinese copy out of ordinary Dart production files except `UiStrings`/approved localization sinks.

- [ ] **Step 5: Run GREEN and commit**

Run: `flutter test --no-pub test/features/battle/presentation test/features/character_panel test/features/cangjingge test/features/seclusion/presentation test/features/baike`

```bash
git add lib/shared lib/features data/narratives data/lore test/features
git commit -m "统一内力与真气界面语义"
```

## Task 9: Balance, truth sources, full verification, and READY

**Files:**
- Modify: `GDD.md`
- Modify: `CLAUDE.md`
- Modify: `PROGRESS.md`
- Modify: this plan recovery point

- [ ] **Step 1: Run focused simulations and red lines**

Run balance simulator, full-build damage/HP red lines, representative Ch1/Ch6/inner-demon fights, and deterministic seed suites. Adjust YAML only until no infinite qi loop, survival cliff, or red-line breach remains.

- [ ] **Step 2: Synchronize truth sources**

Document permanent inner force, combat qi, school loops, heart-method profiles, disorder, 0.36 migration, and removal of inner force from HP. Remove production statements that still say skills spend inner force.

- [ ] **Step 3: Static and full test gate**

Run:

```bash
dart format lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build macos --debug --no-pub
git diff --check
```

Expected: zero analysis errors, zero test failures, successful macOS build, clean whitespace.

- [ ] **Step 4: macOS visual smoke**

Capture battle, character detail, heart-method detail, retreat result, and disorder status at 1280×720 and 1440×900. Verify no overflow, correct terms, focus/keyboard behavior, and visible qi generation/spending.

- [ ] **Step 5: Update recovery point and commit**

```bash
git add GDD.md CLAUDE.md PROGRESS.md docs/superpowers/plans/2026-07-12-inner-force-qi-cycle.md
git commit -m "[GDD] 同步内力与真气循环"
git commit --allow-empty -m "[READY] 完成内力与真气系统拆分"
```

## Current recovery point

- **Status:** Plan written; implementation not started.
- **Last completed:** Approved design committed at `e07c8b7e` on `codex/inner-force-qi-cycle-design`.
- **Next step:** Commit this plan, create `.worktrees/inner-force-qi-cycle` on `codex/inner-force-qi-cycle`, then execute Task 1 RED tests.
- **Verification run:** Design/spec and plan self-review only; no implementation tests yet.
- **Blockers:** None.
