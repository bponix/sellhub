# Fixed Scopes

## Master
- integration decisions
- sequence and priority
- review and test gates
- final consolidation

## A1 Local Platform
- `lib/core/api`
- `lib/core/database`
- `lib/core/local_seed`
- `lib/injection_container.dart`
- local-first architecture contracts

## A2 Discovery Home
- `lib/features/product/screens/home_screen.dart`
- `lib/features/product/screens/widget/allPartHomePage.dart`
- home reseller workflow

## A3 Search + Categories
- `lib/features/search/**`
- `lib/features/categories/**`
- intent-led product discovery

## A4 Product Detail + Cards
- `lib/features/product/screens/product_details_screen.dart`
- `lib/features/product/screens/widget/product_list_*`
- seller decision surfaces

## A5 Selling List + Quote
- `lib/features/cart/screens/cart_screen.dart`
- `lib/features/cart/screens/quote_preview_screen.dart`
- shortlisting and share flow

## A6 Checkout + Payment
- `lib/features/cart/screens/checkout_screen.dart`
- `lib/features/cart/screens/payment_screen.dart`
- quick-order and multivendor execution

## A7 Orders + Fulfillment
- `lib/features/orders/**`
- order queue, detail, and support flow

## A8 Buyer Book + Repeat Sell
- `lib/features/profile/screens/buyer_book_screen.dart`
- buyer risk, repeat-sell, and reuse flow

## A9 Payouts + Trust
- `lib/features/profile/screens/payout_ledger_screen.dart`
- payout promise and dispute flow

## A10 Profile + Settings + Shell
- `lib/features/profile/screens/profile_screen.dart`
- `lib/features/settings/**`
- shell-level operator clarity

## A11 Data Models + Repositories
- cross-feature repository contracts
- local/remote parity
- BD reseller business rules

## A12 QA + Test Gates
- analyzer gates
- overflow/runtime review
- manual flow checklist
