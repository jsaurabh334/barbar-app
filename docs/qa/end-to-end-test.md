# End-to-End Test — Full Order Lifecycle

This test covers the complete lifecycle: **Customer → Vendor → Delivery Partner → Admin → Finance**.

---

## 1. Customer Places Order

| Step | Expected Result | API | DB Change | Notification | UI |
|------|----------------|-----|-----------|-------------|-----|
| Customer browses products | Products listed correctly | `GET /api/v1/products` | — | — | Product grid |
| Customer adds to cart | Cart updated | `POST /api/v1/cart` | `cart_items` row created | — | Cart badge +1 |
| Customer places order | Order created with status `pending` | `POST /api/v1/orders` | `orders` + `order_items` rows created | — | Order confirmation |
| Payment processed | Payment status = `success` | `POST /api/v1/payments` | `payments` row, `orders.payment_status` = `success` | — | Payment success screen |

## 2. Vendor Processes Order

| Step | Expected Result | API | DB Change | Notification | UI |
|------|----------------|-----|-----------|-------------|-----|
| Vendor receives order | Order visible in vendor dashboard | `GET /api/v1/vendor/orders` | — | Push: "New Order Received" | Order list updated |
| Vendor accepts order | Status → `accepted` | `PUT /api/v1/vendor/orders/:id/status` | `orders.status` = `accepted`, `order_status_logs` row | WebSocket: status update | Status badge changes |
| Vendor packs order | Status → `packed` | `PUT /api/v1/vendor/orders/:id/status` | `orders.status` = `packed` | WebSocket | Packed shown |
| Vendor marks ready for pickup | Status → `ready_for_pickup` | `PUT /api/v1/vendor/orders/:id/status` | `orders.status` = `ready_for_pickup` | WebSocket + Push to delivery | Pickup OTP shown |

## 3. Delivery Partner Delivers Order

| Step | Expected Result | API | DB Change | Notification | UI |
|------|----------------|-----|-----------|-------------|-----|
| Broadcast sent to nearby drivers | Drivers receive offer | `POST /api/v1/admin/orders/:id/dispatch` | `order_delivery_assignments` row created | Push: "New delivery available" | Offer card appears |
| Driver claims order | Assignment status → `accepted` | `PUT /api/v1/delivery/orders/:id/claim` | `order_delivery_assignments.status` = `accepted` | — | Claim button disabled |
| Driver accepts | Assignment confirmed | `PUT /api/v1/delivery/orders/:id/accept` | `orders.delivery_partner_id` set | WebSocket: driver assigned | Driver info shown |
| Driver navigates to vendor | GPS location visible | `POST /api/v1/delivery/location` | `delivery_presence_logs` | — | Live map tracking |
| Driver pickup OTP verified | Status → `picked_up` | `POST /api/v1/delivery/orders/:id/pickup` | `orders.status` = `picked_up`, delivery_otp verified | WebSocket | Picked up badge |
| Driver navigates to customer | GPS location visible | `POST /api/v1/delivery/location` | `delivery_presence_logs` | — | Live map tracking |
| Driver delivery OTP verified | Status → `delivered` | `POST /api/v1/delivery/orders/:id/deliver` | `orders.status` = `delivered`, delivery_otp verified | WebSocket + Push to customer | Delivered badge |

## 4. Finance — Wallet Credit

| Step | Expected Result | API | DB Change | Notification | UI |
|------|----------------|-----|-----------|-------------|-----|
| Vendor wallet credited | Balance increased | Auto on delivery | `wallet_transactions` credit row, `wallets.balance` += amount | Push: "Payment received" | Wallet balance updates |
| Delivery wallet credited | Balance increased | Auto on delivery | `wallet_transactions` credit row, `delivery_earning` row | Push: "Earnings updated" | Earnings dashboard updates |
| Withdrawal request created | Status `pending` | `POST /api/v1/wallet/withdraw` | `withdrawal_requests` row, `wallets.locked_balance` += amount | — | Withdrawal pending |

## 5. Admin — Withdrawal Approval

| Step | Expected Result | API | DB Change | Notification | UI |
|------|----------------|-----|-----------|-------------|-----|
| Admin views withdrawals | List of pending requests | `GET /api/v1/admin/withdrawals` | — | — | Withdrawal list |
| Admin approves withdrawal | Status → `approved` | `PUT /api/v1/admin/withdrawals/:id/approve` | `withdrawal_requests.status` = `approved` | Push: "Withdrawal approved" | Status badge updates |
| Admin marks processed | Status → `processed`, UTR entered | `PUT /api/v1/admin/withdrawals/:id/process` | `withdrawal_requests.status` = `processed`, `utr_number` set, locked_balance decreased | Push: "Withdrawal completed" | Processed badge |

## 6. Admin Panel Verification

| Step | Expected Result | API | DB Change | Notification | UI |
|------|----------------|-----|-----------|-------------|-----|
| View all orders | Paginated list with filters | `GET /api/v1/admin/orders` | — | — | Admin orders screen |
| View order detail | Full detail with timeline | `GET /api/v1/admin/orders/:id` | — | — | Order detail screen |
| View vendor approval list | Pending vendors shown | `GET /api/v1/admin/vendors` | — | — | Vendor management |
| View delivery partners list | All partners with status | `GET /api/v1/admin/delivery-partners` | — | — | Delivery management |
| View analytics | Charts and metrics load | `GET /api/v1/admin/analytics/*` | — | — | Reports dashboard |
| View audit logs | Admin actions listed | `GET /api/v1/admin/audit-logs` | — | — | Audit log screen |
