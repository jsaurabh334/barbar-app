# Build
go build ./...

# Run server (dev)
DB_USER=saurabhjain DB_PASSWORD="" JWT_SECRET="test-secret-for-dev-32-chars-long!!" DB_NAME=barbar_app REDIS_HOST=localhost REDIS_PORT=6379 go run ./cmd/server/

# Run integration tests (requires barbar_app_test db)
DB_USER=saurabhjain DB_PASSWORD="" JWT_SECRET="test-secret-for-dev-32-chars-long!!" DB_NAME=barbar_app_test REDIS_HOST=localhost REDIS_PORT=6379 go test -v -count=1 -timeout 60s ./tests/

# Run seed script (requires barbar_app db)
DB_USER=saurabhjain DB_PASSWORD="" JWT_SECRET="test-secret-for-dev-32-chars-long!!" DB_NAME=barbar_app REDIS_HOST=localhost REDIS_PORT=6379 go run ./cmd/seed/

# Lint
golangci-lint run

# Build binary
go build -o /tmp/barbar-server ./cmd/server/
