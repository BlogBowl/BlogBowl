# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BlogBowl is a multi-tenant blogging platform (blogs, changelogs, help centers) built with Rails 8 and React. It uses a submodule architecture where core business logic lives in `submodules/core` (Rails engine) and the rich text editor in `submodules/editor` (React + Vite).

## Commands

### Development
```bash
bin/setup              # Full setup: install gems, bun packages, prepare DB, start server
bin/dev                # Start all services (Rails, Sidekiq, JS/CSS watchers, Docker infra)
```

### Testing
```bash
bin/rails test                    # Run all tests (includes engine tests)
bin/rails test test/models/       # Run specific directory
bin/rails test test/models/user_test.rb    # Run single file
bin/rails test test/models/user_test.rb:10 # Run specific test by line
rake test:core_engine             # Run core engine tests only
```

### Code Quality
```bash
bin/rubocop            # Lint Ruby (Rails Omakase style)
bin/brakeman           # Security scan
bun run lint           # Lint JavaScript/TypeScript
```

### Assets
```bash
bun build              # Build all JavaScript
bun build:css          # Build all CSS (Tailwind)
bun build:css:watch    # Watch mode for CSS
```

### Database
```bash
bin/rails db:prepare   # Create, migrate, seed (dev environment only)
RAILS_ENV=development bin/rails db:migrate
RAILS_ENV=development bin/rails db:seed
```

## Architecture

### Submodule Structure
- **`submodules/core`**: Rails engine containing all models, controllers, views, jobs, mailers, and abilities. Mounted as a gem via Gemfile.
- **`submodules/editor`**: React/TypeScript rich text editor built with TipTap Pro and Vite.

### Core Engine Structure (`submodules/core`)
```
submodules/core/
├── app/
│   ├── abilities/           # CanCanCan authorization
│   ├── constraints/         # Route constraints (PublicRouteConstraint)
│   ├── controllers/
│   │   ├── api/v1/          # Public REST API (token-authenticated)
│   │   │   ├── concerns/    # Shared API concerns (APIResponse)
│   │   │   ├── base_controller.rb
│   │   │   ├── pages_controller.rb
│   │   │   ├── posts_controller.rb
│   │   │   ├── categories_controller.rb
│   │   │   └── ...
│   │   ├── admin/           # Admin panel controllers
│   │   └── public/          # Public blog controllers
│   ├── jobs/                # Sidekiq background jobs
│   ├── mailers/             # Email templates
│   ├── models/              # All ActiveRecord models
│   └── views/               # ERB templates
├── config/
│   └── routes.rb            # Engine routes (merged with main app)
├── lib/
│   └── core/
│       └── engine.rb        # Engine configuration
└── spec/ or test/           # Engine-specific tests
```

### API v1 Architecture
The public API uses Bearer token authentication via `APIToken` model:
- **Base controller**: `API::V1::BaseController` authenticates requests and sets `@current_workspace`
- **Concerns**: Located in `api/v1/concerns/` and loaded via `require_relative` (Zeitwerk doesn't autoload custom paths)
- **Response format**: Collections use pagination envelope `{page, size, total, result}`, single resources are unwrapped
- **JSON keys**: `snake_case` for consistency with Rails conventions
- **Documentation**: Apipie DSL in controllers generates API docs

### Multi-Tenant Routing
Routes are constrained by hostname:
- **Admin routes** (`blogbowl.test` in dev): Sign in, workspace management, post editing
- **Public routes** (custom domains): Blog pages served based on `Page.domain` lookup

The `PublicRouteConstraint` in `submodules/core/app/constraints/` handles this routing logic.

### Key Models (in core engine)
- `Workspace` → `Members` → `Users` (multi-tenant container)
- `Page` → `Posts` → `PostRevisions` (blog content with versioning)
- `Newsletter` → `NewsletterEmails` → `Subscribers` (email campaigns)
- `Author` (belongs to Member, writes posts)

### Authorization
CanCanCan abilities in `submodules/core/app/abilities/`:
- `workspace_ability.rb` - Workspace-level access
- `member_ability.rb` - Member permissions within workspace
- `post_ability.rb` - Post owner/collaborator/viewer roles

### Background Jobs
Sidekiq jobs in `submodules/core/app/jobs/`:
- `PublishPostJob` - Scheduled post publishing
- `SendNewsletterJob` - Newsletter dispatch
- `ProcessPostmarkEventJob` - Email webhook handling

### Asset Pipeline
- **Bundler**: Bun (configured in `bun.config.js`)
- **CSS**: Three separate Tailwind builds (public, application, editor)
- **Output**: `app/assets/builds/` consumed by Propshaft

## Development Environment

### Required Services (via docker-compose.dev.yaml)
- PostgreSQL 16 on port 5435
- Redis on port 6380

### Host Configuration
Add to `/etc/hosts`:
```
127.0.0.1 blogbowl.test
```

### Default Credentials
- Email: `admin@example.com`
- Password: `changeme`

### Environment Variables
Copy `.env.example` to `.env`. Key variables:
- `DATABASE_URL` - PostgreSQL connection (use `postgresql://development:development@localhost:5435/blogbowl` for local dev)
- `BASE_DOMAIN` - Base domain for blog routing
- `POSTMARK_ACCOUNT_TOKEN` - Email delivery (optional)

## Testing Notes

- Tests use Minitest with WebMock for HTTP stubbing
- Test database runs on port 5434 (separate from dev)
- Fixtures in `test/fixtures/`
- Engine tests are automatically included via `lib/tasks/engine_tests.rake`
- CI runs PostgreSQL 14 + Redis 6 via GitHub Actions
