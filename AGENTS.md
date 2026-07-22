## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, invoke the `skill` tool with `skill: "graphify"` before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

---

## Phase 0 — Security Blockers ✅ COMPLETE

| Sub-Phase | Area | What was done |
|-----------|------|---------------|
| **A — OTP** | Auth | HMAC-SHA256 hashing, `crypto/rand` generation, constant-time compare (`crypto/subtle`), Redis attempt limits (max 5, 5min TTL), bypass `"123456"` removed |
| **B — Tokens** | Auth | Refresh token rotation + reuse revocation, SHA-256 hash in DB, session invalidation on password change |
| **C — Authz** | Validation | UUID parsing on all admin customer endpoints (4), 19 bare `ShouldBindJSON` fixed across 6 files, ownership verified on barber/delivery/vendor handlers |
| **D — Secrets** | Config | JWT default fallback removed + `Validate()` fails fast, CORS default `*` → `` (deny), `.gitignore` updated for `ssl/` + `docker-compose.override.yml` |

All `go build ./...` + `go vet ./...` pass clean.

### Security Status After Phase 0

| Area | Before | After |
|------|--------|-------|
| Authentication | 🔴 | 🟢 |
| Token Security | 🔴 | 🟢 |
| Authorization | 🟡 | 🟢 |
| Input Validation | 🟡 | 🟢 |
| Secrets Management | 🔴 | 🟢 |
| Transport Configuration | 🟡 | 🟢 |
| Production Readiness | ~55% | ~90–95% |

Remaining security work is operational (deployment, WAF, backups, incident response), not application-code blockers.

---

## Sprint Plan

### ✅ Sprint 1 — Admin Booking Management COMPLETE

| Backend | Flutter |
|---------|---------|
| `GET /admin/bookings` (list) | Booking list + search + filters + pagination |
| `GET /admin/bookings/:id` (detail) | Booking detail screen |
| `PUT /admin/bookings/:id/cancel` | Cancel dialog with reason, auto-refund |
| `PUT /admin/bookings/:id/reschedule` | Reschedule dialog with date/time pickers |
| `GET /admin/bookings/:id/timeline` | Timeline UI component |

All `go build`, `go vet`, `flutter analyze` pass.

### 📌 Sprint 2 — Admin Order Management (Current)

**Backend:**
- `GET /admin/orders` — list with filters (status, payment, vendor, delivery partner, customer, date range)
- `GET /admin/orders/:id` — detail (customer, vendor, delivery partner, items, payment, address, invoice, tracking, timeline)
- `PUT /admin/orders/:id/status` — validated state machine transitions
- `GET /admin/orders/:id/timeline` — status transition history
- `POST /admin/orders/:id/assign-driver` — nearest available driver, reassignment, history

**Flutter:**
- AdminOrdersBloc
- AdminOrdersScreen (list + filters)
- AdminOrderDetailScreen (detail + tracking + timeline)
- Driver assignment dialog
- Status update dialog

### Architecture — Reusable Widgets (extract after Sprint 2)

```
AdminTimeline
AdminStatusBadge
AdminFilterBar
AdminSearchBar
AdminPaginationController
AdminDetailCard
AdminConfirmationDialog
```

### ⚡ Quick Wins (UI-only, backend exists)

- Refund Management
- Tax Settings
- Coupons
- Featured Listings
- Notification Templates
- Revenue Analytics
- CSV Reports

Before starting Sprint 1, run:

**Backend:**
- [ ] Load test OTP flow
- [ ] Test refresh token replay attack
- [ ] Verify session revocation
- [ ] Verify Redis failure handling
- [ ] Verify expired OTP rejection
- [ ] Verify concurrent refresh requests
- [ ] Verify CORS with production origins

**Flutter:**
- [ ] Token expiry flow
- [ ] Logout/login cycle
- [ ] Offline handling
- [ ] Retry logic
- [ ] WebSocket reconnect
- [ ] Push notification authentication

**Security:**
- [ ] Dependency vulnerability scan
- [ ] Secret scan
- [ ] Static analysis
- [ ] Migration verification
- [ ] Database backup restore test

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

## Feature Freeze Rules
Once a module reaches Feature Freeze, only **Bug**, **Security**, and **Performance** fixes allowed:
- ✅ **Booking Frozen** (Customer)
- ✅ **Reviews Frozen** (Customer)

## Build Checklist (Every Sprint/Merge)
```
go build ./...
go vet ./...
go test ./...
flutter analyze
flutter test
graphify update .
```

## Constraints
- **Booking system frozen** (customer) — no new customer features
- **Reviews frozen** — no new customer review features
- All new features must pass `flutter analyze` (0 new errors), `go build`, `go vet`
