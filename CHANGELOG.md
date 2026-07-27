# Changelog

All notable changes to the Barbar App project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0-RC1] — 2026-07-23

### Added
- Admin booking management (list, detail, cancel, reschedule, timeline)
- Admin order management (list with filters, detail, status transitions, timeline, driver assignment)
- Delivery partner system (register, KYC, bank accounts, earnings, presence tracking)
- Delivery OTP verification (pickup + delivery with HMAC-SHA256 hashing)
- Wallet system with locked/available balance
- Withdrawal requests with admin approval workflow
- Settlement processing with UTR tracking
- Real-time WebSocket notifications for order/booking status changes
- FCM push notifications for all major events
- Multi-language notification templates (EN + HI)
- Admin campaigns (create, schedule, send, stats)
- CMS pages and FAQ management
- Banner management (CRUD + toggle)
- Coupon/promotion management
- Review system (customer write/edit, admin moderate, public display)
- Barber queue tracking and wait time management
- Analytics/reports dashboard (bookings, revenue, orders, customers, barbers, delivery)
- Staff management for barber shops
- Home service support with radius-based pricing
- Warehouse and inventory management for vendors

### Changed
- Seed script refactored into modular files with per-feature flags (`--admin`, `--catalog`, `--demo-vendor`, `--demo-delivery`, `--lookup`, `--notifications`, `--settings`, `--reset`, `--all`)
- Seed operations are now independently idempotent and additive

### Fixed
- OTP storage: HMAC-SHA256 hash truncated at 64 chars in `varchar(10)` column — increased to `varchar(128)`
- Wallet list: `GET /admin/wallets` returned `data: null` despite 27 wallets existing — GORM slice initialization fix
- Frozen wallet: credit/debit operations bypassed `IsActive` check — added guard in both handlers
- Double settlement processing: missing status check allowed re-processing — added status guard
- Column name mismatch: `utr_nnumber` → `utr_number` in settlement processing
- Missing AutoMigrate: `purchases`, `delivery_earnings`, `delivery_presence_logs` tables not created
- State machine: `OrderStatusProcessing` not in `AllowedTransitions` — seed orders stuck in "processing"
- Vendor warehouse response: empty `vendor` object due to non-pointer struct — changed to `*Vendor`
- CMS: `GET /admin/cms` returned 400 when called without `type` param
- `final_amount` floating-point precision: 499 + 89.82 = 588.8199999999999 instead of 588.82
- Booking `home_service_address` stored as JSON string instead of proper nested object
- Wallet transactions not populated on booking creation
- Docker image must be rebuilt after code changes — added to deploy checklist

### Security
- OTP: HMAC-SHA256 hashing with `crypto/rand` generation, constant-time compare (`crypto/subtle`), Redis attempt limits (max 5, 5 min TTL), bypass code `"123456"` removed
- Tokens: refresh token rotation + reuse revocation, SHA-256 hash in DB, session invalidation on password change
- Authorization: UUID parsing on all admin/customer endpoints (4), fixed 19 bare `ShouldBindJSON` calls across 6 files, ownership verified on barber/delivery/vendor handlers
- Secrets: JWT default fallback removed with `Validate()` fast-fail, CORS default `*` → `` (deny), `.gitignore` for `ssl/` + `docker-compose.override.yml`

## [0.7.0] — 2026-07-09

### Added
- Review system Phase 1 & 2 (customer write/edit, admin moderate, public display)
- Booking system Sprint 7 (race condition fix with `pg_advisory_xact_lock`)
- Service belonging validation on booking creation

### Fixed
- Race condition in concurrent double-booking: added `pg_advisory_xact_lock(hashtext(lockKey))` before `SELECT ... FOR UPDATE`
- Rejected bookings with services not owned by the selected barber

## [0.6.0] — 2026-07-02

### Added
- Review system initial implementation
- Admin moderation for reviews (approve/reject with reason)
- Public review display on barber shop detail pages
- Rating distribution calculation

## [0.5.0] — 2026-06-25

### Added
- Order management system
- Delivery partner system
- Vendor order workflow
- Admin order management
- Driver assignment and dispatch
- Real-time order tracking

## [0.4.0] — 2026-06-18

### Added
- Payment gateway integration (Razorpay, Stripe)
- Wallet system with transactions
- Refund processing
- Commission tracking
- Platform fee configuration

## [0.3.0] — 2026-06-11

### Added
- Admin panel with user management
- Vendor approval workflow
- Banner management (CRUD + toggle)
- CMS page management
- Coupon/promotion management
- Analytics dashboard

## [0.2.0] — 2026-06-04

### Added
- Booking system with queue management
- Barber shop detail view
- Service selection and pricing
- Booking cancellation and rescheduling
- Barber queue tracking

## [0.1.0] — 2026-05-28

### Added
- Initial platform setup
- Authentication with OTP
- JWT token-based sessions
- User roles (customer, barber, vendor, admin, delivery)
- Product catalog with categories
- Barber shop profiles
- Seed script for demo data
- Basic API structure with Gin + GORM
- Postgres database with migrations
- Redis integration
- Firebase Cloud Messaging setup
