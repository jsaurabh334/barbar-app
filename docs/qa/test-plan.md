# QA Test Plan — Barbar App

## Roles Covered
- Customer
- Barber
- Vendor
- Delivery Partner
- Admin

## Testing Order
1. Authentication
2. Booking
3. Queue
4. Payment
5. Wallet
6. Settlement
7. Orders
8. Delivery
9. Vendor
10. Admin
11. Reports
12. CMS
13. Notifications
14. Banners

---

## Phase 1 — Functional Tests

### 1. Authentication
| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| 1.1 | Customer Signup | Customer | Open app → Signup → Enter details → Submit | Account created, OTP sent | |
| 1.2 | Customer OTP Verify | Customer | Enter OTP → Submit | OTP verified, logged in | |
| 1.3 | Customer Login | Customer | Open app → Login → Enter credentials | Logged in successfully | |
| 1.4 | Customer Logout | Customer | Profile → Logout | Logged out, redirected to login | |
| 1.5 | Barber Signup | Barber | Register as barber → Fill details → Submit | Barber account created | |
| 1.6 | Barber Login | Barber | Login with credentials | Logged in to barber dashboard | |
| 1.7 | Vendor Login | Vendor | Login with vendor credentials | Logged in to vendor dashboard | |
| 1.8 | Delivery Login | Delivery | Login with delivery credentials | Logged in to delivery dashboard | |
| 1.9 | Admin Login | Admin | Login with admin credentials | Logged in to admin console | |
| 1.10 | Token Expiry | All | Wait for token to expire → Make API call | 401 returned, redirect to login | |
| 1.11 | Invalid OTP | Customer | Enter wrong OTP | Error shown, retry allowed | |
| 1.12 | OTP Resend | Customer | Request OTP resend | New OTP sent | |

### 2. Booking
| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| 2.1 | Search Barber by name | Customer | Search bar → Type barber name | Matching barbers shown | |
| 2.2 | Search Barber by service | Customer | Search → Type service name | Barbers offering service shown | |
| 2.3 | View barber detail | Customer | Tap barber → View profile/services/reviews | Details displayed | |
| 2.4 | Book a service | Customer | Select service → Select time → Confirm | Booking created, confirmation shown | |
| 2.5 | Cancel booking | Customer | My Bookings → Cancel → Confirm | Booking cancelled, refund processed | |
| 2.6 | Reschedule booking | Customer | My Bookings → Reschedule → New time | Booking rescheduled | |
| 2.7 | Accept booking | Barber | Dashboard → New booking → Accept | Booking confirmed, customer notified | |
| 2.8 | Reject booking | Barber | Dashboard → New booking → Reject | Booking cancelled, customer notified | |
| 2.9 | Update queue | Barber | Booking → Update queue position | Queue updated | |
| 2.10 | Complete booking | Barber | Booking → Mark complete | Booking completed, receipt generated | |
| 2.11 | View booking history | Customer | My Bookings → View all | All past/future bookings listed | |

### 3. Payment
| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| 3.1 | Pay with card | Customer | Booking → Pay → Enter card → Submit | Payment successful | |
| 3.2 | Pay with wallet | Customer | Booking → Pay via wallet → Confirm | Payment deducted from wallet | |
| 3.3 | Apply coupon | Customer | Payment → Enter coupon code → Apply | Discount applied | |
| 3.4 | Payment failure handling | Customer | Use invalid card → Submit | Error shown, retry option | |
| 3.5 | Refund on cancel | Customer | Cancel paid booking → Check wallet | Amount refunded to wallet | |

### 4. Wallet
| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| 4.1 | View wallet balance | Customer | Profile → Wallet | Balance displayed correctly | |
| 4.2 | Add money to wallet | Customer | Wallet → Add → Enter amount → Pay | Balance updated | |
| 4.3 | View wallet transactions | Customer | Wallet → Transactions | All transactions listed with details | |
| 4.4 | Wallet deduction on booking | Customer | Book service → Pay via wallet | Balance decreases correctly | |
| 4.5 | Wallet credit on refund | Customer | Cancel paid booking | Balance increases by refund amount | |

### 5. Settlement
| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| 5.1 | View settlements list | Admin | Admin → Settlements | All settlements listed | |
| 5.2 | Process settlement | Admin | Select settlement → Process | Settlement processed, barber credited | |
| 5.3 | View settlement detail | Admin | Tap settlement → View details | Full breakdown shown | |
| 5.4 | Filter settlements by status | Admin | Filter → Paid/Pending | Filtered results shown | |

### 6. Orders
| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| 6.1 | View orders list | Admin | Admin → Orders | All orders listed | |
| 6.2 | View order detail | Admin | Tap order | Full order detail shown | |
| 6.3 | Update order status | Admin | Order → Change status → Save | Status updated | |
| 6.4 | Assign delivery driver | Admin | Order → Assign driver | Driver assigned, notification sent | |
| 6.5 | Search order by ID | Admin | Orders → Type order ID | Specific order found | |
| 6.6 | Filter orders by status | Admin | Filter by status | Filtered orders shown | |

