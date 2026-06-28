# Long Balance Audit Plan (2026-06-28)

## Goal

Execute the first read-only long-term balance audit for drops, silver, forging materials, technique training, passive/offline income, endgame extremum builds, and New Game+ rewards.

The audit should identify whether long-term rewards feel visible without drifting into million-scale inflation, and whether any resource has orphaned supply, oversupply, or drought risk.

## Branch

`codex/long-balance-audit`

## Acceptance Criteria

- Read required context: `AGENTS.md`, `CLAUDE.md` §5/§7/§8.0, `GDD.md` §5/§9, and `docs/spec/playability_phase2_backlog.md` §十二.
- Do not tune `data/numbers.yaml` or other balance data in this pass.
- Prefer existing balance/tool tests or read-only diagnostics over impression-based conclusions.
- Produce `docs/audit/long_balance_audit_2026-06-28.md`.
- The report includes data sources, commands/tests run, finding severity, suggested task slices, and user decision items.
- Commit in small slices; do not merge, push, or modify `main`.

## Task Slices

1. Create the audit branch and this recoverable plan.
2. Inventory existing tests, configs, and services relevant to economy, drops, offline income, techniques, endgame builds, and cycle rewards.
3. Run targeted balance/tool tests and any existing read-only diagnostics.
4. Inspect configuration and test evidence for long-term resource flow risks.
5. Write the audit report with severity, evidence, and user decision items.
6. Update this plan's recovery point and commit the completed audit.

## Current Recovery Point

- Status: plan created; audit not yet run.
- Last completed: required context read and branch `codex/long-balance-audit` created from `b2bc6066`.
- Next step: inventory relevant tests/configs/services, then run targeted validation.
- Validation run: none yet.
- Blockers: none.
