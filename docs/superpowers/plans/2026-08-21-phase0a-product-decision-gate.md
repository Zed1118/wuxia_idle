# Phase 0A product decision gate

## Goal

Turn the Ch1 founder-skill and Q/R behavior debt into a decision-ready package
before any further combat migration. This batch is documentation-only until the
human choices are recorded.

Branch: `codex/phase0a-product-decisions-0821`

## Acceptance checklist

- [x] Reconcile the latest audit, `docs/sessions/NEXT.md`, the Ch1 profile, and
      the frozen greybox contract.
- [x] Separate current facts from product choices.
- [x] Give one recommended option for each blocking choice and spell out its
      implementation impact.
- [x] Record the user's decisions in the decision sheet.
- [ ] Slice the approved implementation without changing unrelated balance.

## Recovery point

The current implementation was inspected at main `699f61a8`. The user approved
D1-A / D2-A / D3-A / D4-A. The first implementation slice is restricted to
making the three founder techniques' power skills available at `chuKui` without
raising founder cultivation, changing the global ultimate threshold, or tuning
enemy values. The typed behavior slice remains separate.
