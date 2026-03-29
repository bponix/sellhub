# SellHub

SellHub is Bponi's customer-facing Flutter commerce app. It lets a shopper discover a store, switch into that store context, browse products, search, buy, track orders, and come back through notifications or deep links.

It is not a demo storefront. It is a production mobile shell for real Bponi-powered stores.

## What The App Does

SellHub covers the full customer journey:

- store discovery and store switching
- storefront home, campaign rails, category browsing, and search
- product details, variants, favourites, and related discovery
- cart, checkout, payment selection, and order confirmation
- profile, settings, notifications, and order continuity

The app is designed around one consistent mobile commerce flow:

`Discover store -> Browse -> Search -> Open product -> Add to cart -> Checkout -> Place order -> Return via notifications or deep links`

## Product Position

SellHub sits inside the Bponi ecosystem as the shopper app.

It borrows:

- architecture discipline from `suite/`
- commerce UX direction from the existing Bponi storefront surfaces
- real backend contracts from the live GraphQL API

It intentionally excludes non-commerce business modules. SellHub should stay focused on customer browsing, conversion, account continuity, and retention.

## Current Product Shape

The current app already includes:

- splash and startup orchestration
- active store hydration and recent-store recovery
- store selector and QR-based store activation
- unified storefront preload for home surfaces
- category-led and search-led product discovery
- compact horizontal rails and two-column product grids
- cart, checkout, payment, and success flow
- notification inbox and deep-link-aware route handling
- app update gate, connectivity banner, analytics, and crash reporting

## Architecture Summary

Main entry:

- [main.dart](/Users/dev/prod/sellhub/lib/main.dart)
- [injection_container.dart](/Users/dev/prod/sellhub/lib/injection_container.dart)

Core platform files:

- [app_router.dart](/Users/dev/prod/sellhub/lib/core/utils/app_router.dart)
- [app_environment.dart](/Users/dev/prod/sellhub/lib/core/config/app_environment.dart)
- [app_theme.dart](/Users/dev/prod/sellhub/lib/core/theme/app_theme.dart)

Architecture style:

- Flutter feature-first structure
- `GetIt` dependency injection
- Cubit-owned presentation state
- repository-based data access
- GraphQL as the primary remote contract
- local storage for session, cart, recent store, and notification state

Key runtime capabilities:

- startup step orchestration with degraded-service tracking
- local notifications and push notification sync
- deep-link initialization and consumption
- connectivity state banner
- remote config and app update gating

## Folder Guide

- `lib/core`
  Shared infrastructure: theme, network, local storage, notifications, deep links, app-wide widgets.
- `lib/features/discovery`
  Store selector, QR scanner, and store activation flow.
- `lib/features/storefront`
  Store preload, shell state, home feed data, pagination, and category-wise home sections.
- `lib/features/product`
  Product lists, product details, related items, and shared product card widgets.
- `lib/features/categories`
  Category tree and category product exploration.
- `lib/features/search`
  Search input, search results, and query-driven discovery.
- `lib/features/favourite`
  Saved products and quick re-entry to purchase.
- `lib/features/cart`
  Cart, checkout, payment, and order-complete flow.
- `lib/features/orders`
  Order details and continuity after purchase.
- `lib/features/profile`
  Customer profile and account-level actions.
- `lib/features/notifications`
  In-app notification inbox and notification-driven route recovery.
- `lib/features/settings`
  Device-level customer settings such as notification permission state.
- `lib/features/shell`
  Bottom navigation and shared shell ownership.
- `lib/features/splash`
  Startup route resolution and initial preload handoff.

## Brand And Identity

- app name: `SellHub`
- domain: `sellhub.bponi.com`
- Android application id: `com.bponi.sellhub`
- iOS bundle id: `com.bponi.sellhub`
- Dart package: `sellhub`

Brand text source:

- [app_text.dart](/Users/dev/prod/sellhub/lib/core/config/app_text.dart)

## UX Direction

SellHub should remain:

- white-first
- compact
- low-noise
- mobile-first
- fast to scan
- explicit about next actions

UI principles used across the current codebase:

- subtle borders over heavy shadows
- outline icons
- compact spacing rhythm
- dense but readable product cards
- clear primary actions
- minimal decorative clutter

## Data And Backend Rules

- use the real GraphQL backend at `https://api.bponi.com/x`
- keep selection sets intentional and minimal
- do not silently drift from backend contracts
- keep refresh-sensitive reads network-backed
- keep widget trees free of ad hoc query logic where repository methods already exist

## Local Development

Prerequisites:

- Flutter SDK available at `/Users/dev/flutter/bin/flutter`
- Xcode for iOS/macOS builds
- Android SDK for Android builds

Install:

```bash
flutter pub get
```

Run:

```bash
flutter run
```

Common targets:

```bash
flutter run -d ios
flutter run -d android
flutter run -d chrome
```

Verification:

```bash
flutter analyze
flutter test
```

## Change Standard

For production-safe work in SellHub, keep this minimum bar:

- no analyzer or compile errors in touched files
- no runtime layout assertions on core commerce routes
- no broken store activation, search, cart, checkout, or notification flows
- no unverified GraphQL contract changes
- no changes that blur the app into non-commerce scope

## Related Docs

- product direction and decision filter: [CORE_IDEA.md](/Users/dev/prod/sellhub/CORE_IDEA.md)
- app bootstrap and platform lifecycle: [main.dart](/Users/dev/prod/sellhub/lib/main.dart)

