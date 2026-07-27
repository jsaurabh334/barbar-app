# QA Checklist — Barbar App

## Authentication

- [ ] Customer Registration
- [ ] Customer OTP Verification
- [ ] Customer Login
- [ ] Customer Logout
- [ ] Barber Registration
- [ ] Barber Login
- [ ] Vendor Registration
- [ ] Vendor Login
- [ ] Delivery Partner Registration
- [ ] Delivery Partner Login
- [ ] Admin Login
- [ ] Token Expiry Handling
- [ ] Invalid OTP Error
- [ ] OTP Resend

## Customer

- [ ] Search Barber by Name
- [ ] Search Barber by Service
- [ ] View Barber Detail
- [ ] Book a Service
- [ ] Cancel Booking
- [ ] Reschedule Booking
- [ ] Pay with Card
- [ ] Pay with Wallet
- [ ] Apply Coupon
- [ ] View Booking History
- [ ] Write a Review
- [ ] Edit Review
- [ ] Save Address
- [ ] Browse Products
- [ ] Place Product Order

## Vendor

- [ ] Register Vendor
- [ ] Complete KYC
- [ ] Admin Approval
- [ ] Create Product
- [ ] Edit Product
- [ ] Delete Product
- [ ] View Orders
- [ ] Accept Order
- [ ] Pack Order
- [ ] Ready for Pickup
- [ ] View Delivery Info
- [ ] Manage Brands
- [ ] Manage Warehouses
- [ ] Record Purchase (Inventory)
- [ ] View Inventory Stock

## Barber

- [ ] Accept Booking
- [ ] Reject Booking
- [ ] Update Queue Position
- [ ] Mark Service Started
- [ ] Complete Booking
- [ ] Manage Availability
- [ ] Set Holidays

## Delivery Partner

- [ ] Register Delivery Partner
- [ ] Upload KYC Documents
- [ ] Add Bank Account
- [ ] Admin Approval
- [ ] Go Online
- [ ] Go Offline
- [ ] Receive Broadcast
- [ ] Claim Delivery Order
- [ ] Accept Assignment
- [ ] Reject Assignment
- [ ] Navigate to Vendor
- [ ] Verify Pickup OTP
- [ ] Pick Up Order
- [ ] Navigate to Customer
- [ ] Verify Delivery OTP
- [ ] Mark Delivered
- [ ] Live Tracking / GPS
- [ ] View Earnings
- [ ] Heartbeat / Presence

## Orders

- [ ] Place Order (Product)
- [ ] Place Booking (Service)
- [ ] Vendor Accept
- [ ] Ready for Pickup
- [ ] Pickup OTP Generated
- [ ] Driver Receives Offer
- [ ] Driver Claim
- [ ] Driver Accept
- [ ] Pickup OTP Verify
- [ ] Picked Up
- [ ] Delivery OTP Verify
- [ ] Delivered
- [ ] Wallet Credit
- [ ] Transaction Created
- [ ] Payment Success
- [ ] Payment Failure Handling
- [ ] Refund on Cancel

## Wallet

- [ ] View Wallet Balance
- [ ] Add Money to Wallet
- [ ] View Wallet Transactions
- [ ] Wallet Deduction on Booking
- [ ] Wallet Credit on Refund
- [ ] Frozen Wallet — No Credit/Debit
- [ ] Locked vs Available Balance

## Withdrawals

- [ ] Withdrawal Request Created
- [ ] Admin Approval
- [ ] Admin Rejection
- [ ] Status Update
- [ ] UTR Number Entry
- [ ] Locked Balance Updated
- [ ] Withdrawal History

## Notifications

- [ ] Booking Confirmed (Customer)
- [ ] New Order Received (Vendor)
- [ ] Delivery Assignment (Driver)
- [ ] Wallet Credit
- [ ] Withdrawal Status
- [ ] Admin Campaign
- [ ] FCM Push Notification
- [ ] In-App Notification
- [ ] WebSocket Real-time Update

## Admin

- [ ] View Dashboard
- [ ] Manage Users
- [ ] Manage Vendors (Approve/Reject)
- [ ] Manage Delivery Partners (Approve/Suspend)
- [ ] View Orders
- [ ] Update Order Status
- [ ] Assign Driver to Order
- [ ] Broadcast Dispatch
- [ ] View Online Drivers
- [ ] Manage Bookings
- [ ] Cancel Booking
- [ ] Reschedule Booking
- [ ] Manage Banners
- [ ] Manage CMS Pages
- [ ] Manage Promotions/Coupons
- [ ] Manage Settlements
- [ ] Process Settlement
- [ ] View Reports/Analytics
- [ ] Manage Wallet (Credit/Debit)
- [ ] Approve/Reject Withdrawals
- [ ] View Audit Logs

## Performance

- [ ] Pagination — Bookings (200+)
- [ ] Pagination — Orders (200+)
- [ ] Pagination — Users (500+)
- [ ] Image Loading — Banners
- [ ] Image Loading — Products
- [ ] Reports Dashboard Load
- [ ] App Restart — Session Persists
- [ ] Background → Foreground Resume

## Security

- [ ] OTP HMAC Verification
- [ ] OTP Attempt Limit (5 max)
- [ ] Refresh Token Rotation
- [ ] Reuse Revocation
- [ ] Session Invalidation on Password Change
- [ ] UUID Validation on All Admin Endpoints
- [ ] Ownership Verified (Barber/Delivery/Vendor)
- [ ] No JWT Default Fallback
- [ ] CORS Restricted
- [ ] Input Validation — All Forms
- [ ] XSS Prevention — Special Characters
- [ ] Concurrent Booking — Same Slot
- [ ] Expired Coupon Rejected
