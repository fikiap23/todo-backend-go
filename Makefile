# =============================================================================
# Makefile - Go Boilerplate Backend
# =============================================================================

COMPOSE_DEV := -f docker-compose.yml
CONTAINER_DEV := todo-backend-go-dev

BINARY_NAME := server
BUILD_DIR := bin
MIGRATIONS_DIR := ./internal/database/migrations

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------
.PHONY: help
help:
	@echo "Go Boilerplate - Available targets:"
	@echo ""
	@echo "  make build          - Build the application binary"
	@echo "  make run            - Run the application (loads .env if present)"
	@echo "  make test           - Run tests"
	@echo "  make lint           - Run golangci-lint"
	@echo "  make tidy           - Format code and tidy dependencies"
	@echo "  make fmt            - Format Go code (go fmt)"
	@echo ""
	@echo "  make migrations-up  - Apply database migrations (requires BACKEND_DB_DSN or .env)"
	@echo "  make migrations-down [TARGET=0] - Rollback to version (default 0)"
	@echo "  make migrations-new NAME=xxx - Create a new migration file"
	@echo ""
	@echo "  make up             - Start services (docker), then follow logs"
	@echo "  make down           - Stop services"
	@echo "  make restart       - Restart app container, then follow logs"
	@echo "  make logs          - Follow app container logs"
	@echo "  make exec          - Shell into app container"
	@echo ""
	@echo "  make clean          - Remove build artifacts"

# -----------------------------------------------------------------------------
# Dev (local - Go)
# -----------------------------------------------------------------------------
.PHONY: build run test lint tidy fmt
build:
	@mkdir -p $(BUILD_DIR)
	go build -ldflags="-w -s" -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd
	@echo "Built $(BUILD_DIR)/$(BINARY_NAME)"

run:
	@if [ -f .env ]; then set -a && . ./.env && set +a; fi; go run ./cmd

test:
	go test ./...

lint:
	golangci-lint run ./...

tidy: fmt
	go mod tidy
	go mod verify
	@echo "Done: fmt, mod tidy, mod verify"

fmt:
	go fmt ./...

# -----------------------------------------------------------------------------
# Migrations
# -----------------------------------------------------------------------------
.PHONY: migrations-up migrations-down migrations-new
migrations-up:
	@if [ -f .env ]; then set -a && . ./.env && set +a; fi; \
	dsn="$${BACKEND_DB_DSN}"; \
	if [ -z "$$dsn" ]; then \
		dsn="postgres://$${BACKEND_DATABASE.USER}:$${BACKEND_DATABASE.PASSWORD}@$${BACKEND_DATABASE.HOST}:$${BACKEND_DATABASE.PORT}/$${BACKEND_DATABASE.NAME}?sslmode=$${BACKEND_DATABASE.SSL_MODE}"; \
	fi; \
	if [ -z "$$dsn" ] || [ "$$dsn" = "postgres://:@/?sslmode=" ]; then \
		echo "Error: Set BACKEND_DB_DSN or ensure .env has BACKEND_DATABASE.*"; exit 1; \
	fi; \
	echo "Running migrations..."; \
	tern migrate -m $(MIGRATIONS_DIR) --conn-string "$$dsn"

migrations-down:
	@if [ -f .env ]; then set -a && . ./.env && set +a; fi; \
	dsn="$${BACKEND_DB_DSN}"; \
	if [ -z "$$dsn" ]; then \
		dsn="postgres://$${BACKEND_DATABASE.USER}:$${BACKEND_DATABASE.PASSWORD}@$${BACKEND_DATABASE.HOST}:$${BACKEND_DATABASE.PORT}/$${BACKEND_DATABASE.NAME}?sslmode=$${BACKEND_DATABASE.SSL_MODE}"; \
	fi; \
	if [ -z "$$dsn" ] || [ "$$dsn" = "postgres://:@/?sslmode=" ]; then \
		echo "Error: Set BACKEND_DB_DSN or ensure .env has BACKEND_DATABASE.*"; exit 1; \
	fi; \
	target=$${TARGET:-0}; \
	echo "Rolling back to version $$target..."; \
	tern migrate -m $(MIGRATIONS_DIR) --conn-string "$$dsn" --target $$target

migrations-new:
	@if [ -z "$(NAME)" ]; then echo "Error: NAME is required. Usage: make migrations-new NAME=create_users_table"; exit 1; fi
	tern new -m $(MIGRATIONS_DIR) $(NAME)
	@echo "Created migration for $(NAME)"

# -----------------------------------------------------------------------------
# Dev (Docker)
# -----------------------------------------------------------------------------
.PHONY: up down restart logs exec
up:
	docker compose $(COMPOSE_DEV) up -d 
	docker logs -f $(CONTAINER_DEV)

down:
	docker compose $(COMPOSE_DEV) down

restart:
	docker restart $(CONTAINER_DEV)
	docker logs -f $(CONTAINER_DEV)

logs:
	docker logs -f $(CONTAINER_DEV)

exec:
	docker exec -it $(CONTAINER_DEV) sh

# -----------------------------------------------------------------------------
# Utils
# -----------------------------------------------------------------------------
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	@echo "Cleaned $(BUILD_DIR)"
