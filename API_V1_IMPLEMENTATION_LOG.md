# BlogBowl API v1 Implementation Log

**Date:** January 8, 2026
**Branch:** `feat/api-v1`
**Status:** In Progress (Pages, Categories, Posts, Cover Image, Newsletters, Subscribers, Emails completed - Revisions pending)

---

## 1. Completed: Pages API

### 1.1 Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `submodules/core/app/controllers/api/v1/concerns/api_response.rb` | Created | Shared concern for API responses |
| `submodules/core/app/controllers/api/v1/base_controller.rb` | Modified | Added APIResponse concern |
| `submodules/core/app/controllers/api/v1/pages_controller.rb` | Modified | Updated to use new response patterns |
| `test/controllers/api/v1/pages_controller_test.rb` | Modified | Complete test coverage (13 tests) |
| `test/fixtures/pages.yml` | Modified | Added test fixtures |

### 1.2 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/pages` | List pages (paginated) |
| GET | `/api/v1/pages/:id` | Get single page |
| POST | `/api/v1/pages` | Create page |
| PATCH | `/api/v1/pages/:id` | Update page |

### 1.3 Response Format

**Collection Response (paginated envelope):**
```json
{
  "page": 1,
  "size": 10,
  "total": 25,
  "result": [
    {
      "id": 1,
      "name": "My Blog",
      "slug": "my-blog",
      "name_slug": "my-blog",
      "domain": "blog.example.com",
      "workspace_id": 1,
      "created_at": "2026-01-04T...",
      "updated_at": "2026-01-04T..."
    }
  ]
}
```

**Single Resource Response (unwrapped):**
```json
{
  "id": 1,
  "name": "My Blog",
  "slug": "my-blog",
  "name_slug": "my-blog",
  "domain": "blog.example.com",
  "workspace_id": 1,
  "created_at": "2026-01-04T...",
  "updated_at": "2026-01-04T..."
}
```

**Error Response:**
```json
{
  "errors": [
    { "field": "name", "message": "can't be blank" }
  ]
}
```

---

## 2. Completed: Categories API

### 2.1 Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `submodules/core/config/routes.rb` | Modified | Added nested categories routes under pages |
| `submodules/core/app/models/concerns/models/category_concern.rb` | Modified | Removed dead `page_topics` association |
| `test/controllers/api/v1/categories_controller_test.rb` | Created | Complete test coverage (16 tests) |
| `test/fixtures/categories.yml` | Modified | Added fixtures for default_user_workspace |

### 2.2 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/pages/:page_id/categories` | List categories (paginated) |
| GET | `/api/v1/pages/:page_id/categories/:id` | Get single category |
| POST | `/api/v1/pages/:page_id/categories` | Create category |
| PATCH | `/api/v1/pages/:page_id/categories/:id` | Update category |
| DELETE | `/api/v1/pages/:page_id/categories/:id` | Delete category |

### 2.3 Request/Response Format

**Create/Update params:**
```json
{
  "category": {
    "name": "Tech",
    "slug": "tech",
    "description": "Technology articles",
    "color": "#FF5733",
    "parent_id": null
  }
}
```

**Response fields:**
```json
{
  "id": 1,
  "name": "Tech",
  "slug": "tech",
  "description": "Technology articles",
  "color": "#FF5733",
  "parent_id": null,
  "page_id": 1,
  "created_at": "2026-01-04T...",
  "updated_at": "2026-01-04T..."
}
```

### 2.4 Bug Fix

**Problem:** Category model had `has_many :page_topics` association referencing non-existent model and table.

**Solution:** Removed dead association line from `category_concern.rb`.

---

## 3. Completed: Posts API

