# MASTER SPRINT TEMPLATE

## Before Making Any Changes

1. Read all related files (backend + frontend).
2. Explain your understanding of the current flow.
3. Identify risks — especially cross-role impact.
4. Show implementation plan.
5. Wait for approval.

Only after approval start modifying code.

---

## Rules

- Read all files before editing.
- Never assume APIs — check backend first, then match frontend.
- Reuse existing architecture (BLoC, Repository, DataSource patterns).
- Do NOT break other modules (Barber, Vendor, Delivery, Admin).
- Do NOT redesign UI layout unless required for functionality.

## Architecture Safety Rule

If implementation requires:
- changing database schema
- changing API contracts
- changing authentication flow
- changing token format
- changing storage format
- changing routing architecture

STOP.
Explain:
- Why change is needed
- Which files are affected
- Possible risks

Wait for approval before proceeding.

## Testing Rules

- Never mark a feature as Tested unless it has actually been verified through the application's flow.
- If testing could not be performed, mark: `Tested = Not Verified`
- Do not assume success.

## Missing Backend Dependency

If any task cannot be completed because backend support is missing:
- DO NOT create a temporary implementation or mock fallback.
- Report "Missing Backend Dependency: <details>"
- Stop and wait for instructions.

---

## Sprint Goal

<Describe what this sprint achieves in one sentence.>

## Files in Scope

### Backend
<list backend files>

### Frontend
<list frontend files>

---

## Tasks

### Task 1: <Title>
- <description of what to do>
- <semantic location, NOT line numbers>

### Task 2: <Title>
- <description of what to do>

...

### Task N: <Title>
- <description of what to do>

---

## What NOT to Do

- <list out-of-scope items explicitly>
- <prevents AI scope creep>

---

## After Completion

Generate this report:

```
====================================
SPRINT <N> — FEATURE COMPLETION REPORT
====================================

| Feature | Backend | Frontend | Connected | Regression Risk | Tested | Status |
|---------|:-------:|:--------:|:---------:|:---------------:|:-----:|:------:|
| ...     |    ✔    |    ✔     |     ✔     |      Low        |   ✔   | 🟢     |
| ...     |    ✔    |    ❌    |     ❌    |      High       |   ❌  | 🔴     |

Completed Features:
Partially Completed Features:
Pending Features:
Backend APIs Missing:
Frontend Bugs Found:
Development Blockers:
Files Modified:

Regression Check:
☐ Barber login unaffected
☐ Vendor login unaffected
☐ Delivery login unaffected
☐ Admin login unaffected

Next Sprint Recommended:
```

Do NOT start the next sprint. Wait for approval.
