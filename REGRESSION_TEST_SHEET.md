# Release 1.0 — Manual Regression Test Sheet

**Backend**: http://localhost:8080  
**Health**: ✅ `{"status":"ok"}`  
**Seed Data**: 15 shops, 90 services, 30 products, 5 vendors  

---

## How to Use

1. Run `flutter run` on emulator/device
2. Go through each module in order
3. Mark ✅ Pass / ❌ Fail / ⚠️ Partial
4. For failures, note details in Bug Triage

---

## 1. Authentication

| # | Test Case | Steps | Expected | Result |
|---|-----------|-------|----------|--------|
| 1.1 | OTP Login | Enter phone → Send OTP → Enter 123456 | Logged in to HomeScreen | ⬜ |
| 1.2 | Email Login | Use `customer@demo.com` / `Demo@123` | Logged in | ⬜ |
| 1.3 | Register | Fill form → Submit | Account created, auto-login | ⬜ |
| 1.4 | Wrong OTP | Enter wrong code | Error message | ⬜ |
| 1.5 | OTP Resend | Tap "Resend" | New OTP sent | ⬜ |
| 1.6 | Logout | From Profile → Sign Out | Back to AuthScreen | ⬜ |
| 1.7 | Session Restore | Kill app → Open again | Auto-login (no OTP) | ⬜ |
| 1.8 | Demo Buttons | Tap each demo button | Logged in as correct role | ⬜ |

## 2. Profile

| # | Test Case | Steps | Expected | Result |
|---|-----------|-------|----------|--------|
| 2.1 | View Profile | Profile tab | Name, phone, email display | ⬜ |
| 2.2 | Edit Name | Tap edit → change name → save | Updated name persists | ⬜ |
| 2.3 | Edit Email | Change email → save | Updated email persists | ⬜ |
| 2.4 | Empty Name | Clear name → save | Validation error | ⬜ |
| 2.5 | Invalid Email | Enter "abc" → save | Validation error | ⬜ |

## 3. Address

| # | Test Case | Steps | Expected | Result |
|---|-----------|-------|----------|--------|
| 3.1 | Add Address | Profile → My Addresses → Add → fill all fields | Address appears in list | ⬜ |
| 3.2 | Edit Address | Tap existing address → Edit | Changes saved | ⬜ |
| 3.3 | Delete Address | Swipe/tap delete | Address removed | ⬜ |
| 3.4 | Set Default | Tap "Set as default" | Default badge appears | ⬜ |
| 3.5 | Delete Default | Delete the default address | Warning or auto-reassign | ⬜ |
| 3.6 | Multiple Addresses | Add 3+ addresses | All listed, scrollable | ⬜ |
| 3.7 | No Pincode | Leave pincode empty → save | Validation error | ⬜ |

## 4. Discovery

| # | Test Case | Steps | Expected | Result |
|---|-----------|-------|----------|--------|
| 4.1 | HomeScreen Loads | Launch app | 15 shops visible in list | ⬜ |
| 4.2 | Search | Type "Premium" in search bar | Filtered results | ⬜ |
| 4.3 | Category Filter | Tap "Haircut" category chip | Only haircut shops | ⬜ |
| 4.4 | Rating Filter | Tap 4+ rating | Shops with 4+ rating | ⬜ |
| 4.5 | Open Now | Toggle "Open Now" | Only open shops | ⬜ |
| 4.6 | Map View | Tap map icon | Map with markers | ⬜ |
| 4.7 | Map Marker Tap | Tap marker | Bottom sheet with shop info | ⬜ |
| 4.8 | No Nearby Shops | Search "xyz123" | Empty state message | ⬜ |
| 4.9 | No Search Result | Search nonsense text | "No results found" | ⬜ |

## 5. Shop Detail