### 3.1 Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `submodules/core/config/routes.rb` | Modified | Added posts routes with publish and cover_image |
| `submodules/core/app/controllers/api/v1/posts_controller.rb` | Modified | Updated to snake_case JSON |
| `submodules/core/app/controllers/api/v1/images_controller.rb` | Modified | Changed to handle cover_image (singular) |
| `submodules/core/app/models/concerns/models/post_concern.rb` | Modified | Added 'scheduled' status, removed dead page_topic |
| `submodules/core/app/jobs/publish_post_job.rb` | Created | Job for scheduled post publishing |
| `test/controllers/api/v1/posts_controller_test.rb` | Created | Complete test coverage (22 tests) |
| `test/fixtures/posts.yml` | Modified | Added fixtures for default_user_workspace |
| `test/fixtures/authors.yml` | Modified | Added default_user_author fixture |
| `test/fixtures/post_authors.yml` | Modified | Added post-author association |

### 3.2 Posts API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/pages/:page_id/posts` | List posts (paginated, filterable) |
| GET | `/api/v1/pages/:page_id/posts/:id` | Get single post |
| POST | `/api/v1/pages/:page_id/posts` | Create post |
| PATCH | `/api/v1/pages/:page_id/posts/:id` | Update post |
| DELETE | `/api/v1/pages/:page_id/posts/:id` | Delete post |
| POST | `/api/v1/pages/:page_id/posts/:id/publish` | Publish or schedule post |

**Filters for index:**
- `status` - Filter by status (draft, published, scheduled)
- `category_id` - Filter by category

**Publish endpoint:**
- Without `scheduled_at`: Publishes immediately
- With `scheduled_at` (ISO 8601 future date): Schedules for later

### 3.3 Cover Image API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/pages/:page_id/posts/:post_id/cover_image` | Get cover image |
| POST | `/api/v1/pages/:page_id/posts/:post_id/cover_image` | Set cover image |
| PUT | `/api/v1/pages/:page_id/posts/:post_id/cover_image` | Replace cover image |
| DELETE | `/api/v1/pages/:page_id/posts/:post_id/cover_image` | Remove cover image |

### 3.4 Bug Fixes

1. **Dead `page_topic` association** - Removed from Post model (referenced non-existent model)
2. **Missing `scheduled` status** - Added to Post enum (draft: 0, published: 1, scheduled: 2)
3. **Missing `PublishPostJob`** - Created job for scheduled publishing

### 3.5 Known Issues

- **TODO:** Check why cover image doesn't show on frontend

---

## 4. Completed: Newsletters API

### 4.1 Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `submodules/core/config/routes.rb` | Modified | Added newsletters routes at workspace level |
| `test/controllers/api/v1/newsletters_controller_test.rb` | Created | Complete test coverage (13 tests) |
| `test/fixtures/newsletters.yml` | Modified | Added fixtures for default_user_workspace |

### 4.2 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/newsletters` | List newsletters (paginated) |
| GET | `/api/v1/newsletters/:id` | Get single newsletter |
| POST | `/api/v1/newsletters` | Create newsletter |
| PATCH | `/api/v1/newsletters/:id` | Update newsletter |

### 4.3 Request/Response Format

**Create/Update params:**
```json
{
  "newsletter": {
    "name": "Weekly Digest",
    "description": "Weekly newsletter for subscribers"
  }
}
```

**Response fields:**
```json
{
  "id": 1,
  "name": "Weekly Digest",
  "description": "Weekly newsletter for subscribers",
  "slug": "weekly-digest",
  "workspace_id": 1,
  "created_at": "2026-01-08T...",
  "updated_at": "2026-01-08T..."
}
```

---

## 5. Completed: Subscribers API

### 5.1 Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `submodules/core/config/routes.rb` | Modified | Added subscribers routes nested under newsletters |
| `submodules/core/app/controllers/api/v1/subscribers_controller.rb` | Modified | Added update endpoint for status management |
| `test/controllers/api/v1/subscribers_controller_test.rb` | Created | Complete test coverage (12 tests) |
| `test/fixtures/subscribers.yml` | Modified | Added fixtures for default_user_workspace |

