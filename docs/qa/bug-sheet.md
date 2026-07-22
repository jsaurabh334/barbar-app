# Bug Sheet — Barbar App

| ID | Module | Bug | Priority | Status | Reported | Notes |
| -- | ------ | --- | -------- | ------ | -------- | ----- |
| B1 | CMS | `GET /admin/cms` returns 400 when called without `type` query param — ListCmsPages handler expects `type` but it's not required in route definition | Medium | Open | 2026-07-22 | Backend handler should provide default or make `type` optional |
| B2 | Orders | `final_amount` has floating-point precision issue: 499 + 89.82 = 588.8199999999999 instead of 588.82 | Low | Open | 2026-07-22 | Should use decimal rounding |
| B3 | Booking | `home_service_address` stored as JSON string in struct instead of being a proper nested object | Low | Open | 2026-07-22 | Cosmetic for API, but Flutter parsing may fail |
| B4 | Wallet | No wallet transactions exist for customers despite bookings being made | Medium | Open | 2026-07-22 | Wallet not being populated on booking creation |
| B5 | Booking | `payment_status` stays "pending" for all 12 bookings — no payment flow ever completed | High | Open | 2026-07-22 | Either seed data issue or payment integration gap |
| B6 | Admin | Orders endpoint returned 404 until Docker image was rebuilt — running container was outdated | Medium | Fixed | 2026-07-22 | Docker image must be rebuilt after code changes; add to CI/deploy checklist |
| B7 | Wallet | `GET /admin/wallets` returns `data: null` even though `total: 27` wallets exist | Medium | Fixed | 2026-07-22 | Fixed: query now uses `[]*models.Wallet` for GORM, then maps to WalletRecord for response |
| B8 | Booking | Admin cancel booking returns `400` when payload is empty — may need proper request validation | Low | Open | 2026-07-22 | Test with proper payload to confirm |
| B9 | Auth | Customer OTP verification fails — DB column `users.otp` was `varchar(10)` but HMAC-SHA256 hash is 64 chars → truncated | High | Fixed | 2026-07-22 | Changed to `varchar(128)` + ALTER COLUMN; also added `[DEV_OTP]` logging to server stdout |
| B10 | Promotions | `GET /admin/coupons` returns empty list — need to verify create/update/delete flow end to end | Medium | Open | 2026-07-22 | Test with creating a coupon |
| B11 | Vendor/Purchases | `purchases` table missing from AutoMigrate — `POST /vendor/purchases` returns 500 "relation does not exist" | Medium | Fixed | 2026-07-22 | Added `&models.Purchase{}` to AutoMigrate list |
| B12 | Vendor/Warehouses | Empty `vendor` object in warehouse response — `omitempty` didn't work on non-pointer struct | Low | Fixed | 2026-07-22 | Changed `Vendor Vendor` → `*Vendor` so omitempty fires |
| B13 | Orders | `OrderStatusProcessing` defined in model but not in `AllowedTransitions` state machine — one seed order stuck in "processing" | Low | Open | 2026-07-22 | Add `processing` to state machine or remove dead status |

**Legend:** High / Medium / Low | Open / In Progress / Fixed / Verified / Won't Fix
