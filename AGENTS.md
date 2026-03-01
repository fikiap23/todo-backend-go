# AGENTS.md – Go Todo Backend

Briefing for AI coding agents working on this codebase.

## Quick Reference

| Action          | Command                                       |
| --------------- | --------------------------------------------- |
| Run locally     | `make run`                                    |
| Run with Docker | `make up`                                     |
| Run tests       | `make test`                                   |
| Lint            | `make lint`                                   |
| Format & tidy   | `make tidy`                                   |
| Migrations up   | `make migrations-up`                          |
| Migrations down | `make migrations-down TARGET=0`               |
| New migration   | `make migrations-new NAME=create_users_table` |

## Architecture

Clean architecture: **Handlers → Services → Repositories → Models**.

- `cmd/` – Entry point
- `internal/handler/` – HTTP handlers (parse, validate, respond)
- `internal/service/` – Business logic
- `internal/repository/` – Data access (pgx)
- `internal/model/` – Domain models
- `internal/middleware/` – Auth, logging, rate limit, CORS
- `internal/config/` – Koanf config with `BACKEND_` env prefix
- `internal/database/` – DB pool, migrations (Tern)
- `internal/lib/` – Shared libs (email, job/Asynq)

Stack: Echo v4, PostgreSQL (pgx), Redis, Asynq, Zerolog, New Relic.

## Configuration

- Env vars use `BACKEND_` prefix; dots map to nested config (e.g. `BACKEND_DATABASE.HOST`).
- Copy `.env.example` to `.env` before running.
- For Docker: use hostnames `postgres` and `redis` (service names).
- Docker Compose uses vars without dots: `APP_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_PORT` (see `.env.example`).

## Code Conventions

- Use constructor-based DI; pass dependencies explicitly.
- Handlers: parse/validate → call service → return response.
- Services: orchestrate logic; use repositories for data.
- Repositories: parameterized queries only; no raw SQL concatenation.
- Logging: Zerolog with structured fields (`log.Info().Str("key", val).Msg("...")`).
- Errors: use `internal/errs` types; return appropriate HTTP status via handlers.

## Migrations

- Tern migrations in `internal/database/migrations/`.
- Migrations need `BACKEND_DB_DSN` or `BACKEND_DATABASE.*` in `.env`.
- Migrations run automatically only when `BACKEND_PRIMARY.ENV` ≠ `local`.

## Gotchas

- **Docker Compose**: Variable names with dots (e.g. `BACKEND_SERVER.PORT`) break interpolation. Use `APP_PORT`, `DB_*` etc. in compose.
- **Config**: Koanf expects `BACKEND_` prefix; keys like `BACKEND_DATABASE.HOST` map to `database.host`.
- **Tests**: Use `internal/testing/` helpers; tests may use Testcontainers for Postgres/Redis.
