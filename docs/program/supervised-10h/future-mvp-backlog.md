# Future MVP Backlog

This backlog captures the remaining MVP-critical work for SellHub after the
current supervised waves. It is intentionally focused on reseller utility,
Bangladesh-first operating realities, and backend truth. SLA-specific work is
excluded from this list.

## Must Ship Before Beta

1. True quick-order flow
- buyer name
- phone
- area
- address
- quantity
- sell price
- COD or advance
- under-30-second path from product to confirmed order draft

2. Buyer risk and COD risk scoring
- clear `Safe`, `Caution`, `Risky` states
- return history
- unreachable buyer pattern
- failed-order pattern
- COD reliability

3. Bangladesh delivery confidence
- inside/outside Dhaka behavior
- risky area warning
- likely delivery time
- COD caution
- move current partial local model toward real truth

4. Social-ready share assets
- WhatsApp-first share card
- Facebook caption copy
- Bangla + English product pitch
- buyer total + delivery + CTA

5. Basic reseller dashboard metrics
- active orders
- today’s confirmed buyers
- expected payout
- top saved product
- repeat buyer prompts

6. Real onboarding for first-time resellers
- first-sale setup flow
- name
- area
- payout method
- selling channel
- preferred categories

## Creative Differentiators

These are not vanity features. They are product differentiators that fit the BD reseller market.

1. `Neighbourhood selling mode`
- buyers grouped by area/community
- local repeat-sell prompts
- lane-based follow-up

2. `Chat-to-order mode`
- turn a chat-confirmed sale into a supplier-backed draft with minimal typing

3. `Trust-led quote variants`
- buyer-friendly Bangla
- trust-first follow-up
- platform-specific copy

4. `Supplier leg truth`
- every split order should feel explainable
- who is fulfilling what
- what delivery lane applies
- what payout outcome depends on that leg

## Must Ship Before MVP Launch

7. Real multivendor order routing
- split mixed-supplier orders for real
- track supplier-specific order legs
- show payout implications per supplier order

8. Payout trust end-to-end
- exact payout eligible date
- batch inclusion status
- blocked reason
- released reason
- dispute lifecycle backed by real data

9. Backend-backed buyer book and payout data
- move critical payout, dispute, buyer-risk, and quote flows off local-only simulation

10. Richer supplier trust profile
- fulfillment rate
- return rate
- average delivery time
- payout consistency
- supplier quality visibility before sell decision

11. Repeat-sell engine completion
- sell-again suggestions
- reorder same item to previous buyer
- likely repeat buyers this week
- saved neighborhood/community segments

12. Support and dispute workflow
- supplier problem report
- payout mismatch report
- buyer fraud report
- issue resolution state

## Post-Launch Hardening

13. Backend hardening vs local seed dependence
- quotes
- payout disputes
- payout batches
- buyer risk/history
- team selling logic
- clear local-first dev mode vs backend truth mode boundaries
