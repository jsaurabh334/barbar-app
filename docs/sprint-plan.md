# BARBAR-APP SPRINT PLAN

## Overview

6 sprints to make the Customer module fully functional with real backend data.

| Sprint | Focus | Type |
|--------|-------|------|
| 1 | Authentication Stabilization | Fix + Connect |
| 2 | Home, Discovery & Shop Details | Fix + Enhance |
| 3 | Booking & Queue | Fix + Connect |
| 4 | Marketplace, Wallet & Address | Fix + Connect |
| 5 | Profile, Notifications & Navigation | New Screens |
| 6 | End-to-End Testing & Audit | Verify |

---

## Sprint 1: Authentication Stabilization

### Goal
Make Auth fully functional with real backend data. Remove ALL fake/mock/bypass code from Auth flow.

### Files in Scope

**Backend:**
- `backend/internal/handlers/auth/auth_handler.go`

**Frontend:**
- `lib/data/repositories/auth_repository_impl.dart`
- `lib/data/datasources/remote/auth_remote_datasource.dart`
- `lib/data/datasources/local/auth_local_datasource.dart`
- `lib/presentation/screens/auth_screen.dart`
- `lib/presentation/bloc/auth/auth_bloc.dart`
- `lib/presentation/bloc/auth/auth_event.dart`
- `lib/presentation/bloc/auth/auth_state.dart`

### Tasks

**Task 1: Backend — Remove OTP bypass**
Locate the OTP verification logic checking `req.OTP == "123456"` and refactor so all OTP validation goes through the normal verification path (check phone + OTP + expiry). Preserve existing business logic.

**Task 2: Frontend — Remove test phone bypass**
Locate test phone bypass in `sendOtp()` and `verifyOtp()` in the auth repository. Remove all hardcoded test phone numbers and mock session creation. Ensure all OTP calls go through the real backend.

**Task 3: Frontend — Verify API contracts**
Read `auth_remote_datasource.dart` and verify every endpoint matches backend routes. Check request body fields match backend request structs. Fix any mismatches by aligning frontend to backend.

**Task 4: Frontend — Auth screen validation**
Verify frontend form fields match backend registration/login contracts. If fields differ, update frontend to match backend. Verify errors display in UI, loading states work, and successful auth navigates correctly.

**Task 5: Frontend — BLoC audit**
Read auth BLoC files. Verify all backend responses have corresponding states. Verify error propagation to UI.

**Task 6: Session restore**
Audit existing bootstrap flow. If session restoration exists, verify and fix. If missing, implement using existing token storage mechanism.

**Task 7: Auth error handling**
Ensure proper messages for: network errors, invalid credentials, expired OTP, server errors.

### What NOT to Do
- Do NOT add Google/Apple login
- Do NOT change AuthLocalDataSource storage format
- Do NOT redesign auth screen layout
- Do NOT touch other modules

---

## Sprint 2: Home, Discovery & Shop Details

### Goal
Make Home screen, nearby shop discovery, and barber detail page fully functional with real backend data. Remove mock barbers from directory repository. Add missing UI components (gallery, working hours, categories).

### Files in Scope

**Backend:**
- `backend/internal/handlers/barber/barber_handler.go`
- `backend/internal/handlers/product/product_handler.go` (categories)

**Frontend:**
- `lib/presentation/screens/home_screen.dart`
- `lib/presentation/screens/barber_detail_screen.dart`
- `lib/presentation/screens/map_discovery_screen.dart`
- `lib/data/repositories/directory_repository_impl.dart`
- `lib/data/datasources/remote/directory_remote_datasource.dart`
- `lib/presentation/bloc/directory/directory_bloc.dart`
- `lib/presentation/bloc/directory/directory_event.dart`
- `lib/presentation/bloc/directory/directory_state.dart`

### Tasks

**Task 1: Remove mock barbers from directory repository**
Locate `_mockBarbers` list in `directory_repository_impl.dart`. Remove it along with the `catch(_) { return mockData }` fallback in `getNearbyBarbers()`. If API returns empty, return empty list. If API fails, let error propagate to BLoC which handles `DirectoryFailure` with error display.

