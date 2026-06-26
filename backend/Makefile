.PHONY: build run test seed lint docker-build docker-up docker-down dev clean

# Build
build:
	go build -o /tmp/barbar-server ./cmd/server

build-prod:
	CGO_ENABLED=0 go build -ldflags="-w -s" -o barbar-server ./cmd/server

# Run
run:
	DB_USER=saurabhjain DB_PASSWORD="" JWT_SECRET="test-secret-for-dev-32-chars-long!!" DB_NAME=barbar_app REDIS_HOST=localhost REDIS_PORT=6379 go run ./cmd/server/

# Test
test:
	DB_USER=saurabhjain DB_PASSWORD="" JWT_SECRET="test-secret-for-dev-32-chars-long!!" DB_NAME=barbar_app_test REDIS_HOST=localhost REDIS_PORT=6379 go test -v -count=1 -timeout 60s ./tests/

test-verbose:
	DB_USER=saurabhjain DB_PASSWORD="" JWT_SECRET="test-secret-for-dev-32-chars-long!!" DB_NAME=barbar_app_test REDIS_HOST=localhost REDIS_PORT=6379 go test -v -count=1 -timeout 120s ./tests/

# Seed data
seed:
	DB_USER=saurabhjain DB_PASSWORD="" JWT_SECRET="test-secret-for-dev-32-chars-long!!" DB_NAME=barbar_app REDIS_HOST=localhost REDIS_PORT=6379 go run ./cmd/seed/

# Lint
lint:
	golangci-lint run

lint-fix:
	golangci-lint run --fix

# Docker
docker-build:
	docker build -t barbar-app .

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f api

docker-restart:
	docker-compose restart api

docker-clean:
	docker-compose down -v

# Production Docker
docker-prod-up:
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

docker-prod-down:
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml down

# Dev
dev:
	air

clean:
	rm -f barbar-server
	go clean -cache

# Database
db-psql:
	psql -h localhost -U saurabhjain -d barbar_app

db-reset:
	psql -h localhost -U saurabhjain -c "DROP DATABASE IF EXISTS barbar_app; CREATE DATABASE barbar_app;"
	DB_USER=saurabhjain DB_PASSWORD="" JWT_SECRET="test-secret-for-dev-32-chars-long!!" DB_NAME=barbar_app REDIS_HOST=localhost REDIS_PORT=6379 go run ./cmd/seed/

# Help
help:
	@echo "Available targets:"
	@echo "  build          - Build the Go binary"
	@echo "  run            - Run the server locally"
	@echo "  test           - Run integration tests"
	@echo "  seed           - Seed demo data"
	@echo "  lint           - Run golangci-lint"
	@echo "  docker-up      - Start all services with Docker"
	@echo "  docker-down    - Stop all Docker services"
	@echo "  db-reset       - Reset and re-seed database"
