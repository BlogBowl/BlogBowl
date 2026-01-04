# BlogBowl API v1 Implementation Log

**Date:** January 4, 2026
**Branch:** `feat/api-v1`
**Status:** In Progress (Pages, Categories completed)

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

## 3. Technical Decisions

### 3.1 JSON Key Format: `snake_case`

**Decision:** Use `snake_case` for all JSON keys.

**Reasoning:**
- Consistent with Rails conventions
- Consistent with existing internal API
- Avoids complexity of key transformation

**Alternative Considered:** `camelCase` (common for JS frontends) - rejected for consistency.

### 3.2 Pagination: Pagy gem

**Decision:** Use Pagy gem for pagination (already in project).

**Implementation:**
```ruby
pagy, records = pagy(scope, limit: limit, page: params[:page])
```

**Parameters:**
- `page` - Page number (default: 1)
- `size` - Items per page (default: 10, max: 100)

### 3.3 Response Envelope Strategy

**Decision:** Envelope for collections only, single resources unwrapped.

**Reasoning:**
- Collections need pagination metadata
- Single resources don't need wrapper
- Cleaner API for consumers

---

## 4. Implementation Challenges & Solutions

### 4.1 Concern Autoloading Issue

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

### 4.2 Module Naming with API Acronym

**Problem:** Zeitwerk inflection for "API" caused constant name mismatch.

**Root Cause:**
- File: `api_response.rb`
- Expected constant by Zeitwerk: `APIResponse` (not `ApiResponse`)
- Rails has inflection: `inflect.acronym "API"`

**Solution:** Name the module `API::V1::APIResponse` (uppercase API and Response).

### 4.3 File Permissions

**Problem:** Concern file had restrictive permissions (600).

**Solution:** `chmod 644` to make file readable.

### 4.4 Test Fixtures - Page Domain Validation

**Problem:** Tests failed with "Domain is invalid" when creating pages.

**Root Cause:** Pages require `PAGES_BASE_DOMAIN` env var for domain generation.

**Solution:**
1. Use fixtures with pre-set domains instead of creating pages in setup
2. Set `ENV['PAGES_BASE_DOMAIN']` in test setup for create tests

### 4.5 Test URL Generation - `to_param` Returns Slug

**Problem:** `api_v1_page_url(@page1)` generated URL with slug instead of ID.

**Root Cause:** Page model has `to_param` returning slug for SEO-friendly URLs.

**Solution:** Use explicit ID in test URLs:
```ruby
# Before (broken):
get api_v1_page_url(@page1)  # => /api/v1/pages/my-slug

# After (working):
get api_v1_page_url(id: @page1.id)  # => /api/v1/pages/123
```

### 4.6 Test Database Setup

**Problem:** Test database on port 5434 not running.

**Solution:** Use separate Docker Compose file for test environment:
```bash
docker compose -f docker-compose.test.yaml up -d
```

### 4.7 Migration Conflicts

**Problem:** Duplicate migrations for `api_tokens` table.

**Root Cause:** Migrations copied from engine to main app but also run from engine.

**Solution:** Use `db:schema:load` instead of `db:migrate` for test database, then manually mark migrations as run.

---

## 5. File Structure

```
submodules/core/
├── app/
│   └── controllers/
│       └── api/
│           └── v1/
│               ├── base_controller.rb
│               ├── pages_controller.rb
│               ├── categories_controller.rb (created, not tested)
│               ├── posts_controller.rb (created, not tested)
│               ├── images_controller.rb (created, not tested)
│               ├── revisions_controller.rb (created, not tested)
│               ├── newsletters_controller.rb (created, not tested)
│               ├── subscribers_controller.rb (created, not tested)
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
│           └── categories_controller_test.rb (16 tests)
└── fixtures/
    ├── pages.yml (updated)
    └── categories.yml (updated)
```

---

## 6. APIResponse Concern Details

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

## 7. Controllers Status

| Controller | Status | Tests | Notes |
|------------|--------|-------|-------|
| PagesController | ✅ Complete | 13 tests | Workspace-level CRUD |
| CategoriesController | ✅ Complete | 16 tests | Nested under pages |
| PostsController | ⏳ Pending | - | CRUD + publish under pages |
| ImagesController | ⏳ Pending | - | Upload/delete under posts |
| RevisionsController | ⏳ Pending | - | List, create, show_last, update_last, apply_last, share_last |
| NewslettersController | ⏳ Pending | - | CRUD at workspace level |
| SubscribersController | ⏳ Pending | - | List, create (upsert), delete under newsletters |

**Note:** All controllers have been updated to use `snake_case` JSON keys.

---

## 8. Next Steps

1. **Update remaining controllers** to use `snake_case` JSON keys
2. **Configure routes** for new controllers
3. **Write tests** for each controller
4. **Test manually** in Postman after each controller

---

## 9. Commands Reference

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
