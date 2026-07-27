# Barbar App — Production Release Checklist

> **Generated**: July 27, 2026  
> **Feature Completion**: 🟢 ~92–94%  
> **Production Readiness**: 🟡 ~70–75%  
> **Estimated Launch**: 2–3 weeks of focused work

---

## How to Use

- Each item is a ticket-style task with: **ID, Area, Description, File Reference, Estimated Effort, Status**
- Mark `[x]` when done
- Track progress in the header counters
- Update dates as you go

**Progress Tracking**:
- 🔴 Critical (6) — Block production launch
- 🟡 Major (8) — Should fix before launch
- 🔵 Minor (6) — Fix before v1.0 stable
- ⚪ Enhancement (4) — Post-launch / v2

---

## SECTION 1: 🔴 CRITICAL — BLOCKS PRODUCTION

*Fix before any production deployment. These can cause financial loss or security breach.*

### C-01: Wallet Deduction Before Transaction

| Field | Value |
|-------|-------|
| **Area** | Backend — Order |
| **File** | `backend/internal/handlers/order/order_handler.go:161` |
| **Issue** | Wallet balance is deducted via `h.db.Model(&wallet).Update("balance", ...)` at line 161, BEFORE the order creation transaction starts at line 194. If order creation fails, money is deducted with no order created. |
| **Risk** | **Financial loss** — customer charged without order |
| **Fix** | Move wallet deduction inside the same GORM transaction as order creation. Use `tx.Model(&wallet)...` instead of `h.db...` |
| **Estimate** | ⏱ ~1 day (including testing) |
| **Status** | `[ ]` Pending |
| **Verification** | Unit test: create order with wallet payment, force DB error after wallet deduction but before order insert → verify wallet is credited back |

---

### C-02: Auto-Approved Refunds

| Field | Value |
|-------|-------|
| **Area** | Backend — Booking |
| **File** | `backend/internal/handlers/booking/booking_handler.go:1097,1110` |
| **Issue** | `processRefund()` creates refund with `Status: "approved"` hardcoded (lines 1097, 1110). No admin moderation. |
| **Risk** | **Financial fraud** — anyone who cancels gets auto-refunded without review |
| **Fix** | Change status to `"pending"`. Create admin moderation endpoint or auto-approve only for small amounts (< ₹500) with configurable threshold. |
| **Estimate** | ⏱ ~2 hours |
| **Status** | `[ ]` Pending |
| **Verification** | Create booking → pay → cancel → verify refund status is `"pending"`, not `"approved"` |

---

### C-03: OTP Bypass Codes in Production

| Field | Value |
|-------|-------|
| **Area** | Backend — Delivery |
| **File** | `backend/internal/services/order/order_service.go:556,580` |
| **Issue** | Two bypass codes exist: `"1234"` (line 556 — auto-generates OTP) and `"MASTER_1234"` (line 580 — always matches). These are dev shortcuts. |
| **Risk** | **Delivery fraud** — anyone can confirm pickup/delivery without real OTP |
| **Fix** | Remove both bypass conditions. Wrap in `if !cfg.IsDevMode()` or remove entirely. |
| **Estimate** | ⏱ ~30 min |
| **Status** | `[ ]` Pending |
| **Verification** | Test delivery OTP flow with `"1234"` in production mode → must fail |

---

### C-04: Docker Health Check Broken

| Field | Value |
|-------|-------|
| **Area** | Infrastructure — Docker |
| **File** | `backend/Dockerfile:33` |
| **Issue** | `HEALTHCHECK` uses `wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1` but `wget` is NOT installed in `alpine:3.19` base image. Health check always fails, causing container restart loops. |
| **Risk** | **Orchestrator kills healthy container** — container thrashing |
| **Fix** | Either: (1) Add `RUN apk add --no-cache wget` before HEALTHCHECK, or (2) Use `CMD curl -f http://localhost:8080/health` and add `curl`, or (3) Use Go-native health endpoint with no external dependency. |
| **Estimate** | ⏱ ~10 min |
| **Status** | `[ ]` Pending |
| **Verification** | `docker build . && docker run` → `docker inspect` shows `"Status": "healthy"` |