### 5.2 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/newsletters/:newsletter_id/subscribers` | List subscribers (paginated, filterable) |
| POST | `/api/v1/newsletters/:newsletter_id/subscribers` | Create subscriber (upsert by email) |
| PATCH | `/api/v1/newsletters/:newsletter_id/subscribers/:id` | Update subscriber status |
| DELETE | `/api/v1/newsletters/:newsletter_id/subscribers/:id` | Remove subscriber |

**Filters for index:**
- `status` - Filter by status (pending, active)
- `verified` - Filter by verification status (true/false)

### 5.3 Request/Response Format

**Create params:**
```json
{
  "subscriber": {
    "email": "user@example.com",
    "note": "Optional note"
  }
}
```

**Update params (status management):**
```json
{
  "subscriber": {
    "active": true,
    "verified": true,
    "status": "active"
  }
}
```

**Response fields:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "verified": true,
  "active": true,
  "status": "active",
  "newsletter_id": 1,
  "verified_at": "2026-01-08T...",
  "created_at": "2026-01-08T...",
  "updated_at": "2026-01-08T..."
}
```

### 5.4 Notes

- **Upsert behavior:** If subscriber with same email exists, returns existing subscriber instead of creating duplicate
- **Update endpoint:** Added to allow activating/verifying subscribers for testing purposes

---

## 6. Completed: Emails API

### 6.1 Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `submodules/core/config/routes.rb` | Modified | Added emails routes nested under newsletters |
| `submodules/core/app/controllers/api/v1/emails_controller.rb` | Created | Full CRUD + send/schedule functionality |
| `test/controllers/api/v1/emails_controller_test.rb` | Created | Complete test coverage (15 tests) |
| `test/fixtures/newsletter_emails.yml` | Modified | Added fixtures for default_user_workspace |

### 6.2 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/newsletters/:newsletter_id/emails` | List emails (paginated, filterable) |
| GET | `/api/v1/newsletters/:newsletter_id/emails/:id` | Get single email |
| POST | `/api/v1/newsletters/:newsletter_id/emails` | Create email |
| PATCH | `/api/v1/newsletters/:newsletter_id/emails/:id` | Update email (draft only) |
| DELETE | `/api/v1/newsletters/:newsletter_id/emails/:id` | Delete email (draft only) |
| POST | `/api/v1/newsletters/:newsletter_id/emails/:id/send` | Send or schedule email |

**Filters for index:**
- `status` - Filter by status (draft, scheduled, sent, failed)

### 6.3 Request/Response Format

**Create/Update params:**
```json
{
  "email": {
    "subject": "Newsletter Subject",
    "preview": "Preview text shown in inbox",
    "content_html": "<p>Email content</p>",
    "content_json": {},
    "author_id": 1
  }
}
```

**Send endpoint params:**
```json
{
  "scheduled_at": "2026-01-15T10:00:00Z"
}
```
- Without `scheduled_at`: Sends immediately
- With `scheduled_at` (ISO 8601 future date): Schedules for later

**Response fields:**
```json
{
  "id": 1,
  "subject": "Newsletter Subject",
  "preview": "Preview text",
  "slug": "newsletter-subject",
  "status": "draft",
  "content_html": "<p>Email content</p>",
  "content_json": {},
  "author_id": 1,
  "newsletter_id": 1,
  "scheduled_at": null,
  "sent_at": null,
  "created_at": "2026-01-08T...",
  "updated_at": "2026-01-08T..."
}
```

### 6.4 Business Rules

- **Cannot update sent emails** - Returns 422 error
- **Cannot delete sent emails** - Returns 422 error
- **Cannot send without content** - Requires non-empty content_html
- **Cannot send without subject** - Requires non-empty subject
- **Cannot send without subscribers** - Requires at least one active and verified subscriber
- **Cannot schedule in the past** - scheduled_at must be future date

### 6.5 Known Issues

