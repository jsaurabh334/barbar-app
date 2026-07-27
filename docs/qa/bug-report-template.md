# Bug Report Template

```md
---
ID: B{number}
Module: {Auth / Customer / Vendor / Delivery / Orders / Wallet / Admin / UI}
Severity: {Critical / High / Medium / Low}
Status: {Open / In Progress / Fixed / Verified / Won't Fix}
Reported: {YYYY-MM-DD}
---

## Description

{Clear, concise description of the bug}

## Steps to Reproduce

1. {Step 1}
2. {Step 2}
3. {Step 3}

## Expected Result

{What should happen}

## Actual Result

{What actually happens}

## Environment

- Backend commit: {git hash}
- Flutter commit: {git hash}
- Database: {postgres / mysql}
- Device/OS: {Android 14 / iOS 17 / etc.}

## Screenshots / Logs

{Attach screenshots, server logs, or API responses}

## Notes

{Additional context, workarounds, or related issues}
```

---

## Example

```md
---
ID: B16
Module: Settlements
Severity: High
Status: Fixed
Reported: 2026-07-23
---

## Description

Double settlement processing is possible — status check missing before processing.

## Steps to Reproduce

1. Admin processes a settlement (POST /admin/settlements/:id/process)
2. Admin processes the same settlement again

## Expected Result

Second attempt returns error: "Settlement already processed"

## Actual Result

Second attempt processes again, creating duplicate payout records.

## Fix

Added status guard: reject if already processed/rejected. Also fixed column name mismatch `utr_nnumber` → `utr_number`.
```
