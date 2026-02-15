# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BlogBowl is a multi-tenant blogging platform (blogs, changelogs, help centers) built with Rails 8 and React. It uses a submodule architecture where core business logic lives in `submodules/core` (Rails engine) and the rich text editor in `submodules/editor` (React + Vite).

## Commands

### Development
```bash
bin/setup              # Full setup: install gems, bun packages, prepare DB, start server
bin/dev                # Start all services (Rails, Sidekiq, JS/CSS watchers, Docker infra)

# Git submodules (required after fresh clone)
git clone --recurse-submodules https://github.com/BlogBowl/BlogBowl.git
git submodule update --init --recursive   # Initialize submodules
git submodule update --remote             # Update to latest
git submodule update --force              # Reset to tracked commit
```

### Testing
```bash
# Start test database (separate from dev)
docker compose -f docker-compose.test.yaml up -d

# Run tests
bin/rails test                    # Run all tests (includes engine tests)
bin/rails test test/models/       # Run specific directory
bin/rails test test/models/user_test.rb    # Run single file
bin/rails test test/models/user_test.rb:10 # Run specific test by line
rake test:core_engine             # Run core engine tests only

# Reset test database if needed
RAILS_ENV=test bin/rails db:drop db:create db:schema:load
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

### Submodule Workflow (core engine changes)
Short flow for updating the core engine and syncing the parent repo:
```bash
# 1) Work in the standalone core repo
cd ../blogbowl-core
git checkout <branch>
git status
# ...edit, commit...
git push fork <branch>

# 2) Update submodule pointer in parent repo
cd ../BlogBowl
# Fetch from local sibling clone or from a remote (either is fine)
git -C submodules/core fetch ../blogbowl-core   # local sibling clone linked to this submodule
git -C submodules/core fetch fork               # or: git -C submodules/core fetch upstream
git -C submodules/core checkout <core-commit-sha>
git add submodules/core
git commit -m "chore: bump blogbowl-core submodule"
git push fork <branch>
```
Notes:
- Parent repo stores only the submodule commit SHA; changing the submodule checkout and committing in the parent updates the pointer.
- Remotes are named `fork` (dlysenko) and `upstream` (BlogBowl org).

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
│   │   │   ├── revisions_controller.rb
│   │   │   ├── images_controller.rb
│   │   │   ├── newsletters_controller.rb
│   │   │   ├── subscribers_controller.rb
│   │   │   └── emails_controller.rb
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

### Public API (v1)
**Authentication**: Bearer token via `APIToken` model
**Location**: `submodules/core/app/controllers/api/v1/`

Key characteristics:
- **Base controller**: `API::V1::BaseController` authenticates requests and sets `@current_workspace`
- **Concerns**: Located in `api/v1/concerns/` and loaded via `require_relative` (Zeitwerk doesn't autoload custom paths)
- **Response format**: Collections use pagination envelope `{page, size, total, result}`, single resources are unwrapped
- **JSON keys**: `snake_case` for consistency with Rails conventions
- **Pagination**: Pagy gem with default 10 items/page, max 100
- **Documentation**: Apipie DSL in controllers generates API docs

**Available endpoints:**
| Resource | Endpoints | Description |
|----------|-----------|-------------|
| Pages | `GET /api/v1/pages`, `GET /api/v1/pages/:id`, `POST/PATCH` | Blog/changelog/help center pages |
| Categories | `GET/POST/PATCH/DELETE /api/v1/pages/:page_id/categories` | Page categories (nested) |
| Posts | `GET /api/v1/pages/:page_id/posts`, `GET /api/v1/posts/:id` | Posts with filtering (`status`, `category_id`), search, pagination |
| Posts | `POST/PATCH/DELETE /api/v1/posts/:id` | Create, update, delete posts |
| Posts | `POST /api/v1/posts/:id/publish` | Publish immediately or schedule with `scheduled_at` param |
| Posts | `GET/POST/PUT/DELETE /api/v1/posts/:post_id/cover_image` | Cover image management |
| Revisions | `GET /api/v1/posts/:post_id/revisions` | Post revision history |
| Newsletters | `GET/POST/PATCH /api/v1/newsletters` | Newsletter management (workspace-level) |
| Subscribers | `GET/POST/PATCH/DELETE /api/v1/newsletters/:newsletter_id/subscribers` | Subscriber management with filtering (`status`, `verified`) |
| Emails | `GET/POST/PATCH/DELETE /api/v1/newsletters/:newsletter_id/emails` | Newsletter emails |
| Emails | `POST /api/v1/newsletters/:newsletter_id/emails/:id/send` | Send immediately or schedule with `scheduled_at` param |

### Internal API
**Authentication**: Session-based (admin users)
**Location**: `submodules/core/app/controllers/api/internal/`
**Purpose**: Used by the React editor and admin dashboard

Key endpoints:
- `POST/PATCH /api/internal/pages/:page_id/posts` - Create/update posts from editor
- `POST /api/internal/pages/:page_id/posts/:id/publish` - Publish posts
- `GET/POST /api/internal/pages/:page_id/posts/:id/revisions` - Revision management
- `POST /api/internal/pages/:page_id/posts/:id/images` - Image uploads from editor
- `GET /api/internal/pages/:page_id/categories` - Category dropdown data

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

### React Editor Architecture
**Location**: `submodules/editor/`
**Build Tool**: Vite 5.2.0
**Framework**: React 18.3.1 + TypeScript

Structure:
```
submodules/editor/src/
├── components/
│   ├── tiptap/          # BlockEditor, PostEditor, EmailEditor
│   ├── ui/              # Radix UI components (shadcn/ui)
│   ├── sidebar/         # Editor sidebar panels
│   ├── modal/           # Modal dialogs
│   └── core/            # Shared components
├── extensions/          # Custom TipTap extensions
│   ├── SlashCommand/
│   ├── ImageUpload/
│   ├── TableOfContentsNode/
│   └── MultiColumn/
├── hooks/
│   └── api/             # React Query hooks for API calls
└── lib/
    ├── utils/           # Utility functions
    └── data/            # Static data
