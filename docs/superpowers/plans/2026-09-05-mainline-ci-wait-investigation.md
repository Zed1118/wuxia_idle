# Mainline CI wait investigation

- Authorization: initial local investigation was followed by explicit user approval to review, commit and integrate this patch, then execute frozen-version Black Wind Ridge desktop acceptance (2026-09-05 voice session).
- Branch: `codex/mainline-ci-wait-investigation-20260905`, baseline `58ae40bb`.
- Scope: test-wait hardening review and main integration, followed by M2 three-row desktop evidence on one unchanged production package. One integration full suite and push-triggered CI are authorized as necessary integration verification; no CI rerun/cancellation, production rule changes, or original-save writes.
- Budget: 30 minutes; one test-reliability gate. Formal M0–M9 remains 1/10.
- Acceptance: preserve real StageListScreen → stage flow → Isar → battle host and exact participant assertions; use controlled delayed I/O to demonstrate the wait failure and correction; verify cleanup and adjacent tests; analyze changed scope.
- Steps: inspect entry/cleanup; establish targeted baseline; controlled-delay experiment; smallest justified correction; verify and record limitations.
- Current checkpoint: integration review complete. Delayed fixture now starts the real-zone timer at loader invocation so slow bootstrap cannot consume the intended delay. Restoring the old wait yields exactly one failure, restored final test file 6/6 PASS. Contract ledger prepared; awaiting committed-candidate integration checks. Formal M0–M9 remains 1/10.

## Findings and evidence

- Remote failure: run `33950577057`, attempt 1, test job `101264449295`, missing `Phase0aMainlineBattleHost` plus ten-minute timeout. Attempt 2 passed. Four-document diff does not exonerate pre-existing production races or prove identical runtime environments.
- Local baseline: original file 4/4 PASS. Fresh-worktree offline dependency resolution and code generation completed before testing.
- Controlled counterexample: real-time one-second delay before the existing repository runtime-binding loader completes; the old 120-pump wait failed to find `Phase0aBattleScreen`, 0 PASS / 1 FAIL, and exited normally. This demonstrates the wait algorithm's false-negative susceptibility in the host's loading phase, **not** reproduction of the remote missing-host failure or its ten-minute hang. A database-lock experiment was stopped after blocking and excluded as root-cause evidence.
- Correction: use a five-second wall-clock deadline with real event-loop waits, retain exact participant and real production-loader assertions, preserve ordinary and delayed entry cases, and always unmount the widget tree even if host lookup or pop cleanup fails. Pop settling is separately bounded. No production code, numerical rules, saves, or workflow changes.
- Final verification: current file 6/6, adjacent all-mode consistency 6/6, stage-entry flow 10/10; targeted analyzer 0 issues; format and diff-check pass. The 6 tests include an always-missing-widget timeout case. No full suite or GUI/Windows acceptance rerun.
- Evidence directory: `/Users/a10506/Documents/Codex/2026-09-05/mainline-ci-wait/`; retained baseline, controlled RED, final, adjacent, entry-flow and analyze logs. RED file is `wuxia-mainline-ci-red-real-20260905.log`.
- Remaining boundary: remote root cause remains open; local patch is not a CI stability sign-off. Original report-only restrictions were superseded only for the explicitly authorized integration and isolated desktop acceptance. Never use this test fix to promote a milestone.

## Authorized integration and M2 desktop continuation

- Single primary gate: `P2-M2-HUMAN-G2-ACCEPTANCE`, formal 0/1; overall 1/10. Test integration is a prerequisite, not milestone progress.
- Observable budget: first checkpoint after 60 minutes of this continuation; only ongoing CI wait may extend without new implementation.
- Desktop denominator: the existing three M2 rows (stage_01_03 continuous controls; stage_01_05 Boss response/failure retry/victory; return/continue/state preservation). Each begins NOT_RUN for this frozen version. AI evidence cannot replace natural-person control-feel, audio, or Windows sign-off.
- Integration sequence: exact diff review and test-contract gate; committed candidate full regression under shared exclusive lock, analyzer and format; no-ff merge into unchanged clean main; push and inspect exact-SHA CI. Do not mutate the candidate during the suite.
- Desktop sequence: verify existing frozen package production equivalence and AOT, use isolated application/save copy, capture native dimensions and evidence files, execute manual controls from production menus, record results and remaining gaps. No unrelated weapons/tower content implementation.