---

### C-05: `.env` Secrets Baked Into Docker Image

| Field | Value |
|-------|-------|
| **Area** | Infrastructure — Docker |
| **File** | `backend/Dockerfile:22` |
| **Issue** | `COPY --from=builder /app/.env /.env` copies the `.env` file (which may contain DB passwords, API keys, JWT secrets) into the final production image. Anyone with image access can extract secrets. |
| **Risk** | **Credential leak** — secrets exposed in registry |
| **Fix** | (1) Remove line 22 entirely. (2) Add `.env` to `.dockerignore`. (3) Pass secrets via Docker environment variables or secrets manager. |
| **Estimate** | ⏱ ~10 min |
| **Status** | `[ ]` Pending |
| **Verification** | `docker history <image>` should show no `.env` layer. `docker run --rm -it --entrypoint sh <image>` → `ls /.env` should NOT exist |

---

### C-06: Settlement UTR Number Typo

| Field | Value |
|-------|-------|
| **Area** | Backend — Admin |
| **File** | `backend/internal/handlers/admin/admin_settlement_handler.go:138,202` |
| **Issue** | Field name `"utr_nnumber"` has double 'n'. GORM maps this to column `utr_nnumber` in DB, but the model `WithdrawalRequest` expects `utr_number`. The UTR number is saved to the wrong column and never readable. |
| **Risk** | **Data loss** — settlement UTR references lost. Compliance/audit failure. |
| **Fix** | Change `"utr_nnumber"` → `"utr_number"` on lines 138 and 202 |
| **Estimate** | ⏱ ~10 min |
| **Status** | `[ ]` Pending |
| **Verification** | Process a settlement → check DB column `utr_number` has correct value |

---

## SECTION 2: 🟡 MAJOR — SHOULD FIX BEFORE LAUNCH

*High impact but won't cause financial loss or security breach.*

### M-01: JWT_SECRET No Default in Production Compose

| Field | Value |
|-------|-------|
| **Area** | Infrastructure — Docker Compose |
| **File** | `backend/docker-compose.prod.yml:48` |
| **Issue** | `JWT_SECRET: ${JWT_SECRET}` has no default value (no `:-` fallback). If the env var is not set, it becomes empty string. JWT signing with empty key = trivially forgeable tokens. |
| **Risk** | **Authentication bypass** if secret is empty |
| **Fix** | Add fallback check in `config.go` or add `${JWT_SECRET:?error}` to fail fast if missing |
| **Estimate** | ⏱ ~5 min |
| **Status** | `[ ]` Pending |
| **Verification** | Deploy without setting JWT_SECRET → container should fail to start with clear error |

---

### M-02: Real Payment Gateway Integration

| Field | Value |
|-------|-------|
| **Area** | Flutter — Payment |
| **Files** | `barbar_app/lib/core/services/payment_service.dart`, `barbar_app/lib/presentation/screens/payment_screen.dart` |
| **Issue** | Flutter payment screen uses `PaymentService.simulatePayment()` — a mock UI that shows a fake Razorpay-like bottom sheet with 2-second delay and always returns success. Backend has full Razorpay/Stripe integration but Flutter never calls it. |
| **Risk** | **No real payments** — app cannot process money |
| **Fix** | (1) Integrate `razorpay_flutter` package or Stripe SDK. (2) Replace `simulatePayment()` with real gateway call. (3) Handle webhook response for payment confirmation. |
| **Estimate** | ⏱ ~2–3 weeks (largest remaining item) |
| **Status** | `[ ]` Pending |
| **Dependencies** | Razorpay merchant account / Stripe account. Webhook endpoint (`POST /payments/webhook/:gateway`) already exists. |

---

### M-03: Redis & WebSocket Health Check Fake

