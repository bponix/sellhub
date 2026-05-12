# First-Wave Implementation Roadmap

## CEO Direction

SellHub should now be run as a reseller operating system, not a renamed storefront.

The product order is:
1. close first sale faster
2. reduce buyer/COD risk
3. make supplier and delivery truth visible
4. make payout timing trustworthy
5. increase repeat selling

See `ceo-product-memo.md` and `automation-operator-spec.md` for operating rules.

## Decision
Start with local reseller workflow contracts and the highest-frequency BD reseller loop:

1. quick order draft
2. buyer risk profile
3. supplier order-group draft
4. share asset draft
5. selling-list and checkout/payment screens consuming those contracts

Reason:
- the app already has a local-first platform
- the largest current gap is workflow state, not storage plumbing
- this unlocks faster iteration across home, product detail, selling list, checkout, and payout trust

## Wave 1 Scope

### Platform
- add reseller-first local collections
- add local store methods and seed data
- expose repository contracts for quick-order and buyer-risk flows

### Selling Flow
- selling list becomes social-selling-first
- checkout becomes resumable quick-order setup
- payment gains order-group and buyer-risk context

### Product Decision Layer
- product detail and cards show margin/risk/trust/shareability more clearly

## Not In Wave 1
- full sync journal
- advanced offline mutation replay
- large category/search facet refactor
- full delivery-zone intelligence UI

## Exit Criteria
- local contracts exist and are repository-exposed
- checkout draft can be saved/restored
- buyer risk is explicit and carried through checkout/payment
- selling list has stronger share/quote first actions
- product surfaces better expose seller decision signals

## Next Waves

### Wave 4
- payout batch scheduling truth
- reseller cash release timing by order state
- dispute lifecycle visibility

### Wave 5
- true quick-order flow
- buyer risk and COD risk scoring completion
- first-time reseller onboarding
- dashboard metrics for daily operator clarity

### Wave 6
- Bangladesh delivery confidence hardening
- social-ready share assets
- beta gate review

### Wave 7
- real multivendor routing parity
- payout trust end-to-end completion
- backend-backed buyer book and payout truth

### Wave 8
- richer supplier trust profile
- repeat-sell engine completion
- support and dispute workflow
- MVP launch review

## Persona-Based Delivery Tracks

### Track A: Student Reseller
- one-tap quick order
- buyer risk clarity
- payout timing confidence

### Track B: Housewife / Neighbourhood Seller
- easy onboarding
- repeat buyers
- delivery confidence
- simple support flow

### Track C: Facebook / WhatsApp Page Seller
- stronger share assets
- supplier trust
- split-order truth

### Post-Launch Hardening
- backend hardening away from local-seed-only simulation