```

**Key dependencies:**
- TipTap 2.3.0 with Pro extensions (required for collaboration)
- Hocuspocus Provider for real-time collaboration (Y.js based)
- React Query (TanStack) for server state
- React Hook Form + Zod for forms/validation
- Radix UI for accessible components
- Lucide React for icons

**Integration**: Editor is embedded in Rails views, communicates with backend via internal API endpoints. Built bundle is placed in `app/assets/builds/` and served via Propshaft.

### Asset Pipeline
- **Bundler**: Bun (configured in `bun.config.js`)
- **CSS**: Three separate Tailwind builds:
  - `public.css` - Public-facing blog pages
  - `application.css` - Admin dashboard
  - `editor.css` - Rich text editor
- **Output**: `app/assets/builds/` consumed by Propshaft
- **Watch mode**: Run via Procfile.dev during development

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
- `PAGES_BASE_DOMAIN` - Base domain for blog routing (e.g., `blogbowl.test`)
- `POSTMARK_ACCOUNT_TOKEN` - Email delivery via Postmark (optional)
- `POSTMARK_X_API_KEY` - Webhook secret for Postmark events (optional)
- `S3_*` - AWS S3 credentials for image storage (optional, uses local disk by default)

## Testing Notes

- Tests use Minitest with WebMock for HTTP stubbing
- Test database runs on port 5434 (separate from dev)
- Fixtures in `test/fixtures/`
- Engine tests are automatically included via `lib/tasks/engine_tests.rake`
- CI runs PostgreSQL 14 + Redis 6 via GitHub Actions

## Important Technical Notes

### Zeitwerk Autoloading Gotchas
- **Concerns in custom paths**: API concerns at `api/v1/concerns/` must be loaded via `require_relative` in `base_controller.rb` - Zeitwerk only autoloads concerns from `app/controllers/concerns/`
- **API acronym**: Rails inflector has `inflect.acronym "API"`, so module names must be `API::V1::APIResponse` (not `ApiResponse`)

### Model Conventions
- **Post statuses**: Enum with `draft: 0, published: 1, scheduled: 2`
- **to_param override**: `Page` model returns slug instead of ID for SEO-friendly URLs. In tests, explicitly use `id:` parameter: `api_v1_page_url(id: @page.id)`
- **Post versioning**: All post edits create `PostRevision` records for history/draft management
- **Image processing**: All uploaded images auto-convert to WebP via `ConvertToWebp` concern (uses ruby-vips)

### Testing Fixtures
- Set `ENV['PAGES_BASE_DOMAIN']` in test setup when creating pages (required for domain validation)
- Use fixtures with pre-set domains rather than creating pages in test setup to avoid validation errors
