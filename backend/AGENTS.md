# Build
go build ./...

# Run server (dev)
DB_USER=postgres DB_PASSWORD=postgres DB_PORT=5433 JWT_SECRET="test-secret-for-dev-32-chars-long!!" DB_NAME=barbar_app REDIS_HOST=localhost REDIS_PORT=6379 go run ./cmd/server/

# Run integration tests (requires barbar_app_test db)
DB_USER=postgres DB_PASSWORD=postgres DB_PORT=5433 JWT_SECRET="test-secret-for-dev-32-chars-long!!" DB_NAME=barbar_app_test REDIS_HOST=localhost REDIS_PORT=6379 go test -v -count=1 -timeout 60s ./tests/

# Run seed script (requires barbar_app db, --reset to clear & re-seed)
DB_USER=postgres DB_PASSWORD=postgres DB_PORT=5433 JWT_SECRET="test-secret-for-dev-32-chars-long!!" DB_NAME=barbar_app REDIS_HOST=localhost REDIS_PORT=6379 go run ./cmd/seed/

# Run seed with reset
$env:DB_USER="postgres"; $env:DB_PASSWORD="postgres"; $env:DB_PORT="5433"; $env:JWT_SECRET="test-secret-for-dev-32-chars-long!!"; $env:DB_NAME="barbar_app"; $env:REDIS_HOST="localhost"; $env:REDIS_PORT="6379"; go run ./cmd/seed/ --reset

# Lint
golangci-lint run

# Build binary
go build -o /tmp/barbar-server ./cmd/server/
