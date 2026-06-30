# UI night codex archives polish

## Goal

Polish the clearest encyclopedia/catalog slice for better button affordance, list density, wide desktop layout, and detail readability.

## Branch

`codex/ui-night-codex-archives-polish`

## Acceptance

- Keep production paths wired through existing screens: `MartialArtsTab`, `WeaponCodexScreen`, `EquipmentCatalogDetailScreen`.
- Stay in presentation-layer UI changes; do not touch `data/`, save schema, unlock/discovery, equipment stats, or combat logic.
- Do not add scattered runtime text; reuse `UiStrings`.
- Run `flutter analyze`, the requested targeted widget tests, and `git diff --check`.
- Finish with a clean worktree and a tip commit prefixed `[READY]`, or `[BLOCKED]` if blocked.

## Slices

1. Confirm target worktree and branch.
2. Read relevant UI files/tests and project guardrails.
3. Apply small visual polish to archive/codex presentation widgets.
4. Run requested verification.
5. Commit and report status.

## Recovery Point

- Status: ready to commit.
- Last completed: presentation-only UI polish is limited to three files: martial arts chips and weapon catalog list/detail.
- Next step: stage the three presentation files plus this recovery plan, then commit with `[READY]`.
- Verification run: `flutter analyze` passed after temporary `build_runner` generation; requested targeted widget test command passed 55 tests; `git diff --check` passed.
- Blockers: none.
