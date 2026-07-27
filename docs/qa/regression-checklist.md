# Regression Checklist — Barbar App

Run this checklist before every release to ensure core functionality is intact.

## Build & Static Analysis

- [ ] `go build ./...` passes
- [ ] `go vet ./...` passes
- [ ] `go test ./... -count=1 -timeout 60s` passes
- [ ] `flutter analyze` passes (0 new errors)

## Auth

- [ ] Customer signup + OTP verify
- [ ] Customer login + token issued
- [ ] Token expiry returns 401
- [ ] Refresh token rotation works
- [ ] OTP attempt limit enforced (max 5)

## Customer Core Flow

- [ ] Search barbers
- [ ] Book service
- [ ] Cancel booking → refund to wallet
- [ ] View booking history
- [ ] Place product order
- [ ] Write + edit review

## Barber Core Flow

- [ ] Accept booking
- [ ] Reject booking
- [ ] Mark complete
- [ ] Update queue

## Vendor Core Flow

- [ ] Accept order
- [ ] Pack order
- [ ] Ready for pickup
- [ ] Create/edit/delete product
- [ ] Inventory management

## Delivery Core Flow

- [ ] Claim delivery
- [ ] Accept assignment
- [ ] Verify pickup OTP
- [ ] Mark picked up
- [ ] Verify delivery OTP
- [ ] Mark delivered
- [ ] Go online/offline

## Wallet & Payments

- [ ] Wallet credit on delivery complete
- [ ] Wallet deduction on booking
- [ ] Wallet refund on cancellation
- [ ] Withdrawal request created
- [ ] Admin approves withdrawal
- [ ] Admin processes withdrawal (UTR)
- [ ] Frozen wallet blocks credit/debit

## Admin Core Flow

- [ ] Dashboard loads
- [ ] Orders list + detail
- [ ] Assign driver to order
- [ ] Approve/reject vendor
- [ ] Approve/reject delivery partner
- [ ] Manage banners (CRUD)
- [ ] Manage coupons (CRUD)

## Known Bug Regression Tests

- [ ] B1: CMS list works without `type` param
- [ ] B2: `final_amount` has no floating-point precision issue
- [ ] B4: Wallet transactions exist for completed bookings
- [ ] B8: Admin cancel booking with valid payload works
- [ ] B13: Order status "processing" does not get stuck
- [ ] B15: Frozen wallet rejects transactions
- [ ] B16: Double settlement processing is prevented
