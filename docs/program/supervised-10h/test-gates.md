# Test Gates

## Gate 1 Architecture
- local-first reads must have a clear repository path
- no parallel shadow architecture without migration notes
- new local collections must be documented

## Gate 2 Compile
- no compile errors
- targeted `flutter analyze` must pass on touched files

## Gate 3 Runtime
- no new render overflows
- no broken primary navigation routes
- no silent action failures on checkout/order/payout flows

## Gate 4 Workflow
- browse -> detail -> price -> selling list -> checkout -> payment -> order
- buyer reuse from Buyer Book
- payout row visibility after delivered order

## Gate 5 Resume
- handoff file updated
- review log updated
- next checkpoint written in `resume-point.md`