| Field | Value |
|-------|-------|
| **Area** | Backend — Admin |
| **File** | `backend/internal/handlers/admin/admin_handler.go:1016-1017` |
| **Issue** | `GetSystemHealth()` returns `"healthy"` for Redis and WebSocket without actually checking connectivity. Always returns green even when services are down. |
| **Risk** | **False confidence** — ops won't know Redis/WS is down until features break |
| **Fix** | Add Redis `PING` check: `database.RedisClient.Ping(ctx)` and WS hub check (goroutine count or last broadcast time) |
| **Estimate** | ⏱ ~1 day |
| **Status** | `[ ]` Pending |
| **Verification** | Stop Redis → call `/admin/system/health` → Redis status should be `"unhealthy"` |

---

### M-04: Driver Phone Number Exposed in Tracking API

| Field | Value |
|-------|-------|
| **Area** | Backend — Tracking |
| **File** | `backend/internal/services/tracking/tracking_service.go:135` |
| **Issue** | `driverInfo.Phone = order.DeliveryPartner.Phone` returns the driver's personal phone number to any authenticated user who can track an order. PII leak. |
| **Risk** | **Privacy violation** — customer can call driver directly, bypassing app |
| **Fix** | Either: (1) Remove phone from response, (2) Return masked phone (e.g., `"98*****10"`), or (3) Use proxy number service (Twilio proxy) |
| **Estimate** | ⏱ ~1 hour for masking |
| **Status** | `[ ]` Pending |

---

### M-05: Admin Bookings Search Not Functional

| Field | Value |
|-------|-------|
| **Area** | Flutter — Admin |
| **File** | `barbar_app/lib/presentation/screens/admin/admin_bookings_screen.dart:185-189` |
| **Issue** | Search `TextField` has `onSubmitted` but the `_loadBookings()` method does NOT pass search text to the `LoadBookings` event. Search field is purely decorative — typing does nothing. |
| **Risk** | **Broken UX** — admin cannot search bookings |
| **Fix** | Add search query parameter to `LoadBookings` event and pass it through the API call |
| **Estimate** | ⏱ ~2 hours |
| **Status** | `[ ]` Pending |

---

### M-06: Admin Orders Date Range Shows Placeholder

| Field | Value |
|-------|-------|
| **Area** | Flutter — Admin |
| **File** | `barbar_app/lib/presentation/screens/admin/admin_orders_screen.dart:276` |
| **Issue** | When date range IS selected, display text shows literal string `\/\/\ - \/\/` instead of actual formatted dates. Developer placeholder never replaced. |
| **Risk** | **Broken UX** — admin cannot see selected date range |
| **Fix** | Replace placeholder string with actual formatted date range (e.g., `"${dateFrom} - ${dateTo}"`) |
| **Estimate** | ⏱ ~2 hours |
| **Status** | `[ ]` Pending |

---

### M-07: Vendor Wallet Tab is Stub

| Field | Value |
|-------|-------|
| **Area** | Flutter — Vendor |
| **File** | `barbar_app/lib/presentation/screens/vendor/vendor_main_screen.dart:32` |
| **Issue** | Wallet tab shows `Text('Wallet / Payouts coming soon')` — stub placeholder. No real UI. |
| **Risk** | **Missing feature** — vendor cannot view earnings/payouts |
| **Fix** | Implement wallet screen showing balance, transaction history, withdrawal requests. Backend endpoints already exist (`GET /vendor/dashboard`, `GET /wallet/transactions`, `POST /wallet/withdrawals`). |
| **Estimate** | ⏱ ~3–5 days |
| **Status** | `[ ]` Pending |

---

### M-08: Call Driver Button is Stub

| Field | Value |
|-------|-------|
| **Area** | Flutter — Vendor |
| **File** | `barbar_app/lib/presentation/screens/vendor/vendor_order_detail_screen.dart:201` |
| **Issue** | Call Driver button has `onPressed: () {}` — empty stub with `// TODO: Launch phone dialer` comment. |
| **Risk** | **Broken UX** — vendor cannot call driver |
| **Fix** | Add `url_launcher` to open `tel:<driver_phone>`. Driver phone is available in order detail response. |
| **Estimate** | ⏱ ~1 day |
| **Status** | `[ ]` Pending |