- **SSL Certificate Error:** Local development environment may have SSL certificate issues when connecting to Postmark API. This is a local Ruby/OpenSSL configuration issue, not a code problem.

---

## 7. Technical Decisions

### 7.1 JSON Key Format: `snake_case`

**Decision:** Use `snake_case` for all JSON keys.

**Reasoning:**
- Consistent with Rails conventions
- Consistent with existing internal API
- Avoids complexity of key transformation

**Alternative Considered:** `camelCase` (common for JS frontends) - rejected for consistency.

### 7.2 Pagination: Pagy gem

**Decision:** Use Pagy gem for pagination (already in project).

**Implementation:**
```ruby
pagy, records = pagy(scope, limit: limit, page: params[:page])
```

**Parameters:**
- `page` - Page number (default: 1)
- `size` - Items per page (default: 10, max: 100)

### 7.3 Response Envelope Strategy

**Decision:** Envelope for collections only, single resources unwrapped.

**Reasoning:**
- Collections need pagination metadata
- Single resources don't need wrapper
- Cleaner API for consumers

---

## 8. Implementation Challenges & Solutions

### 8.1 Concern Autoloading Issue

**Problem:** `API::V1::APIResponse` concern not being autoloaded by Zeitwerk.

**Root Cause:**
- Rails concerns expect specific file paths: `app/controllers/concerns/api/v1/api_response.rb`
- But we wanted: `app/controllers/api/v1/concerns/api_response.rb`
- Custom paths don't auto-map to namespaced constants

**Attempted Solutions:**
1. ❌ Placing file in `concerns/api/v1/` - worked but didn't match desired structure
2. ❌ Adding custom path to `config.autoload_paths` - Zeitwerk expects top-level constants
3. ✅ Using `require_relative` in base_controller.rb

**Final Solution:**
```ruby
# base_controller.rb
require_relative 'concerns/api_response'

module API
  module V1
    class BaseController < ActionController::API
      include API::V1::APIResponse
      # ...
    end
  end
end
```

### 8.2 Module Naming with API Acronym

**Problem:** Zeitwerk inflection for "API" caused constant name mismatch.

**Root Cause:**
- File: `api_response.rb`
- Expected constant by Zeitwerk: `APIResponse` (not `ApiResponse`)
- Rails has inflection: `inflect.acronym "API"`

**Solution:** Name the module `API::V1::APIResponse` (uppercase API and Response).

### 8.3 File Permissions

**Problem:** Concern file had restrictive permissions (600).

**Solution:** `chmod 644` to make file readable.

### 8.4 Test Fixtures - Page Domain Validation

**Problem:** Tests failed with "Domain is invalid" when creating pages.

**Root Cause:** Pages require `PAGES_BASE_DOMAIN` env var for domain generation.

**Solution:**
1. Use fixtures with pre-set domains instead of creating pages in setup
2. Set `ENV['PAGES_BASE_DOMAIN']` in test setup for create tests

### 8.5 Test URL Generation - `to_param` Returns Slug

**Problem:** `api_v1_page_url(@page1)` generated URL with slug instead of ID.

**Root Cause:** Page model has `to_param` returning slug for SEO-friendly URLs.

**Solution:** Use explicit ID in test URLs:
```ruby
# Before (broken):
get api_v1_page_url(@page1)  # => /api/v1/pages/my-slug

# After (working):
get api_v1_page_url(id: @page1.id)  # => /api/v1/pages/123
```

### 8.6 Test Database Setup

**Problem:** Test database on port 5434 not running.

**Solution:** Use separate Docker Compose file for test environment:
```bash
docker compose -f docker-compose.test.yaml up -d
```

### 8.7 Migration Conflicts

**Problem:** Duplicate migrations for `api_tokens` table.

**Root Cause:** Migrations copied from engine to main app but also run from engine.

**Solution:** Use `db:schema:load` instead of `db:migrate` for test database, then manually mark migrations as run.

---

