# Automation Operator Spec

This file defines how the SellHub heartbeat should behave.

## Rule 1: One finished feature per run

A run must complete one bounded feature or subfeature end-to-end.

Acceptable examples:
- restore quick-order operational selections
- turn buyer risk into a checkout decision card
- add a real order issue reporting flow
- expose supplier legs on split-order completion

Unacceptable examples:
- touch home, checkout, and payouts lightly with no real outcome
- rename labels only
- write planning text without implementation
- stop after partial plumbing

## Rule 2: Choose by reseller pain, not by code convenience

Pick the next feature based on:
1. what removes fear
2. what reduces time to sell
3. what increases trust
4. what increases repeat sales
5. what compounds value as buyer, supplier, and neighborhood history grows

Do not choose work because it is easy to patch.

## Rule 3: Feature slices must be vertical

A slice should be complete enough that a reseller can feel the difference.

Good vertical slice:
- entry point
- logic/state
- visible UI
- validation
- checkpoint update

The UI should become more direct after the slice, not more narrated.

## Rule 4: Prefer Bangladesh-first simplicity

Default assumptions:
- mobile-only use
- low patience
- chat-first sales
- COD-sensitive flow
- mixed Bangla/English mental model
- limited technical confidence

The benchmark is not “well explained.”
The benchmark is “obvious enough to use without reading a manual.”

Prefer:
- one strong CTA
- short labels
- self-evident sequence
- preserved context between screens

Avoid:
- extra explainer cards
- repeated how-it-works text inside core flows
- duplicate summaries that slow the user down

## Rule 5: Stop condition

The run is complete only when:
- the chosen feature works coherently across required files
- the relevant analyzer/test gate passed
- `review-log.md` is updated
- `resume-point.md` is updated

## Rule 6: If blocked, narrow safely

If the planned feature is too large:
- narrow to one user-meaningful slice
- finish that slice fully
- leave a precise next step in `resume-point.md`

## Rule 7: Prefer contiguous flows

Choose slices that connect steps together:
- buyer book -> selling list -> checkout
- product detail -> share -> quote
- order detail -> payout truth -> support action

A good run reduces context switching and repeated input.

## Rule 8: Prefer network effects

Look for features that get better as usage grows:
- repeat buyer reuse
- neighborhood demand clustering
- referral capture
- supplier trust accumulation
- saved winning products
- buyer-to-buyer resell patterns

Prefer compounding systems over isolated widgets.

## Current strategic order

### Beta completion
1. first-sale onboarding
2. quick-order speed
3. buyer/COD decisioning
4. delivery confidence
5. social-ready share
6. reseller dashboard

### MVP launch preparation
1. multivendor routing truth
2. payout truth with real release logic
3. backend-backed buyer/payout truth
4. richer supplier trust
5. repeat-sell completion
6. support/dispute workflow
7. network-effect loops

## Required docs to read before each run

- `ceo-product-memo.md`
- `future-mvp-backlog.md`
- `implementation-roadmap.md`
- `review-log.md`
- `resume-point.md`
- `test-gates.md`