---

## SECTION 3: 🔵 MINOR — FIX BEFORE v1.0 STABLE

*Should fix for a polished experience but won't block launch.*

### N-01: Admin Orders Status Update Lacks State-Machine Validation

| Field | Value |
|-------|-------|
| **Area** | Flutter — Admin |
| **File** | `barbar_app/lib/presentation/screens/admin/admin_order_detail_screen.dart:75-123` |
| **Issue** | Status update dialog allows selecting ANY status from a fixed dropdown list. No validation that the transition is valid (e.g., can jump from "pending" to "delivered" directly). Backend does validate, but UI should prevent invalid options. |
| **Fix** | Filter available statuses per current status using the state machine transition map |
| **Estimate** | ⏱ ~1 day |
| **Status** | `[ ]` Pending |

---

### N-02: OTP Dev Bypass in Flutter Auth Screen

| Field | Value |
|-------|-------|
| **Area** | Flutter — Auth |
| **File** | `barbar_app/lib/presentation/screens/auth_screen.dart` |
| **Issue** | `_otpController.text = '123456'` — dev shortcut automatically fills OTP field. Should only activate in debug mode. |
| **Risk** | **Auth bypass** — anyone can bypass OTP in release builds |
| **Fix** | Wrap in `assert(() { ... }())` or `if (kDebugMode)` |
| **Estimate** | ⏱ ~30 min |
| **Status** | `[ ]` Pending |

---

### N-03: Vendor Analytics & Notification Bell Stubs

| Field | Value |
|-------|-------|
| **Area** | Flutter — Vendor |
| **File** | `barbar_app/lib/presentation/screens/vendor/vendor_main_screen.dart:70,147` |
| **Issue** | Analytics drawer item shows `"Analytics coming soon"` snackbar. Notification bell has empty `onPressed`. |
| **Fix** | Implement analytics (use existing backend endpoints) and wire notification bell to notification list |
| **Estimate** | ⏱ ~2–3 days |
| **Status** | `[ ]` Pending |

---

### N-04: No Monitoring / Alerting

| Field | Value |
|-------|-------|
| **Area** | Infrastructure |
| **Issue** | No Prometheus metrics, no Grafana dashboards, no Sentry error tracking, no uptime monitoring. Zero observability. |
| **Risk** | **Blind in production** — can't detect or diagnose issues |
| **Minimal fix** | Add Sentry SDK to Go backend + Flutter app. Add Prometheus metrics endpoint (`/metrics`). |
| **Full fix** | Prometheus + Grafana + Sentry + uptime monitor (Better Uptime / Pingdom) |
| **Estimate** | ⏱ ~1 week (minimal) to ~2 weeks (full) |
| **Status** | `[ ]` Pending |

---

### N-05: No CI/CD Pipeline

| Field | Value |
|-------|-------|
| **Area** | Infrastructure |
| **Files** | `.github/workflows/ci.yml` (exists but minimal) |
| **Issue** | No automated build, test, lint, deploy pipeline. Manual deployment only. |
| **Minimal fix** | Add `go build ./...`, `go vet ./...`, `flutter analyze`, `flutter test` to CI |
| **Full fix** | Full CD pipeline: build → test → docker build → push to registry → deploy |
| **Estimate** | ⏱ ~1 week |
| **Status** | `[ ]` Pending |

---

### N-06: No Automated Tests

| Field | Value |
|-------|-------|
| **Area** | Backend + Flutter |
| **Issue** | Only 1 integration test file exists (1300 lines, covers ~30% of critical paths). Zero unit tests for handlers or services. Zero Flutter widget tests. |
| **Priority order** | (1) Unit tests for `order_service.go` (state machine), (2) Unit tests for `booking_handler.go`, (3) Unit tests for `payment_handler.go`, (4) Flutter widget tests for critical screens |
| **Estimate** | ⏱ ~2–3 weeks (ongoing activity) |
| **Status** | `[ ]` Pending |

