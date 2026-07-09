## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, invoke the `skill` tool with `skill: "graphify"` before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

## Release Roadmap

> Feature Freeze + Release Milestones approach.

### ✅ Release 1.0 (Customer) — FEATURE FROZEN 🎉

| Feature | Status |
|---------|--------|
| Authentication (OTP/JWT) | ✅ |
| Discovery (Map + List) | ✅ |
| Shop Details | ✅ |
| Booking (Create/Queue/Cancel) | ✅ |
| Queue Tracking (WS + REST) | ✅ |
| Reviews (Write/List/Moderate/Report) | ✅ |
| Review Image Upload | ✅ |
| Marketplace (Products/Cart/Order) | ✅ |
| Profile (Address/Wallet) | ✅ |

**Freeze Rule**: Only bug/security/performance fixes. No new features.

### 🔄 Sprint R1 — Regression Testing
Before starting Release 1.1, run full regression:
- Backend: all API flows (auth, booking, queue, reviews, marketplace, profile)
- Flutter: all screens (login, home, shop, booking, review, marketplace, profile)
- Technical: `go build`, `go vet`, `go test`, `flutter analyze`, `flutter test`, `graphify update .`
- **Exit**: 0 critical bugs, 0 data loss, 0 security issues, 0 crashes, all tests pass
- **Outcome**: Tag **Release 1.0 — Stable**

### 🔜 Release 1.1 (Execution Order — post R1)
| Sprint | Feature | Est. |
|--------|---------|------|
| 9.1 | **Amenities** ⭐ | 2-3 days |
| 9.2 | **Home Service** ⭐⭐ | 4-5 days |
| 9.3 | **Barber Staff** ⭐⭐⭐⭐⭐ | 2-3 weeks |
| 9.4 | **Family Booking** ⭐⭐⭐ | 3-4 days |

### 🔜 Release 2.0
- **Phase 1**: Multi-Staff Booking, Staff Schedule, Staff Queue, Staff Holidays
- **Phase 2**: Loyalty, Referral, Membership
- **Phase 3**: AI Recommendations

### 🔜 Release 3.0+
- Barber Dashboard, Vendor Dashboard, Delivery Module
- Admin Analytics, Production Hardening

---

## Review Lifecycle (Customer → Admin → Public)

### Customer Flow

```
Customer Login
      │
      ▼
Book Appointment → Queue Tracking → Service Started
      │
      ▼
Service Completed → Payment Successful
      │
      ▼
Booking Status = COMPLETED
      │
      ▼
Booking History (History Tab) → [ Write Review ]
      │
      ▼
Review Screen: ⭐ Rating (1-5) + Comment + Images (Max 5)
      │
      ▼
POST /api/v1/reviews → Status = Pending
```

### Backend Validation Chain

```
JWT → booking_id → Booking exists? → Own booking? → Completed? → Paid? 
  → Already reviewed? → Window valid? → Rating 1-5 → Comment 10-1000 
  → Max 5 images → Save Review → Notifications
```

**Security**: Flutter sends only `booking_id`, `rating`, `comment`, `images`.
`customer_id`, `shop_id`, `staff_id` are extracted from booking record server-side.

### Customer Status UI

| State | Booking Card Shows |
|-------|-------------------|
| Before review | `[ Write Review ]` button |
| After submit | "🟡 Pending Approval" + `[ Edit Review ]` |
| After approval | "✔ Approved" + `[ View Review ]` |
| After rejection | "❌ Rejected + Reason" + `[ Edit & Resubmit ]` |

### Admin Moderation

```
Admin Console → Reviews tab → Pending review → Approve / Reject
  → Approve: status=approved, recalculate rating, notify customer + shop owner
  → Reject: status=rejected, save reason, notify customer with reason
```

### Public Display

```
Shop Detail → tap rating badge → GET /public/barbers/{shopId}/reviews
  → Returns ONLY approved reviews → ReviewListScreen
```

### Review Status State Machine