**Task 2: Add categories section to Home screen**
Backend has `GET /public/categories` endpoint. Add horizontal scrolling categories chip row below search bar in `home_screen.dart`. Categories fetched on init. Each chip filters the nearby barbers list.

**Task 3: Add filter bar to Home screen**
Add filter chips for: Rating (3+/4+/5+), Open Now toggle. Backend `ListNearby` supports `min_rating` param. Update `FetchNearbyBarbers` event to pass filters.

**Task 4: Add gallery section to Barber Detail screen**
The `Barber` model has `shopImages` (JSONB array). Add horizontal image gallery row below shop info section in `barber_detail_screen.dart`.

**Task 5: Add working hours display**
The `Barber` model has `startTime`, `endTime`, `businessDays`. Add "Working Hours" section in barber detail screen.

**Task 6: Verify API contract for barber detail**
Read `GET /public/barbers/:id` in backend and verify frontend `barber_model.dart` maps all fields correctly.

**Task 7: Search functionality**
Verify search bar in home screen properly passes search param to backend.

### What NOT to Do
- Do NOT change booking/queue flow
- Do NOT touch payment
- Do NOT modify Barber/Vendor/Delivery screens

---

## Sprint 3: Booking & Queue

### Goal
Make booking creation, queue tracking, and booking history fully functional with real backend data. Remove ALL mock booking fallback patterns. Payment screen deferred.

### Files in Scope

**Backend:**
- `backend/internal/handlers/booking/booking_handler.go`

**Frontend:**
- `lib/data/repositories/booking_repository_impl.dart`
- `lib/data/datasources/remote/booking_remote_datasource.dart`
- `lib/presentation/screens/barber_detail_screen.dart` (booking button)
- `lib/presentation/screens/queue_tracker_screen.dart`
- `lib/presentation/bloc/booking/booking_bloc.dart`
- `lib/presentation/bloc/booking/booking_event.dart`
- `lib/presentation/bloc/booking/booking_state.dart`

### Tasks

**Task 1: Remove all mock data from booking repository**
Remove `_mockServices`, catch block fallbacks in `createBooking()`, `getAllBookings()`, `getQueuePosition()`, `updateBookingStatus()`, `payBooking()`, `getBookingInvoice()`. Every catch block should rethrow or let exception propagate.

**Task 2: Verify booking API endpoints**
Verify all endpoints in `booking_remote_datasource.dart` match `booking_handler.go` routes. Fix mismatches.

**Task 3: Booking creation flow**
Verify `_confirmBooking()` in barber detail screen sends correct data. On success → navigate to queue tracker. On failure → show error with retry.

**Task 4: Queue tracker screen**
Verify displays active booking, queue position, estimated wait, WebSocket updates. Leave Queue → cancel booking. Empty/loading/error states.

**Task 5: Cancel booking flow**
Verify cancel dispatches correct event → backend call → remove from queue UI.

**Task 6: Booking history**
Consider adding past bookings section below active queue card. Backend `GET /bookings` returns all customer bookings.

### What NOT to Do
- Do NOT touch payment/payment_screen.dart (deferred)
- Do NOT modify invoice_screen.dart unless necessary

---

## Sprint 4: Marketplace, Wallet & Address

### Goal
Make product marketplace, shopping cart, wallet balance/transactions, and address management fully functional with real backend data.

### Files in Scope

**Backend:**
- `backend/internal/handlers/product/product_handler.go`
- `backend/internal/handlers/order/order_handler.go`
- `backend/internal/handlers/wallet/wallet_handler.go`
- `backend/internal/handlers/address/address_handler.go`
- `backend/internal/handlers/cart/cart_handler.go`

**Frontend:**
- `lib/data/repositories/marketplace_repository_impl.dart`
- `lib/data/repositories/wallet_repository_impl.dart`
- `lib/data/repositories/address_repository_impl.dart`
- `lib/data/datasources/remote/marketplace_remote_datasource.dart`
- `lib/data/datasources/remote/wallet_remote_datasource.dart`
- `lib/data/datasources/remote/address_remote_datasource.dart`
- `lib/presentation/screens/shop_screen.dart`
- `lib/presentation/screens/wallet_screen.dart`
- `lib/presentation/screens/address_screen.dart`
- `lib/presentation/bloc/marketplace/marketplace_bloc.dart`
- `lib/presentation/bloc/wallet/wallet_bloc.dart`