---

## SECTION 4: ⚪ ENHANCEMENTS — POST-LAUNCH / v2

*Valuable additions for subsequent releases.*

### E-01: Real-Time Chat System
- **Why**: Customer ↔ Driver communication during delivery; Customer ↔ Barber for booking queries
- **Requires**: WebSocket infrastructure already exists, just need chat messages model + UI
- **Estimate**: 3-4 weeks

### E-02: Loyalty Program
- **Why**: Customer retention, repeat bookings
- **Requires**: Points system, rewards catalog, redemption flow
- **Estimate**: 2-3 weeks

### E-03: Google Maps Integration
- **Why**: Better UX than OSM (street view, better POI data, turn-by-turn)
- **Requires**: Google Maps API key, replace `flutter_map` with `google_maps_flutter` (already in pubspec!)
- **Estimate**: 1 week

### E-04: Load Testing
- **Why**: Ensure system handles peak loads (New Year, festival season)
- **Requires**: k6 / Locust test scripts, staging environment
- **Estimate**: 1 week

---

## QUICK REFERENCE: ALL OPEN ITEMS

| ID | Priority | Area | Item | Effort | Status |
|----|----------|------|------|--------|--------|
| C-01 | 🔴 Critical | Backend | Wallet deduction before txn | 1 day | `[ ]` |
| C-02 | 🔴 Critical | Backend | Auto-approved refunds | 2 hours | `[ ]` |
| C-03 | 🔴 Critical | Backend | OTP bypass codes | 30 min | `[ ]` |
| C-04 | 🔴 Critical | Docker | Health check broken | 10 min | `[ ]` |
| C-05 | 🔴 Critical | Docker | `.env` in image | 10 min | `[ ]` |
| C-06 | 🔴 Critical | Backend | `utr_nnumber` typo | 10 min | `[ ]` |
| M-01 | 🟡 Major | Docker | JWT_SECRET no default | 5 min | `[ ]` |
| M-02 | 🟡 Major | Flutter | Real payment gateway | 2-3 weeks | `[ ]` |
| M-03 | 🟡 Major | Backend | Fake Redis/WS health | 1 day | `[ ]` |
| M-04 | 🟡 Major | Backend | Driver phone PII leak | 1 hour | `[ ]` |
| M-05 | 🟡 Major | Flutter | Admin bookings search | 2 hours | `[ ]` |
| M-06 | 🟡 Major | Flutter | Admin orders date range | 2 hours | `[ ]` |
| M-07 | 🟡 Major | Flutter | Vendor wallet tab stub | 3-5 days | `[ ]` |
| M-08 | 🟡 Major | Flutter | Call Driver button stub | 1 day | `[ ]` |
| N-01 | 🔵 Minor | Flutter | State-machine validation | 1 day | `[ ]` |
| N-02 | 🔵 Minor | Flutter | OTP dev bypass | 30 min | `[ ]` |
| N-03 | 🔵 Minor | Flutter | Vendor analytics/notif stubs | 2-3 days | `[ ]` |
| N-04 | 🔵 Minor | Infra | No monitoring | 1-2 weeks | `[ ]` |
| N-05 | 🔵 Minor | Infra | No CI/CD | 1 week | `[ ]` |
| N-06 | 🔵 Minor | Both | No automated tests | 2-3 weeks | `[ ]` |
| E-01 | ⚪ Enhancement | Both | Real-time chat | 3-4 weeks | `[ ]` |
| E-02 | ⚪ Enhancement | Both | Loyalty program | 2-3 weeks | `[ ]` |
| E-03 | ⚪ Enhancement | Flutter | Google Maps | 1 week | `[ ]` |
| E-04 | ⚪ Enhancement | Infra | Load testing | 1 week | `[ ]` |

---

## TOTAL ESTIMATED EFFORT