### 7. Delivery
| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| 7.1 | View available deliveries | Delivery | Dashboard → Available | Available deliveries listed | |
| 7.2 | Accept delivery | Delivery | Tap delivery → Accept | Delivery claimed | |
| 7.3 | Live tracking | Delivery | Active delivery → GPS tracking | Location updates in real-time | |
| 7.4 | Mark as picked up | Delivery | Arrive at vendor → Mark picked up | Status updated | |
| 7.5 | Mark as delivered | Delivery | Arrive at customer → Mark delivered | Delivery completed | |
| 7.6 | Delivery history | Delivery | Profile → History | Past deliveries listed | |
| 7.7 | Broadcast dispatch | Admin | Order → Auto-dispatch | Offers sent to nearby drivers | |

### 8. Vendor
| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| 8.1 | View dashboard | Vendor | Login → Dashboard | Stats shown (orders/revenue) | ✅ |
| 8.2 | View profile | Vendor | Login → Profile | Vendor profile loaded | ✅ |
| 8.3 | Create product | Vendor | Products → Add → Fill details → Save | Product created | ✅ |
| 8.4 | Edit product | Vendor | Products → Tap → Edit → Save | Product updated | ✅ |
| 8.5 | Delete product | Vendor | Products → Delete → Confirm | Product removed | ✅ |
| 8.6 | View orders | Vendor | Orders → List | Incoming orders shown | ✅ |
| 8.7 | Accept order | Vendor | Order → Accept | Status → accepted, customer notified | ✅ |
| 8.8 | Pack order | Vendor | Order → Pack | Status → packed | ✅ |
| 8.9 | Ready for pickup | Vendor | Order → Ready for pickup | Status → ready_for_pickup | ✅ |
| 8.10 | View delivery info | Vendor | Order → Delivery | Delivery partner + tracking shown | ✅ |
| 8.11 | Manage brands (CRUD) | Vendor | Brands → Create/List | Brand created and persisted | ✅ |
| 8.12 | Manage warehouses (CRUD) | Vendor | Warehouses → Create/List | Warehouse created and persisted | ✅ |
| 8.13 | Record purchase (inventory) | Vendor | Purchases → Create/List | Stock updated + purchase recorded | ✅ |
| 8.14 | View inventory stock | Vendor | Inventory → List | Stock levels shown (total/available) | ✅ | |

### 9. Admin
| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| 9.1 | View dashboard | Admin | Login → Dashboard | Key metrics displayed | |
| 9.2 | Manage users | Admin | Customers → Search/View/Filter | User management works | |
| 9.3 | Manage vendors | Admin | Vendors → View/Verify/Reject | Vendor management works | |
| 9.4 | Manage bookings | Admin | Bookings → View/Cancel/Reschedule | Full booking management | |
| 9.5 | Manage banners | Admin | Banners → Create/Edit/Toggle/Delete | Banner CRUD works | |
| 9.6 | Manage CMS | Admin | CMS → Create/Edit/Delete Pages & FAQ | CMS CRUD works | |
| 9.7 | Manage promotions | Admin | Promotions → Create/Edit/Delete coupons | Promotions work | |
| 9.8 | View reports | Admin | Reports → View analytics/charts | Data loads correctly | |
| 9.9 | Navigation drawer | Admin | Open drawer → Navigate to all tabs | All 21 tabs accessible | |

### 10. Reports
| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| 10.1 | View booking analytics | Admin | Reports → Bookings tab | Charts and metrics load | |
| 10.2 | View revenue analytics | Admin | Reports → Revenue tab | Revenue data displayed | |
| 10.3 | View order analytics | Admin | Reports → Orders tab | Order stats shown | |
| 10.4 | View customer analytics | Admin | Reports → Customers tab | Customer metrics shown | |
| 10.5 | View barber analytics | Admin | Reports → Barbers tab | Barber performance shown | |
| 10.6 | View delivery analytics | Admin | Reports → Delivery tab | Delivery stats shown | |
| 10.7 | Date range filter | Admin | Reports → Select dates | Data filtered correctly | |
| 10.8 | Export data | Admin | Reports → Export | File downloaded | |

### 11. CMS
| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| 11.1 | Create page | Admin | CMS → Pages → Add → Save | Page created | |
| 11.2 | Edit page | Admin | CMS → Pages → Tap → Edit → Save | Page updated | |
| 11.3 | Delete page | Admin | CMS → Pages → Delete → Confirm | Page deleted | |
| 11.4 | Create FAQ | Admin | CMS → FAQ → Add → Save | FAQ created | |
| 11.5 | Edit FAQ | Admin | CMS → FAQ → Edit → Save | FAQ updated | |
| 11.6 | Delete FAQ | Admin | CMS → FAQ → Delete → Confirm | FAQ deleted | |
| 11.7 | Public page access | Customer | Open page via URL/key | Content displayed | |

