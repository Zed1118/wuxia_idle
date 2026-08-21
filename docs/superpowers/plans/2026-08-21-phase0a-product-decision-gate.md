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
- [ ] Record the user's decisions in the decision sheet.
- [ ] Slice the approved implementation without changing unrelated balance.

## Recovery point

The current implementation was inspected at main `699f61a8`. No Dart, YAML,
save, schema, formula, or balance change has been made. The decision sheet is
ready for human review; implementation remains blocked on the four choices.

