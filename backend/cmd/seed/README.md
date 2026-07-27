# Seed Script — Barbar App

The seed command populates the database with demo data for development and QA.

## Usage

```bash
go run ./cmd/seed/ [flags]
```

## Flags

| Flag | Description |
|------|-------------|
| `--admin` | Seed admin account only |
| `--catalog` | Seed categories and products only |
| `--demo-vendor` | Seed demo vendors and barber shops only |
| `--demo-delivery` | Seed demo delivery partner only |
| `--lookup` | Seed lookup/master data (platform settings) |
| `--notifications` | Seed notification templates only |
| `--settings` | Seed platform settings (alias for `--lookup`) |
| `--reset` | Delete existing demo data before seeding |
| `--all` | Seed all data **(default)** |
| `--help` | Show available flags and usage |

## What Each Seeder Creates

| Seeder | Data |
|--------|------|
| `--admin` | 1 admin user (`admin@barbar.app / Admin@123`) |
| `--catalog` | 12 categories (6 product + 6 barber service) + 30 products |
| `--demo-vendor` | 5 e-commerce vendors + 15 barber shops with 90 services across 4 cities |
| `--demo-delivery` | 1 delivery partner (`delivery@demo.com / Demo@123`) |
| `--lookup` | 16 platform settings (commission, fees, support info, etc.) |
| `--notifications` | 4 notification templates (EN + HI for bookings and orders) |
| `--all` | Everything above + 1 demo customer + demo images |

## Examples

```bash
# Seed everything (default)
go run ./cmd/seed/

# Seed admin + platform settings (fast setup)
go run ./cmd/seed/ --admin --lookup

# Reset and re-seed catalog
go run ./cmd/seed/ --catalog --reset

# Seed only vendors for manual testing
go run ./cmd/seed/ --demo-vendor

# Show all available flags
go run ./cmd/seed/ --help
```

## Safe Usage Notes

- All seeders are **idempotent** — running them multiple times will not duplicate data.
- `--reset` **deletes** all non-admin data from the database. Use with caution in shared environments.
- Flags are **additive** — combine them freely (e.g., `--admin --lookup --notifications`).
- No flags specified = `--all` behavior.
- `--demo-vendor` also triggers demo image generation for barber shop galleries.