## 9. File Structure

```
submodules/core/
├── app/
│   └── controllers/
│       └── api/
│           └── v1/
│               ├── base_controller.rb
│               ├── pages_controller.rb (✅ tested)
│               ├── categories_controller.rb (✅ tested)
│               ├── posts_controller.rb (✅ tested)
│               ├── images_controller.rb (✅ cover_image)
│               ├── revisions_controller.rb (⏳ pending)
│               ├── newsletters_controller.rb (✅ tested)
│               ├── subscribers_controller.rb (✅ tested)
│               ├── emails_controller.rb (✅ tested)
│               └── concerns/
│                   └── api_response.rb
└── lib/
    └── core/
        └── engine.rb

test/
├── controllers/
│   └── api/
│       └── v1/
│           ├── base_controller_test.rb (existing)
│           ├── pages_controller_test.rb (13 tests)
│           ├── categories_controller_test.rb (16 tests)
│           ├── posts_controller_test.rb (22 tests)
│           ├── newsletters_controller_test.rb (13 tests)
│           ├── subscribers_controller_test.rb (12 tests)
│           └── emails_controller_test.rb (15 tests)
└── fixtures/
    ├── pages.yml (updated)
    ├── categories.yml (updated)
    ├── posts.yml (updated)
    ├── authors.yml (updated)
    ├── post_authors.yml (updated)
    ├── newsletters.yml (updated)
    ├── subscribers.yml (updated)
    └── newsletter_emails.yml (updated)
```

---

## 10. APIResponse Concern Details

**Location:** `submodules/core/app/controllers/api/v1/concerns/api_response.rb`

**Methods:**

| Method | Purpose | Usage |
|--------|---------|-------|
| `render_collection(scope, &block)` | Paginated list with envelope | `render_collection(pages) { \|p\| page_json(p) }` |
| `render_resource(resource, status:, &block)` | Single resource | `render_resource(@page) { \|p\| page_json(p) }` |
| `render_error(errors, status:)` | Validation errors array | `render_error(@page.errors)` |
| `render_error_message(message, status:)` | Simple error string | `render_error_message("Not found", status: :not_found)` |

**Constants:**
- `DEFAULT_LIMIT = 10`
- `MAX_LIMIT = 100`

---

## 11. Controllers Status

| Controller | Status | Tests | Notes |
|------------|--------|-------|-------|
| PagesController | ✅ Complete | 13 tests | Workspace-level CRUD |
| CategoriesController | ✅ Complete | 16 tests | Nested under pages |
| PostsController | ✅ Complete | 22 tests | CRUD + publish + schedule |
| ImagesController | ✅ Complete | - | Cover image (GET, POST, PUT, DELETE) |
| NewslettersController | ✅ Complete | 13 tests | Workspace-level CRUD |
| SubscribersController | ✅ Complete | 12 tests | CRUD + upsert, nested under newsletters |
| EmailsController | ✅ Complete | 15 tests | CRUD + send/schedule, nested under newsletters |
| RevisionsController | ⏳ Pending | - | List, create, show_last, update_last, apply_last, share_last |

**Note:** All controllers use `snake_case` JSON keys. Total: 91 tests across 6 controllers.

---

## 12. Next Steps

1. **Revisions API** - Implement tests for post revisions controller
2. **Fix SSL issue** - Local development SSL certificate error with Postmark
3. **Fix cover image display** - TODO: Check why cover image doesn't show on frontend
4. **API Documentation** - Generate/update Apipie documentation

---

## 13. Commands Reference

```bash
# Start test database
docker compose -f docker-compose.test.yaml up -d

# Prepare test database
RAILS_ENV=test bin/rails db:drop db:create db:schema:load

# Run specific tests
RAILS_ENV=test bin/rails test test/controllers/api/v1/pages_controller_test.rb

# Start dev server
bin/dev
```

---

**Document Status:** Living document - updated as implementation progresses
