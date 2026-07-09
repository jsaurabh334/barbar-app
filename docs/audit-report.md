# Audit Report — Barbar App

> Generated: 2026-07-09
> Coverage: Sprint 7 (Booking System) + Sprint 8 (Reviews Phase 1 & 2)

---

## Build Status

| Layer | Check | Result |
|-------|-------|--------|
| Backend | `go build ./...` | ✅ Pass |
| Backend | `go vet ./...` | ✅ Pass |
| Flutter | `flutter analyze` | ✅ Pass (0 new issues) |
| Backend Tests | `go test ./tests/ -count=1 -timeout 60s` | ✅ Pass |

---

## 1. Booking System Fixes (Sprint 7)

### 1.1 Race Condition Fix
- **File**: `backend/internal/handlers/booking/booking_handler.go:271-279`
- **What**: Added `pg_advisory_xact_lock(hashtext(lockKey))` before `SELECT ... FOR UPDATE`
- **Why**: Prevents concurrent double-booking when GORM's `FOR UPDATE` can't lock non-existent rows
- **Risk**: Low — advisory lock is per-connection, auto-released on transaction commit/rollback

### 1.2 Service Belonging Validation
- **File**: `backend/internal/handlers/booking/booking_handler.go:189-192`
- **What**: Added `len(services) != len(req.ServiceIDs)` check
- **Why**: Rejects bookings with services not owned by the selected barber
- **Risk**: Low — straightforward length comparison

### 1.3 WebSocket Reconnection Sync
- **File**: `barbar_app/lib/presentation/screens/queue_tracker_screen.dart:56-63`
- **What**: `connectionStatus` listener dispatches `CheckQueuePosition` on false→true transition
- **Why**: Re-syncs queue state via REST API after WS reconnect
- **Risk**: Low — guarded by `old == false && current == true`

### 1.4 Queue Payload Enhancement
- **File**: `backend/internal/services/queue/queue_service.go:125-174`
- **What**: Added `people_ahead`, `remaining_time`, `currently_serving` to WS broadcast
- **Flutter**: Updated `StreamQueuePositionUpdate`, `QueuePositionLoaded`, `_buildDetailsCard`
- **Risk**: Low — additive change, backwards compatible

### 1.5 Concurrency & Integration Tests
- **File**: `backend/tests/integration_test.go`
- **Test cases added**:
  - `TestConcurrentBookingSameSlot` — 50 parallel → 1 success
  - `TestConcurrentBookingDifferentSlots` — 3 slots → 3 success
  - `TestServiceBelongsToBarber` — foreign service → 400
  - `TestQueueProgress` — status transitions advance queue
  - `TestCancelDuringQueue` — cancel promotes next in line
  - `TestNoShowPromotion` — no-show promotes next
- **Risk**: Low — tests only, no production code

---

## 2. Reviews Phase 1 (Backend)

### 2.1 Data Model (New Files)
- **File**: `backend/internal/models/review.go`
- `Review` — core model with BookingID, CustomerID, ShopID, StaffID, Rating, Comment, IsAnonymous, Status
- `ReviewImage` — separate table (future-proof for delete/reorder/CDN)
- `ReviewReply` — Sprint 10 ready
- `ReviewReport` — Phase 2 addition
- `RatingDistribution` — JSONB for star counts
- `IsReviewWindowValid()` — 30-day window check
- **Migration**: `backend/internal/database/postgres.go` — all 4 models registered in AutoMigrate

### 2.2 Rating Service (New File)
- **File**: `backend/internal/services/review/rating_service.go`
- `RecalculateShopRating(shopID)` — `SELECT AVG(rating)` + `COUNT(*) FILTER(WHERE rating = N)`
- Updates `barber.rating`, `barber.review_count`, `barber.rating_distribution` atomically
- **Risk**: Low — called only on moderate actions; not cached (fine at current scale)

### 2.3 Barber Model Update
- **File**: `backend/internal/models/barber.go:47`
- Added `RatingDistribution datatypes.JSON` field

### 2.4 Review Handler (New File)
- **File**: `backend/internal/handlers/review/review_handler.go`
- **Endpoints**:

| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| POST | `/reviews` | Customer | Create review |
| PUT | `/reviews/:id` | Customer | Edit pending review |
| POST | `/reviews/:id/report` | Customer | Report review |
| PUT | `/admin/reviews/:id/moderate` | Admin | Approve/reject/hide |
| GET | `/admin/reviews` | Admin | List all reviews |
| GET | `/reviews/mine` | Customer | List my reviews |
| GET | `/public/barbers/:id/reviews` | Public | List approved reviews |
| GET | `/public/barbers/:id/rating-summary` | Public | Rating summary |
| POST | `/barber/reviews/:id/reply` | Barber | Reply to review |

- **Validation chain**: JWT ownership → completed status → paid status → 30-day window → duplicate check → rating 1-5 → comment 10-1000 → max 5 images

