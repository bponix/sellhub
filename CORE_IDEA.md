# SellHub Core Idea

## One-Line Idea

SellHub should feel like the fastest path from store discovery to completed order for any Bponi-powered shop.

## Product Thesis

The app exists to solve one problem well:

make mobile commerce inside the Bponi ecosystem clear, trustworthy, and conversion-friendly.

That means a customer should be able to:

- enter the right store quickly
- understand what the store offers immediately
- find products without friction
- buy with confidence
- return later without losing context

## What SellHub Is

SellHub is:

- a multi-store customer commerce app
- a store-context-aware browsing shell
- a product discovery and conversion app
- an order continuity app
- a notification-aware and deep-link-aware mobile client

## What SellHub Is Not

SellHub is not:

- a generic ecommerce UI playground
- a back-office operations app
- a copy of Suite HR or staff workflows
- a place for non-commerce feature sprawl

If a feature does not improve discovery, trust, conversion, order continuity, or retention, it should be questioned before it is added.

## Core User Journey

The core journey should remain:

`Select store -> Browse home -> Search or open category -> Open product -> Add to cart -> Checkout -> Order success -> Re-enter from profile, orders, or notifications`

Every screen in SellHub should support or shorten that journey.

## Product Pillars

### 1. Store-first clarity

- entering the wrong store should be hard
- active-store context should be obvious
- store switching should be fast and reversible

### 2. Fast discovery

- home must surface useful categories, offers, brands, and product rails
- category and search should reduce effort, not add steps
- product cards should stay dense, readable, and scannable

### 3. Frictionless conversion

- the app should make buying feel low-risk and obvious
- cart and checkout should remove hesitation
- primary buying actions must stay visible and stable

### 4. Order continuity

- returning users should recover context quickly
- order status should feel connected to the shopping flow, not bolted on
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

- discovery
- storefront
- categories
- search
- product
- favourite
- cart
- checkout
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

- the end-to-end customer flow still works
- touched files are analyzer-clean
- route behavior stays stable
- loading, empty, error, and retry states remain explainable
- the change improves commerce clarity instead of adding UI weight
- the feature stays inside the product boundary

## Decision Filter

Before shipping work in SellHub, ask:

1. Does this make discovery, trust, conversion, order continuity, or retention better?
2. Does it follow the shared architecture style instead of adding a one-off pattern?
3. Is it clearly commerce-relevant?
4. Does it keep the app compact and predictable?

If the answer is weak, narrow the work before building it.