```
Pending → Approved (public)
Pending → Rejected (customer can edit & resubmit → pending again)
```

### Notification Matrix

| Trigger | Customer | Shop Owner | Admin |
|---------|----------|------------|-------|
| Review submitted | ✅ | ✅ | ✅ |
| Review approved | ✅ | ✅ | — |
| Review rejected | ✅ (with reason) | — | — |

### Release 1.0 Exit Criteria (Updated)
- [x] Review creation
- [x] Review editing
- [x] Review moderation
- [x] Review reporting
- [x] Review lifecycle (Pending → Approved → Public)
- [x] Customer review status tracking
- [x] Admin moderation workflow
- [x] Notifications
- [ ] Review image upload (last pending feature)

### ✅ Release 1.0 (Customer) — FEATURE FROZEN 🎉

| Feature | Status |
|---------|--------|
| Authentication (OTP/JWT) | ✅ |
| Discovery (Map + List) | ✅ |
| Shop Details | ✅ |
| Booking (Create/Queue/Cancel) | ✅ |
| Queue Tracking (WS + REST) | ✅ |
| Reviews (Write/List/Moderate/Report) | ✅ |
| Review Image Upload | ✅ |
| Marketplace (Products/Cart/Order) | ✅ |
| Profile (Address/Wallet) | ✅ |

> **Feature Freeze**: Only bug/security/performance fixes allowed.
> Next: Regression Testing Sprint → Stable tag.

### 🔄 Sprint R1 — Regression Testing (Customer Release 1.0)
- [ ] Backend API tests (all flows)
- [ ] Flutter UI tests (all screens)
- [ ] `go build ./...`, `go vet ./...`, `go test ./...`
- [ ] `flutter analyze`, `flutter test`
- [ ] Tag: **Release 1.0 — Stable**

### ✅ Release 1.1 (Execution Order — after R1)
1. **Amenities** ⭐— WiFi, Parking, AC, Coffee, Card Payment (isolated, no booking impact)
2. **Home Service** ⭐⭐— address validation, service radius, travel charges, slot calc
3. **Barber Staff** ⭐⭐⭐⭐⭐— architectural change: Shop → Staff → Queue → Booking
4. **Family Booking** ⭐⭐⭐— multi-person single slot (easy after Staff)

### ✅ Release 2.0
- **Phase 1**: Multi-Staff Booking, Staff Schedule, Staff Holidays, Staff Queue
- **Phase 2**: Loyalty Program, Referral, Membership
- **Phase 3**: AI Recommendation (personalized barber/product)

### ✅ Release 3.0+ (Role-wise Development)
- **Barber Dashboard**: Appointments, Queue, Revenue, Staff, Reviews, Working Hours
- **Vendor Dashboard**: Inventory, Orders, Products, Coupons, Analytics
- **Delivery Module**: Live Tracking, ETA, OTP Delivery, Maps
- **Admin Finalization**: Finance, Reports, Subscriptions, Moderation, Analytics
- **Production Hardening**: Performance, Security, Monitoring, Crash Reporting, Backup, CI/CD

## Feature Freeze Rules
Once a module reaches Feature Freeze, only **Bug**, **Security**, and **Performance** fixes allowed:
- ✅ **Booking Frozen**
- ✅ **Reviews Frozen** (after Image Upload)

## Build Checklist (Every Sprint/Merge)
```
go build ./...
go vet ./...
go test ./...
flutter analyze
flutter test
graphify update .
```

## Current Completion (Estimated)
| Module   | Progress |
|----------|---------:|
| Customer | 99% (Review Image Upload pending) |
| Barber   | 80% |
| Vendor   | 75% |
| Delivery | 60% |
| Admin    | 85% |

## Constraints
- **Booking system frozen** — no new features
- **Reviews frozen after image upload** — no new features
- Barber Staff module only after Customer Release 1.0 freeze
- All new features must pass `flutter analyze` (0 new errors), `go build`, `go vet`