### 2.5 Notification Constants
- **File**: `backend/internal/models/notification.go`
- Added `NotifReviewReceived`, `NotifReviewModerated`

### 2.6 Routes Registered
- **File**: `backend/internal/routes/routes.go`
- 3 public routes (review list + rating summary)
- 4 customer routes (create, list mine, edit, report)
- 1 barber route (reply)
- 2 admin routes (list all, moderate)

---

## 3. Reviews Phase 1 (Flutter)

### 3.1 Data Layer (New Files)
- **File**: `lib/data/models/review_model.dart`
  - `ReviewModel` — id, bookingId, shopId, staffId, rating, comment, isAnonymous, images, reply
  - `ReviewImageModel` — id, url, thumbnail, sortOrder
  - `ReviewSummaryModel` — avgRating, totalReviews, distribution
  - `RatingDistribution` — star1..star5 counts

- **File**: `lib/data/datasources/remote/review_remote_datasource.dart`
  - `createReview`, `getPublicReviews`, `getShopRatingSummary`, `getMyReviews`, `updateReview`, `reportReview`

- **File**: `lib/data/repositories/review_repository_impl.dart`
  - Wraps remote data source

- **File**: `lib/domain/repositories/review_repository.dart`
  - Abstract interface

### 3.2 BLoC (New Files)
- **File**: `lib/presentation/bloc/review/review_event.dart`
  - `CreateReview`, `UpdateReview`, `FetchPublicReviews`, `FetchShopRatingSummary`, `FetchMyReviews`
- **File**: `lib/presentation/bloc/review/review_state.dart`
  - `ReviewInitial`, `ReviewLoading`, `ReviewCreated`, `ReviewUpdated`, `PublicReviewsLoaded`, `ShopRatingSummaryLoaded`, `MyReviewsLoaded`, `ReviewFailure`
- **File**: `lib/presentation/bloc/review/review_bloc.dart`
  - 5 event handlers

### 3.3 Screens (New Files)
- **File**: `lib/presentation/screens/review_screen.dart`
  - Write/edit review form with rating bar, comment field, anonymous toggle
  - Dynamic placeholder based on rating value
  - Supports both create and edit mode
- **File**: `lib/presentation/screens/review_list_screen.dart`
  - Paginated review list with sort (newest/highest/lowest)
  - Summary header card with star distribution
  - Report review functionality via dialog

### 3.4 Widgets (New Files)
- **File**: `lib/presentation/widgets/rating_bar.dart`
  - Tappable 5-star widget with label per rating level
- **File**: `lib/presentation/widgets/review_card.dart`
  - Display with verified badge, relative time, star rating
  - Shop reply section if present
  - Report button (three-dot menu)
- **File**: `lib/presentation/widgets/review_summary_card.dart`
  - Average rating + star distribution bars
  - "View All Reviews" link

### 3.5 DI Registration
- **File**: `lib/main.dart`
  - `ReviewRemoteDataSource`, `ReviewRepositoryImpl`, `ReviewRepository`, `ReviewBloc` registered
  - `ReviewRepository` also registered as `RepositoryProvider` for direct access

---

## 4. Reviews Phase 2 (Navigation Wiring)

### 4.1 Booking History → Review
- **File**: `lib/presentation/screens/booking_history_screen.dart`
- **Changes**:
  - Imported `ReviewScreen`
  - Added `shopName` field to `BookingModel` (parsed from `barber.shop_name`)
  - "Write a Review" button shown for completed + paid bookings
  - Navigates to `ReviewScreen` with `bookingId` and `shopName`

### 4.2 Shop Detail → Review List
- **File**: `lib/presentation/screens/barber_detail_screen.dart`
- **Changes**:
  - Imported `ReviewListScreen`
  - Rating badge wrapped in `InkWell` → navigates to `ReviewListScreen(shopId, shopName)`
  - Chevron icon added for visual affordance

### 4.3 Admin Console Integration
- **File**: `lib/presentation/screens/admin_console_screen.dart`
- **Changes**:
  - Tab length 7→8
  - "Reviews" drawer item added (index 5)
  - `AdminReviewModerationScreen` added to tab bar view
- **File**: `lib/presentation/screens/admin/admin_review_moderation_screen.dart` (New)
  - Lists reviews with status filter
  - Approve/reject buttons for pending reviews
  - Paginated, pull-to-refresh

### 4.4 Admin Repository
- **File**: `lib/domain/repositories/admin_repository.dart`
  - Added `getAllReviews()`, `moderateReview()`
- **File**: `lib/data/datasources/admin_remote_data_source.dart`
  - Added `getAllReviews()`, `moderateReview()` — hits `/admin/reviews` and `/admin/reviews/:id/moderate`
- **File**: `lib/data/repositories/admin_repository_impl.dart`
  - Delegates to remote data source

