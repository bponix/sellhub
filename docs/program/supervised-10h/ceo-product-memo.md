# SellHub CEO Product Memo

## Product Truth

SellHub is not a shopper app and not a generic multivendor marketplace.
SellHub is the operating system for a no-stock reseller in Bangladesh.

The core user is:
- a student
- a housewife
- a side-income seller
- a Facebook page admin
- a WhatsApp seller
- a neighbourhood/community reseller

They do not want catalog complexity.
They want a reliable path to:
1. find something easy to sell
2. share it fast
3. quote a buyer confidently
4. avoid fake or risky buyers
5. place a supplier-backed order
6. track delivery and payout
7. sell again to the same buyer

## CEO Standard

Every feature should answer one of these questions:
- does this help the reseller close the first sale faster?
- does this reduce COD or buyer risk?
- does this make supplier execution more visible?
- does this increase payout trust?
- does this make repeat selling easier?

If the answer is no, it is probably noise.

The product should feel obvious without needing long instructions.
If a screen needs a paragraph to explain itself, the product design is probably weak.
Prefer:
- direct primary actions
- default-safe choices
- compact copy
- visible next step
- fewer decisions per screen

Avoid:
- manual-like helper text
- long empty-state explanations
- repeated educational banners
- stacked cards that explain the same thing twice

## Primary Personas

### 1. Student Reseller
- low cash
- fast mobile use
- sells through WhatsApp/Messenger
- needs quick quote and quick order
- highly sensitive to failed COD and payout delays

### 2. Housewife Reseller
- sells to neighbours, family circles, local groups
- needs easy UI, low cognitive load, trust-heavy flow
- cares about repeat buyers and stable delivery
- needs Bangla-friendly buyer and order handling

### 3. Side-Income Page Seller
- runs Facebook page or inbox selling
- needs better share assets, better buyer triage, and supplier clarity
- cares about margin, tracking, and issue handling

## North-Star Jobs

1. `Start selling in under 3 minutes`
2. `Turn a chat into a supplier-backed order in under 30 seconds`
3. `Know whether a buyer or delivery lane is safe before confirming COD`
4. `Understand when money becomes payable and why`
5. `Sell again to previous buyers without redoing the whole process`

## Product Loop

`Find -> Share -> Quote -> Confirm buyer -> Place supplier order -> Track delivery -> Get payout -> Repeat sell`

Every route should strengthen this loop.
Every route should also preserve context into the next route so the reseller does not have to reconstruct the flow mentally.

## Route Roles

### Home
- daily reseller desk
- what to sell today
- what buyer/order/payout task needs action now

### Search / Category
- find products to sell, not products to browse
- margin, risk, trust, COD suitability

### Product Detail
- answer `Can I sell this now?`
- should show shareability, safe price, supplier quality

### Selling List
- active shortlist to sell
- should feel like a conversion workspace, not a cart

### Checkout / Payment
- fast buyer-confirmation workflow
- should reduce error and speed up order creation

### Orders
- active task queue
- supplier truth, support truth, payout truth

### Buyer Book
- repeat-sell engine

### Network Effect Layer
- the app should get stronger as the reseller builds:
  - repeat buyers
  - neighborhood clusters
  - product winners
  - supplier trust history
  - referral loops
- good product direction:
  - make prior buyer data reusable
  - make local demand visible
  - make winning products reusable across buyers
  - make supplier trust compound over time

### Payouts
- cash confidence

## Automation Standard

Automation runs must behave like a product operator, not a lint bot.

Each run should:
1. choose one clear reseller outcome
2. finish one real feature slice
3. validate it
4. record what changed and what user pain it removed

Bad run:
- changes five files but no real workflow improves

Good run:
- one user-facing feature becomes actually usable end-to-end
- the feature becomes more obvious and needs less explanatory text than before

## Priority Order

1. first-sale speed
2. buyer/COD trust
3. delivery/supplier truth
4. payout trust
5. repeat-sell power
6. support resolution
7. local network effects and referral loops