### Tasks

**Task 1: Remove mock products from marketplace repository**
Remove `_mockProducts`, catch blocks in `getProducts()`, `placeOrder()`, `getOrders()`.

**Task 2: Verify marketplace API endpoints**
Verify all endpoints match backend routes. Fix mismatches.

**Task 3: Remove fake wallet data**
Remove `_balance = 12500.0`, catch blocks in `getWalletDetails()`, `requestWithdrawal()`.

**Task 4: Verify wallet API endpoints**
Verify endpoints match backend.

**Task 5: Fix address screen real API**
Connect `address_screen.dart` to real backend CRUD endpoints. Add loading/empty/error states.

**Task 6: Cart integration**
Verify add-to-cart in `shop_screen.dart` connects to backend cart endpoints.

**Task 7: Wishlist (report only)**
Check if frontend wishlist UI exists. If not, report as "Backend API exists, frontend screen missing".

### What NOT to Do
- Do NOT build new marketplace features (subscription, repeat orders)
- Do NOT touch payment flow

---

## Sprint 5: Profile, Notifications & Navigation

### Goal
Add profile management screen, notifications list screen, and update navigation drawer with all available customer screens.

### Files in Scope

**Backend:**
- `backend/internal/handlers/auth/auth_handler.go` (GetProfile, UpdateProfile)
- `backend/internal/services/notification/notification_service.go`

**Frontend (New Screens):**
- `lib/presentation/screens/profile_screen.dart`
- `lib/presentation/screens/notifications_screen.dart`
- `lib/presentation/screens/my_bookings_screen.dart`

**Frontend (Existing to Modify):**
- `lib/presentation/screens/home_screen.dart` (drawer)
- `lib/presentation/screens/customer_dashboard_shell.dart` (bottom nav)
- `lib/main.dart` (routes)

### Tasks

**Task 1: Build Profile Screen**
Display/edit name, avatar. GET/PUT `/auth/profile`. Loading, error, save-success states. Follow existing UI patterns (GlassCard, AppColors, LucideIcons).

**Task 2: Build Notifications Screen**
Fetch from GET `/notifications`. List with read/unread. Mark read on tap. Mark all read. Empty state. Pull to refresh.

**Task 3: Build My Bookings Screen**
Fetch from GET `/bookings`. Tabs: Upcoming | Past. Cancel button. Empty/loading/error states.

**Task 4: Update Navigation Drawer**
Add: My Profile, My Bookings, Notifications, My Addresses. Keep existing items. Sign Out at bottom.

**Task 5: Update Bottom Navigation (if needed)**
Evaluate if bottom nav needs updating for new screens.

**Task 6: Register Routes in main.dart**

### What NOT to Do
- Do NOT modify backend (all APIs already exist)
- Do NOT redesign drawer layout

---

## Sprint 6: End-to-End Testing & Production Readiness

### Goal
No new features. Audit every customer screen for loading, empty, error states. Verify all API connections. Ensure no mock/fake data remains anywhere.

### Scope
ALL customer module files (read-only audit + fixes only).

### Tasks

**Task 1: Mock/fake data audit**
Search entire `lib/` for `_mock`, silent `catch (_)`, hardcoded test data, `Random()` used as real values. Fix all instances.

**Task 2: State coverage audit**
Every screen must have: Loading, Empty, Error with retry, Pull to refresh, Form validation. Add missing states.

**Task 3: API contract audit**
Every remote datasource — verify path, method, request body, response fields match backend.

**Task 4: Navigation audit**
Every drawer item, bottom nav tab, booking flow, auth flow — verify correct navigation.

**Task 5: Error message audit**
No raw `Exception:` strings. Network/server/auth errors show friendly messages.

**Task 6: Regression check**
Verify Barber, Vendor, Delivery, Admin modules still work correctly.

**Task 7: Final report**
Comprehensive Module Completion Report with all features, blockers, known limitations, and next steps for other modules.

### What NOT to Do
- Do NOT add new features
- Do NOT redesign any screen
- Do NOT touch backend routes