### 4.5 Booking Model Augmentation
- **File**: `lib/data/models/booking_model.dart`
- **Changes**:
  - Added `shopName` field
  - Parsed from `json['barber']['shop_name']` in `fromJson`
  - Added to `toJson()` and `copyWith()`

---

## 5. Backend Test Coverage

| Test | File | Status |
|------|------|--------|
| TestConcurrentBookingSameSlot | tests/integration_test.go | ✅ |
| TestConcurrentBookingDifferentSlots | tests/integration_test.go | ✅ |
| TestServiceBelongsToBarber | tests/integration_test.go | ✅ |
| TestQueueProgress | tests/integration_test.go | ✅ |
| TestCancelDuringQueue | tests/integration_test.go | ✅ |
| TestNoShowPromotion | tests/integration_test.go | ✅ |
| TestCreateReview | tests/integration_test.go | ✅ |
| TestCreateReviewNotCompleted | tests/integration_test.go | ✅ |
| TestCreateReviewDuplicate | tests/integration_test.go | ✅ |
| TestModerateReview | tests/integration_test.go | ✅ |
| TestListPublicReviews | tests/integration_test.go | ✅ |

---

## 6. File Inventory

### New Files (Backend)
| File | Purpose |
|------|---------|
| `backend/internal/models/review.go` | Review, ReviewImage, ReviewReply, ReviewReport models |
| `backend/internal/handlers/review/review_handler.go` | All review HTTP handlers |
| `backend/internal/services/review/rating_service.go` | Rating recalculation service |

### New Files (Flutter)
| File | Purpose |
|------|---------|
| `lib/data/models/review_model.dart` | Review, ReviewImage, ReviewSummary, RatingDistribution models |
| `lib/data/datasources/remote/review_remote_datasource.dart` | API calls for reviews |
| `lib/data/repositories/review_repository_impl.dart` | Repository implementation |
| `lib/domain/repositories/review_repository.dart` | Repository interface |
| `lib/presentation/bloc/review/review_event.dart` | BLoC events |
| `lib/presentation/bloc/review/review_bloc.dart` | BLoC logic |
| `lib/presentation/bloc/review/review_state.dart` | BLoC states |
| `lib/presentation/screens/review_screen.dart` | Write/edit review form |
| `lib/presentation/screens/review_list_screen.dart` | Paginated review list |
| `lib/presentation/screens/admin/admin_review_moderation_screen.dart` | Admin moderation UI |
| `lib/presentation/widgets/rating_bar.dart` | Star rating widget |
| `lib/presentation/widgets/review_card.dart` | Review display card |
| `lib/presentation/widgets/review_summary_card.dart` | Rating summary card |

### Modified Files (Backend)
| File | Changes |
|------|---------|
| `backend/internal/database/postgres.go` | Added ReviewReply, ReviewReport to AutoMigrate |
| `backend/internal/handlers/booking/booking_handler.go` | Race condition fix, service validation |
| `backend/internal/models/barber.go` | Added RatingDistribution JSONB |
| `backend/internal/models/notification.go` | Added review notification constants |
| `backend/internal/routes/routes.go` | 9 review routes |
| `backend/internal/services/queue/queue_service.go` | Enhanced WS payload |
| `backend/tests/integration_test.go` | 11 test functions |

### Modified Files (Flutter)
| File | Changes |
|------|---------|
| `lib/data/models/booking_model.dart` | Added shopName field |
| `lib/data/datasources/admin_remote_data_source.dart` | Review management methods |
| `lib/data/repositories/admin_repository_impl.dart` | Review management delegation |
| `lib/domain/repositories/admin_repository.dart` | Review management interface |
| `lib/main.dart` | Review DI registration |
| `lib/presentation/screens/booking_history_screen.dart` | Write Review button |
| `lib/presentation/screens/barber_detail_screen.dart` | Review list navigation |
| `lib/presentation/screens/admin_console_screen.dart` | Reviews tab |
| `lib/presentation/screens/queue_tracker_screen.dart` | WS reconnection sync |

---

## 7. Risk Assessment

| Area | Risk | Mitigation |
|------|------|------------|
| Advisory lock | Low | Auto-released on tx commit; scoped to barber+slot hash |
| Rating recalculation | Low | Called only on moderate; fine at current volume |
| Review window (30 days) | Low | Hard constant, easy to change |
| WS reconnection sync | Low | Guarded by false→true transition check |
| Image upload | Not implemented | Phase 2 remaining item |
| Edit review | Low | Validates pending status + ownership |
| Barber reply | Low | Validates barber ownership + approved review |
| Report review | Low | Validates no self-report + no duplicate |
| Migration safety | Low | All models in AutoMigrate, no destructive changes |

---

## 8. Remaining Work

- **Image Upload** — multipart endpoint + Flutter image picker + preview in review form