| Category | Count | Total Effort |
|----------|-------|-------------|
| 🔴 Critical | 6 | ~2 days |
| 🟡 Major | 8 | ~4–5 weeks |
| 🔵 Minor | 6 | ~4–5 weeks |
| ⚪ Enhancement | 4 | ~7–10 weeks |
| **Pre-launch total** | **14** (C + M) | **~4–6 weeks** |
| **All items total** | **24** | **~16–22 weeks** |

---

## WEEK-BY-WEEK LAUNCH PLAN

### Week 1: Critical Fixes
- [ ] C-01: Wallet transaction fix
- [ ] C-02: Refund moderation
- [ ] C-03: OTP bypass removal
- [ ] C-04: Docker health check
- [ ] C-05: .env fix
- [ ] C-06: UTR typo fix
- [ ] M-01: JWT_SECRET check

### Week 2: Features + Flutter Bugs
- [ ] M-05: Admin bookings search
- [ ] M-06: Admin orders date range
- [ ] M-07: Vendor wallet tab
- [ ] M-08: Call Driver button
- [ ] N-01: State-machine validation
- [ ] N-02: OTP dev bypass
- [ ] N-03: Vendor analytics/notif

### Week 3: Payment Gateway
- [ ] M-02: Real payment integration

### Week 4: Infrastructure
- [ ] M-03: Real health checks
- [ ] M-04: Driver phone masking
- [ ] N-04: Monitoring setup
- [ ] N-05: CI/CD pipeline

### Week 5-6: Testing + Hardening
- [ ] N-06: Automated tests
- [ ] Load testing
- [ ] Security audit
- [ ] Production deployment

---

## VERIFICATION CHECKLIST (Pre-Launch)

*Run these checks before every production deployment.*

### Backend
- [ ] `go build ./...` — zero errors
- [ ] `go vet ./...` — zero warnings
- [ ] `go test ./...` — all tests pass
- [ ] All 6 critical bugs confirmed fixed in code
- [ ] Health endpoint reports accurate status for all 5 components

### Flutter
- [ ] `flutter analyze` — zero errors
- [ ] `flutter test` — all tests pass
- [ ] Payment flow works end-to-end with real gateway
- [ ] No OTP bypass in release builds
- [ ] All placeholder/stub screens have real implementations

### Infrastructure
- [ ] Docker health check passes
- [ ] No secrets in Docker image (`docker history` check)
- [ ] JWT_SECRET is configured in production environment
- [ ] Database backups configured
- [ ] Monitoring alerts configured

### Security
- [ ] No hardcoded secrets in code
- [ ] No bypass codes in production code
- [ ] All API endpoints enforce authentication
- [ ] CORS configured for production domain only
- [ ] Rate limiting enabled on all critical endpoints
- [ ] Session tokens expire and can be revoked

---

## LAUNCH GATE CHECKLIST

*All items below must be **checked and passing** before production launch.*

- [ ] **Gate 1**: All 🔴 Critical items resolved
- [ ] **Gate 2**: All 🟡 Major items resolved  
- [ ] **Gate 3**: All 🔵 Minor items resolved OR acknowledged with tracking tickets
- [ ] **Gate 4**: Product owner signs off on remaining ⚪ items as post-launch
- [ ] **Gate 5**: Verified with `flutter analyze` + `go build` + `go vet`
- [ ] **Gate 6**: Staging deployment tested with real payment sandbox
- [ ] **Gate 7**: Load test passed (500 concurrent users minimum)
- [ ] **Gate 8**: Security scan completed (dependency vulns + secret scan)
- [ ] **Gate 9**: Database backup + restore tested
- [ ] **Gate 10**: Rollback plan documented

---

## GO / NO-GO DECISION

| Check | Status |
|-------|--------|
| All Critical fixed? | ❌ 0/6 |
| All Major fixed? | ❌ 0/8 |
| All Minor addressed? | ❌ 0/6 |
| Staging tests passed? | ❌ |
| Security scan passed? | ❌ |
| **Decision** | **NO-GO** |
| **Estimated Ready** | **~2-3 weeks** |

---
*End of Production Release Checklist*