### 12. Notifications
| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| 12.1 | Create campaign | Admin | Campaigns → Create → Fill → Save | Campaign created | |
| 12.2 | Send campaign | Admin | Campaigns → Send now | Notifications sent to target users | |
| 12.3 | Schedule campaign | Admin | Campaigns → Schedule future date | Campaign scheduled | |
| 12.4 | View campaign stats | Admin | Campaigns → Tap → View stats | Sent/failed counts shown | |
| 12.5 | Delete campaign | Admin | Campaigns → Delete | Campaign removed | |
| 12.6 | Receive notification | Customer | Have active booking → Receive update | Push notification received | |

### 13. Banners
| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| 13.1 | Create banner | Admin | Banners → Add → Fill → Save | Banner created | |
| 13.2 | Edit banner | Admin | Banners → Tap → Edit → Save | Banner updated | |
| 13.3 | Toggle banner active | Admin | Banners → Toggle switch | Banner enabled/disabled | |
| 13.4 | Delete banner | Admin | Banners → Delete → Confirm | Banner removed | |
| 13.5 | Banner display on app | Customer | Open app → Home screen | Active banners shown | |

---

## Phase 2 — Edge Case Tests

| # | Test Case | Role | Steps | Expected Result | Pass/Fail |
|---| --------- | ---- | ----- | --------------- | --------- |
| EC1 | Same coupon twice | Customer | Apply coupon → Use it → Try again | Coupon already used error | |
| EC2 | Cancel completed booking | Customer | Complete booking → Try cancel | Error: cannot cancel completed | |
| EC3 | Cancel already cancelled booking | Customer | Cancelled booking → Try cancel again | Error: already cancelled | |
| EC4 | Insufficient wallet balance | Customer | Wallet < booking amount → Pay | Error: insufficient balance | |
| EC5 | Process settlement twice | Admin | Completed settlement → Process again | Error: already processed | |
| EC6 | Open deleted banner | Customer | Banner deleted while viewing | Banner disappears gracefully | |
| EC7 | Expired banner | Customer | Banner past end_date | Banner not shown | |
| EC8 | Invalid dates (past/future) | Customer | Book with past date | Validation error | |
| EC9 | Network off | All | Turn off internet → Try any action | Graceful error, retry option | |
| EC10 | Slow internet | All | Throttle network → Load data | Loading indicator, timeout handling | |
| EC11 | Token expired mid-session | All | Wait for expiry → Continue using app | Redirect to login, data preserved | |
| EC12 | Duplicate signup (same email) | Customer | Signup with existing email | Error: email already registered | |
| EC13 | Empty search results | Customer | Search nonsense query | "No results" empty state | |
| EC14 | Booking with no available slots | Customer | Select fully booked day | No slots shown | |
| EC15 | Create campaign with empty target | Admin | Campaign → No target → Send | Validation error | |
| EC16 | Delete user with active bookings | Admin | Delete user with pending booking | Warning shown, blocked | |
| EC17 | Load more on empty list | All | Pagination on empty results | No crash, no infinite load | |
| EC18 | Special characters in forms | All | Enter HTML/script in fields | Sanitized, no XSS | |
| EC19 | Concurrent booking (same slot) | Customer | Two users book same slot | Second gets conflict error | |
| EC20 | Apply expired coupon | Customer | Enter expired coupon code | Coupon expired error | |

---

## Phase 3 — Performance Tests

| # | Test Case | Description | Expected Result | Pass/Fail |
|---| --------- | ----------- | --------------- | --------- |
| P1 | Pagination (bookings) | Scroll through 200+ bookings | Smooth infinite scroll, no lag | |
| P2 | Pagination (orders) | Scroll through 200+ orders | Smooth infinite scroll, no lag | |
| P3 | Pagination (users) | Scroll through 500+ users | Smooth infinite scroll, no lag | |
| P4 | Image loading (banners) | Load 10+ banner images | Images load without memory spike | |
| P5 | Image loading (products) | Scroll through 100+ products with images | Smooth scroll, lazy load works | |
| P6 | Reports dashboard | Load all 5 analytics sections on slow network | Sections load progressively | |
| P7 | App restart | Kill app → Reopen → Check state | User stays logged in, data restored | |
| P8 | Background → Foreground | Minimize → Reopen after 5 min | App resumes correctly, no crash | |
| P9 | Push notification tap | Receive notification → Tap → Open | Correct screen opens | |
| P10 | Memory — long session | Use app continuously for 30 min | No memory leak, no slowdown | |
| P11 | Memory — list scrolling | Rapid scroll through large lists | No OOM, no jank | |

---

## Instructions

1. Run tests in the order listed above
2. Mark each test case as ✅ Pass / ❌ Fail / ⏭️ Skipped
3. For every failure, add a row to `bug-sheet.md`
4. After fixing a bug, re-run the test case and mark as ✅
5. Phase 1 must be 100% ✅ before starting Phase 2
6. Phase 2 should be 95%+ ✅ before Phase 3
