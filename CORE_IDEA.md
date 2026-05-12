# SellHub Core Idea

## One-Line Idea

SellHub should feel like the fastest way to start and run a business without inventory.

## Product Thesis

The app exists to solve one problem well:

make seller-led commerce inside the Bponi ecosystem instant, trustworthy, and easy to operate from a phone.

That means a seller should be able to:

- pick a product and start selling in minutes
- understand margin and fulfillment responsibility clearly
- share products across social channels without manual setup
- place and track orders without holding stock
- grow from solo selling into repeat, team-based selling

## What SellHub Is

SellHub is:

- a seller-layer mobile app inside the Bponi commerce network
- a supply-to-seller bridge powered by Bponi Store merchants
- a zero-inventory selling shell for individuals and small teams
- a trust and order-routing layer between supplier and buyer
- a notification-aware and deep-link-aware mobile client

## What SellHub Is Not

SellHub is not:

- only a shopper storefront
- a generic ecommerce UI playground
- a back-office operations app
- a place for non-commerce feature sprawl

If a feature does not improve discovery, trust, conversion, order continuity, or retention, it should be questioned before it is added.

## Core User Journey

The core journey should remain:

`Discover supplier products -> Tap Sell this -> Share product -> Capture buyer intent -> Route order -> Track fulfillment -> Re-sell and grow`

Every screen in SellHub should support or shorten that journey.

## Product Pillars

### 1. Zero-friction selling

- product import should feel instant
- seller setup should stay near-zero
- the app should make starting the first sale feel obvious

### 2. Supply and discovery quality

- suppliers and products should be easy to discover
- categories and search should reduce time-to-first-share
- product cards should make value, trust, and margin scannable

### 3. Social-first conversion

- the app should help sellers convert through WhatsApp, Facebook, and similar channels
- primary share and order actions must stay visible and stable
- seller actions should remove operational hesitation, not add setup work

### 4. Fulfillment trust

- supplier reliability should be visible
- order routing and delivery updates should feel connected to the selling flow
- notifications and deep links should reopen the correct route cleanly

### 5. Platform reliability

- startup must be orchestrated and failure-tolerant
- degraded services should not crash the app
- connectivity, notifications, deep links, analytics, and updates are product capabilities, not optional extras

## Source Of Truth

Use these references intentionally:

- `sellhub/`
  Source of truth for business scope and commerce UI implementation.
- `suite/`
  Source of truth for architecture discipline, lifecycle rigor, and shared platform thinking.
- live GraphQL backend
  Source of truth for real contracts and production data shape.

SellHub should inherit the engineering quality bar from Suite without inheriting irrelevant business modules.

## Architecture Direction

SellHub should continue to follow these rules:

- feature-first Flutter structure
- shared `core/` for cross-cutting concerns
- `GetIt` dependency injection
- cubit-owned presentation state
- repository-driven data boundaries
- explicit loading, empty, success, and error states
- central routing and route-safe deep linking

The platform foundation should remain strong in:

- startup orchestration
- active store hydration
- GraphQL client bootstrap
- local storage
- notification center
- local and push notifications
- deep link handling
- app update gating
- crash reporting and analytics

## UX Direction

SellHub should feel:

- compact
- clean
- modern
- stable
- easy to scan
- obvious about what to do next

Visual rules:

- white-first surfaces
- subtle or zero shadow
- outline icons
- compact section spacing
- strong action hierarchy
- no heavy decorative clutter

The interface should look polished, but polish should never come from adding noise or extra decision points.

## Bounded Scope

The valid long-term domains for SellHub are:

- supplier discovery
- seller dashboard
- product import
- pricing and margin
- social sharing
- lead and order capture
- fulfillment tracking
- trust and verification
- team selling
- orders
- profile
- notifications
- settings

Anything outside this list should justify itself in direct commerce terms.

## API And Data Discipline

- use the real backend contract
- do not guess schema shape
- keep GraphQL requests minimal and verified
- prefer repository methods over widget-level data logic
- keep refresh-sensitive flows truly refreshed

## Definition Of Done

A SellHub change is only done when:

- the end-to-end seller flow still works
- touched files are analyzer-clean
- route behavior stays stable
- loading, empty, error, and retry states remain explainable
- the change improves seller speed, trust, or conversion instead of adding UI weight
- the feature stays inside the product boundary

## Decision Filter

Before shipping work in SellHub, ask:

1. Does this make starting, sharing, routing, or scaling sales better?
2. Does it follow the shared architecture style instead of adding a one-off pattern?
3. Is it clearly relevant to the seller-layer vision?
4. Does it keep the app compact and predictable?

If the answer is weak, narrow the work before building it.