| # | Test Case | Steps | Expected | Result |
|---|-----------|-------|----------|--------|
| 5.1 | Shop Loads | Tap any shop from list | Full detail screen | ⬜ |
| 5.2 | Gallery | Swipe through images | Images change, dots update | ⬜ |
| 5.3 | Services List | Scroll services | Names + prices + duration | ⬜ |
| 5.4 | Working Hours | Check hours section | Days + timings displayed | ⬜ |
| 5.5 | Amenities | Check amenities section | Icons + labels | ⬜ |
| 5.6 | Reviews Section | Scroll to reviews | Rating + review cards | ⬜ |
| 5.7 | Call Button | Tap phone icon | `tel:` URL opens | ⬜ |
| 5.8 | Shop with no gallery | Find/seed a shop with no images | Section hidden or empty state | ⬜ |
| 5.9 | Shop closed today | Check a closed shop | "Closed" badge visible | ⬜ |

## 6. Booking ⭐

| # | Test Case | Steps | Expected | Result |
|---|-----------|-------|----------|--------|
| 6.1 | Select Service | Check one service | Price updates | ⬜ |
| 6.2 | Select Multiple Services | Check 2-3 services | Total price sums correctly | ⬜ |
| 6.3 | Select Date | Tap date picker | Calendar opens | ⬜ |
| 6.4 | Available Slots | Select a date | Time slots shown | ⬜ |
| 6.5 | Confirm Booking | Select all → Confirm | Success screen with queue # | ⬜ |
| 6.6 | Booking in History | Go to Booking tab → Upcoming | Booking card visible | ⬜ |
| 6.7 | Cancel Booking | Tap Cancel on booking | Moved to History tab | ⬜ |
| 6.8 | **Double Booking** | Same slot from 2 devices | Only 1 succeeds | ⬜ |
| 6.9 | **Queue Full** | Max queue (50) reached | Proper error message | ⬜ |
| 6.10 | **Internet Lost** | During booking, turn off WiFi | No duplicate, error handling | ⬜ |
| 6.11 | Refresh History | Pull-to-refresh on Booking tab | List reloads | ⬜ |

## 7. Queue

| # | Test Case | Steps | Expected | Result |
|---|-----------|-------|----------|--------|
| 7.1 | Queue Card on Home | After booking | Queue card with position | ⬜ |
| 7.2 | Queue Tracker | Tap queue card | Live tracker screen | ⬜ |
| 7.3 | WS Position Update | Barber updates status | Position updates live | ⬜ |
| 7.4 | Leave Queue | Cancel booking | Removed from queue | ⬜ |
| 7.5 | Estimated Wait | Check tracker | Wait time displayed | ⬜ |
| 7.6 | **WS Reconnect** | Turn off WiFi → back on | Auto-reconnects, syncs | ⬜ |
| 7.7 | **App BG→FG** | Minimize app → reopen | Queue position still correct | ⬜ |

## 8. Payment

| # | Test Case | Steps | Expected | Result |
|---|-----------|-------|----------|--------|
| 8.1 | Pay via UPI | Booking → Payment → UPI | Reference generated, success | ⬜ |
| 8.2 | Pay via Cash | Select Cash → Pay | Booking marked cash | ⬜ |
| 8.3 | Invoice Screen | After payment | Correct totals, booking info | ⬜ |
| 8.4 | Apply Coupon | Enter coupon code | Discount applied | ⬜ |
| 8.5 | Invalid Coupon | Enter wrong code | Error message | ⬜ |
| 8.6 | Wallet Insufficient | Try wallet with < balance | Error or partial payment | ⬜ |
| 8.7 | Payment Failure | Simulate failure | Error message, retry option | ⬜ |

## 9. Reviews

