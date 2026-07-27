# Release Checklist — Barbar App

## Pre-Release Gates

### Build Verification

- [ ] `go build ./...` passes
- [ ] `go vet ./...` passes
- [ ] `go test ./... -count=1 -timeout 60s` passes
- [ ] `flutter analyze` passes (0 new issues)
- [ ] Android build succeeds
- [ ] iOS build succeeds (if applicable)
- [ ] Docker image builds successfully

### QA Verification

- [ ] Regression checklist (regression-checklist.md) — 100% pass
- [ ] End-to-end test (end-to-end-test.md) — all steps verified
- [ ] New features QA checklist (qa-checklist.md) — all new items pass
- [ ] All known bugs resolved or documented as known issues

### Security Checks

- [ ] OTP flows tested (attempt limit, expiry, HMAC)
- [ ] Token security tested (rotation, reuse, expiry)
- [ ] Authorization verified (all admin endpoints require admin role)
- [ ] Input validation verified (UUID parsing, JSON binding)
- [ ] CORS configuration correct for production origins
- [ ] Dependency vulnerability scan completed
- [ ] Secret scan completed (no credentials in code)

### Performance Checks

- [ ] Pagination tested with 200+ records
- [ ] Image loading tested (no memory spikes)
- [ ] Reports dashboard loads within acceptable time
- [ ] App restart preserves session
- [ ] Background → foreground resume works

### Database

- [ ] Database backup completed
- [ ] Migrations reviewed and tested
- [ ] Rollback plan documented
- [ ] Seed script verified (fresh DB → seeded correctly)

### Documentation

- [ ] CHANGELOG.md updated
- [ ] API docs updated (if applicable)
- [ ] Release notes prepared

## Post-Release

- [ ] Production deployment monitored for 1 hour
- [ ] Error tracking checked (no unexpected errors)
- [ ] Performance metrics reviewed
- [ ] Users notified (if applicable)