| # | Test Case | Steps | Expected | Result |
|---|-----------|-------|----------|--------|
| 9.1 | Write Review | Booking History → Write Review | Review screen opens | ⬜ |
| 9.2 | Star Rating | Tap 1-5 stars | Rating selected | ⬜ |
| 9.3 | Add Comment | Type comment (10-1000 chars) | Comment saved | ⬜ |
| 9.4 | Upload Photo(s) | Tap camera icon → select | Thumbnail shows, upload starts | ⬜ |
| 9.5 | 5 Images Upload | Select 5 images | All uploaded | ⬜ |
| 9.6 | Invalid Image | Select non-image file | Rejected or error | ⬜ |
| 9.7 | Remove Image Before Submit | Tap X on thumbnail | Removed from selection | ⬜ |
| 9.8 | Submit Review | Tap Submit | Success → "Pending" status | ⬜ |
| 9.9 | Duplicate Review | Try review same booking again | Error: already reviewed | ⬜ |
| 9.10 | Review Pending | Check status after submit | Shows "Pending Approval" | ⬜ |
| 9.11 | Review Approved | Admin approves | Status = "Approved" | ⬜ |
| 9.12 | Review Rejected | Admin rejects | Status = "Rejected" + reason | ⬜ |

## 10. Marketplace

| # | Test Case | Steps | Expected | Result |
|---|-----------|-------|----------|--------|
| 10.1 | Product Grid | Shop tab | Products with images, prices | ⬜ |
| 10.2 | Category Filter | Tap category chip | Filtered products | ⬜ |
| 10.3 | Add to Cart | Tap + on product | Item added, badge updates | ⬜ |
| 10.4 | Cart View | Tap cart icon | Cart with items, total | ⬜ |
| 10.5 | Quantity Update | Increase/decrease qty | Total updates | ⬜ |
| 10.6 | Remove Product | Tap delete on cart item | Item removed | ⬜ |
| 10.7 | Empty Cart | Cart with no items | Empty state message | ⬜ |
| 10.8 | Apply Promo Code | Enter code | Discount shown | ⬜ |
| 10.9 | Place Order | Select address → Place Order | Order created, history shows | ⬜ |
| 10.10 | Product OOS | Try to order OOS product | Error or disabled | ⬜ |

## 11. Wallet

| # | Test Case | Steps | Expected | Result |
|---|-----------|-------|----------|--------|
| 11.1 | Balance Display | Profile → Wallet | Balance shown (gold card) | ⬜ |
| 11.2 | Transaction List | Wallet screen | Ledger with transactions | ⬜ |
| 11.3 | Request Withdrawal | Enter amount → Request | Withdrawal submitted | ⬜ |
| 11.4 | Zero Balance | Empty wallet | Shows ₹0, no error | ⬜ |
| 11.5 | Withdrawal Validation | Enter negative/zero amount | Validation error | ⬜ |
| 11.6 | Refresh Transactions | Pull-to-refresh | List reloads | ⬜ |

## 12. Admin (if accessible)

| # | Test Case | Steps | Expected | Result |
|---|-----------|-------|----------|--------|
| 12.1 | Dashboard | Login as admin | Stats load | ⬜ |
| 12.2 | Approve Review | Reviews tab → Approve | Status changes, rating updates | ⬜ |
| 12.3 | Reject Review | Reviews tab → Reject | Reason prompt, status changes | ⬜ |
| 12.4 | Customer List | Customers tab | List loads | ⬜ |
| 12.5 | Block Customer | Tap Block | Customer blocked | ⬜ |
| 12.6 | Unblock Customer | Tap Unblock | Customer unblocked | ⬜ |

---

## Phase 5 — Cross-Role Testing

| # | Scenario | Steps | Expected | Result |
|---|----------|-------|----------|--------|
| C1 | Full Booking Flow | Customer A books → Barber confirms → A completes | All statuses correct | ⬜ |
| C2 | Queue Competition | A books slot 1 → B books same slot → B gets "booked" error | Only 1 booking per slot | ⬜ |
| C3 | Queue Progress | A,B,C book → Barber completes A → B becomes #1 | Queue shifts correctly | ⬜ |
| C4 | Cancel & Promote | A,B book → B cancels → A stays #1 | Queue consistent | ⬜ |
| C5 | Review Moderation | Customer reviews → Admin approves → Public sees it | Full lifecycle works | ⬜ |

---

## Scoring

```
Total: ~77 test cases
Passed: ___ / 77
Failed: ___ / 77
Blocked: ___ / 77
```
