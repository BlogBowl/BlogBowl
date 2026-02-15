# BlogBowl API v1 Implementation Plan

**Version:** 1.0
**Date:** December 28, 2025
**Branch:** `feat/api-v1`
**Issue:** https://github.com/BlogBowl/BlogBowl/issues/7

---

## Executive Summary

This document outlines the implementation plan for BlogBowl's Public API v1, enabling programmatic workspace management for content creation and administration. The API uses workspace-level token authentication and auto-generated Swagger documentation.

---

## 1. Current State Analysis

### 1.1 Existing Implementation

| Component | Status | Location |
|-----------|--------|----------|
| BaseController | Done | `core/app/controllers/api/v1/base_controller.rb` |
| PagesController | Done | `core/app/controllers/api/v1/pages_controller.rb` |
| APIToken Model | Done | `core/app/models/api_token.rb` |
| Apipie Config | Done | `config/initializers/apipie.rb` |
| Rack::Attack | Done | `config/initializers/rack_attack.rb` |
| Auth Tests | Done | `test/controllers/api/v1/base_controller_test.rb` |

### 1.2 Existing Features

- **Authentication:** Bearer token via `Authorization` header
- **Rate Limiting:** 1000 requests/minute per IP
- **Documentation:** Apipie at `/apidoc`
- **Workspace Scoping:** All queries filtered by `current_workspace`

---

## 2. Requirements

### 2.1 Resources to Implement

| Resource | Operations | Nesting |
|----------|------------|---------|
| Pages | CRUD | Workspace-level |
| Categories | CRUD | Under Pages |
| Posts | CRUD + Publish | Under Pages |
| Newsletters | CRUD | Workspace-level |
| Subscribers | Create, List, Delete | Under Newsletters |
| Newsletter Emails | CRUD + Send | Under Newsletters |

### 2.2 Content Handling

- Accept HTML or Markdown for post/email content
- Convert to TipTap JSON for `content_json` storage
- Sanitize unsafe HTML tags

---

## 3. Architecture Decisions

### 3.1 Response Envelope Strategy

**Decision Required:** See Section 7 for options and trade-offs.

### 3.2 Pagination Strategy

**Decision Required:** See Section 7 for options and trade-offs.

### 3.3 Error Response Format

```json
{
  "errors": [
    {
      "field": "name",
      "message": "can't be blank"
    }
  ]
}
```

### 3.4 State Guards

| Action | Already in State | Response |
|--------|------------------|----------|
| Publish Post | Already published | 200 + current state |
| Send Email | Already sent | 200 + current state |
| Create Subscriber | Email exists | 200 + existing record (upsert) |

---

## 4. Implementation Phases

### Phase 1: Foundation (5-6 hours)

#### 4.1.1 API Response Concern

**File:** `core/app/controllers/api/v1/concerns/api_response.rb`

```ruby
module API::V1::Concerns::ApiResponse
  extend ActiveSupport::Concern

  def render_resource(resource, status: :ok, serializer: nil)
    # Implementation based on envelope decision
  end

  def render_collection(scope, serializer: nil)
    # Pagination + meta based on pagination decision
  end

  def render_error(errors, status: :unprocessable_entity)
    render json: { errors: normalize_errors(errors) }, status: status
  end

  private

  def normalize_errors(errors)
    # Convert to [{ field:, message: }] format
  end
end
```

#### 4.1.2 Content Converter Service

**File:** `core/app/services/content_converter.rb`

```ruby
class ContentConverter
  def initialize(content, format:)
    @content = content
    @format = format # :html or :markdown
  end

  def convert
    html = @format == :markdown ? markdown_to_html : @content
    sanitized_html = sanitize_html(html)
    json = html_to_tiptap_json(sanitized_html)

    { content_html: sanitized_html, content_json: json }
  end

  private

  def markdown_to_html
    # Use existing markdown library
  end

  def sanitize_html(html)
    # Rails sanitize with allowlist
  end

  def html_to_tiptap_json(html)
    # Conversion logic
  end
end
```

#### 4.1.3 Pagination Concern

**File:** `core/app/controllers/api/v1/concerns/paginatable.rb`

```ruby
module API::V1::Concerns::Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  def paginate(scope)
    # Implementation based on pagination decision
  end

  def pagination_meta(pagy)
    {
      page: pagy.page,
      per_page: pagy.items,
      total: pagy.count,
      total_pages: pagy.pages
    }
  end
end
```

---

### Phase 2: Controllers (10-12 hours)

#### 4.2.1 CategoriesController

**Route:** `GET/POST /api/v1/pages/:page_id/categories`

**Endpoints:**
- `GET /pages/:page_id/categories` - List categories
- `GET /pages/:page_id/categories/:id` - Show category
- `POST /pages/:page_id/categories` - Create category
- `PATCH /pages/:page_id/categories/:id` - Update category
- `DELETE /pages/:page_id/categories/:id` - Delete category

**Reuse:** Logic from `API::Internal::CategoriesController`

---

#### 4.2.2 PostsController

**Route:** `GET/POST /api/v1/pages/:page_id/posts`

**Endpoints:**
- `GET /pages/:page_id/posts` - List posts (filterable)
- `GET /pages/:page_id/posts/:id` - Show post
- `POST /pages/:page_id/posts` - Create post
- `PATCH /pages/:page_id/posts/:id` - Update post
- `DELETE /pages/:page_id/posts/:id` - Delete post
- `POST /pages/:page_id/posts/:id/publish` - Publish post

**Filters:**
- `status` - draft, published, archived
- `category_id` - Filter by category
- `published_after` / `published_before` - Date range

**Content Input:**
```json
{
  "post": {
    "title": "My Post",
    "content": "<p>HTML content</p>",
    "content_format": "html"
  }
}
```

**Reuse:** Logic from `API::Internal::PostsController` + ContentConverter

---

#### 4.2.2.1 Post ImagesController

**Route:** `POST/DELETE /api/v1/pages/:page_id/posts/:post_id/images`

**Endpoints:**
- `POST /pages/:page_id/posts/:post_id/images` - Upload image to post
- `DELETE /pages/:page_id/posts/:post_id/images` - Delete images from post

**Upload Request:**
```
POST /api/v1/pages/1/posts/5/images
Content-Type: multipart/form-data

file: <binary image data>
```

**Upload Response:**
```json
{
  "url": "https://example.com/rails/active_storage/blobs/.../image.png"
}
```

**Delete Request:**
```json
{
  "image_ids": [1, 2, 3]
}
```

**Reuse:** Logic from `API::Internal::Pages::ImagesController`

---

#### 4.2.2.2 Post RevisionsController

**Route:** `GET/POST /api/v1/pages/:page_id/posts/:post_id/revisions`

**Endpoints:**
- `GET /pages/:page_id/posts/:post_id/revisions` - List revisions (last 20)
- `POST /pages/:page_id/posts/:post_id/revisions` - Create new revision
- `GET /pages/:page_id/posts/:post_id/revisions/last` - Get last revision
- `PATCH /pages/:page_id/posts/:post_id/revisions/last` - Update last revision
- `POST /pages/:page_id/posts/:post_id/revisions/last/apply` - Apply last revision to post
- `POST /pages/:page_id/posts/:post_id/revisions/last/share` - Generate share link for preview

**Revision Response:**
```json
{
  "id": 1,
  "postId": 5,
  "title": "My Post Title",
  "contentHtml": "<p>Content...</p>",
  "contentJson": {...},
  "seoTitle": "SEO Title",
  "seoDescription": "SEO Description",
  "ogTitle": "OG Title",
  "ogDescription": "OG Description",
  "shareId": "abc123",
  "createdAt": "2025-12-29T11:16:21.083Z",
  "updatedAt": "2025-12-29T11:16:21.083Z"
}
```

**Create/Update Revision Request:**
```json
{
  "title": "Updated Title",
  "content_html": "<p>New content</p>",
  "content_json": {...},
  "seo_title": "SEO Title",
  "seo_description": "SEO Description"
}
```

**Apply Response:** Returns updated revision with applied state

**Share Response:** Returns revision with generated `shareId` for preview URL

**Reuse:** Logic from `API::Internal::Pages::PostRevisionsController`

---

#### 4.2.3 NewslettersController

**Route:** `GET/POST /api/v1/newsletters`

**Endpoints:**
- `GET /newsletters` - List newsletters
- `GET /newsletters/:id` - Show newsletter
- `POST /newsletters` - Create newsletter
- `PATCH /newsletters/:id` - Update newsletter

**Validation:** Unique name/slug per workspace

---

#### 4.2.4 SubscribersController

**Route:** `GET/POST /api/v1/newsletters/:newsletter_id/subscribers`

**Endpoints:**
- `GET /newsletters/:newsletter_id/subscribers` - List subscribers
- `POST /newsletters/:newsletter_id/subscribers` - Create/upsert subscriber
- `DELETE /newsletters/:newsletter_id/subscribers/:id` - Remove subscriber

**Idempotency:** Create returns existing record if email exists (upsert behavior)

---

#### 4.2.5 EmailsController

**Route:** `GET/POST /api/v1/newsletters/:newsletter_id/emails`

**Endpoints:**
- `GET /newsletters/:newsletter_id/emails` - List emails
- `GET /newsletters/:newsletter_id/emails/:id` - Show email
- `POST /newsletters/:newsletter_id/emails` - Create email
- `PATCH /newsletters/:newsletter_id/emails/:id` - Update email
- `POST /newsletters/:newsletter_id/emails/:id/send` - Send email

**Send Action:**
- Queues `SendNewsletterJob` (async via Sidekiq)
- Accepts optional `scheduled_at` parameter
- Returns current status
- Idempotent: already-sent emails return 200 with state

---

### Phase 3: Routes Configuration

**File:** `core/config/routes.rb`

```ruby
namespace :api do
  namespace :v1 do
    resources :pages, only: [:index, :show, :create, :update] do
      resources :categories, only: [:index, :show, :create, :update, :destroy]
      resources :posts, only: [:index, :show, :create, :update, :destroy] do
        post :publish, on: :member

        # Post Images
        resources :images, only: [:create, :destroy]

        # Post Revisions
        resources :revisions, only: [:index, :create] do
          collection do
            get :last, to: 'revisions#show_last'
            patch :last, to: 'revisions#update_last'
            post 'last/apply', to: 'revisions#apply_last'
            post 'last/share', to: 'revisions#share_last'
          end
        end
      end
    end

    resources :newsletters, only: [:index, :show, :create, :update] do
      resources :subscribers, only: [:index, :create, :destroy]
      resources :emails, only: [:index, :show, :create, :update] do
        post :send_email, on: :member, path: 'send'
      end
    end
  end
end
```

---

### Phase 4: Testing (6-8 hours)

#### 4.4.1 Request Specs

| Controller | Test Cases |
|------------|------------|
| Categories | CRUD, scoping, validation |
| Posts | CRUD, publish, filters, content conversion |
| Newsletters | CRUD, workspace scoping |
| Subscribers | Create, upsert, list, delete |
| Emails | CRUD, send, scheduling, idempotency |

#### 4.4.2 Service Specs

| Service | Test Cases |
|---------|------------|
| ContentConverter | HTML input, Markdown input, unsafe tag removal, edge cases |

#### 4.4.3 Job Specs

| Job | Test Cases |
|-----|------------|
| SendNewsletterJob | Correct params, scheduling |

---

### Phase 5: Documentation (2 hours)

- Update Apipie param groups for all resources
- Add pagination examples
- Document rate limits
- Add error response examples
- Include authentication guide

---

## 5. Behavior Contracts

### 5.1 Security

| Rule | Implementation |
|------|----------------|
| Workspace Scoping | All queries filtered by `current_workspace` |
| Out-of-scope Access | Return 404 (not 403) to prevent information leak |
| Content Sanitization | Strip unsafe HTML tags via Rails sanitize |

### 5.2 Pagination

| Parameter | Default | Max | Required |
|-----------|---------|-----|----------|
| `page` | 1 | - | No |
| `per_page` | 25 | 100 | No |

### 5.3 Rate Limiting

- **Limit:** 1000 requests per minute per IP
- **Response:** 429 Too Many Requests
- **Headers:** `X-RateLimit-Limit`, `X-RateLimit-Remaining`

---

## 6. Estimated Effort

| Phase | Hours | Dependencies |
|-------|-------|--------------|
| Phase 1: Foundation | 5-6h | None |
| Phase 2: Controllers | 12-15h | Phase 1 |
| - Categories | 1-2h | |
| - Posts | 3-4h | |
| - Images | 1-2h | |
| - Revisions | 2-3h | |
| - Newsletters | 1-2h | |
| - Subscribers | 1-2h | |
| - Emails | 2-3h | |
| Phase 3: Routes | 1h | Phase 2 |
| Phase 4: Testing | 8-10h | Phase 2 |
| Phase 5: Documentation | 2h | Phase 2 |
| **Total** | **28-34h** | |

---

## 7. Final Decisions

### 7.1 Response Envelope Strategy

**Decision:** Envelope for collections only, single resources unwrapped.

**Collection Response Format:**
```json
{
  "page": 1,
  "size": 10,
  "total": 100,
  "result": [
    {
      "id": 1,
      "domain": "blog.example.com",
      "name": "My Blog",
      "workspaceId": 1,
      "createdAt": "2025-12-29T11:16:21.083Z",
      "updatedAt": "2025-12-29T11:16:21.083Z"
    }
  ]
}
```

**Single Resource Response Format:**
```json
{
  "id": 1,
  "domain": "blog.example.com",
  "name": "My Blog",
  "workspaceId": 1,
  "createdAt": "2025-12-29T11:16:21.083Z",
  "updatedAt": "2025-12-29T11:16:21.083Z"
}
```

**Rationale:** No existing API consumers, so no breaking changes. Consistent envelope for all collection endpoints.

---

### 7.2 Pagination Strategy

**Decision:** Offset-based pagination, always required with defaults.

**Parameters:**
| Parameter | Default | Max | Description |
|-----------|---------|-----|-------------|
| `page` | 1 | - | Page number (1-indexed) |
| `size` | 10 | 100 | Items per page |

**Behavior:**
- Pagination is always applied (not optional)
- Missing params default to `page=1, size=10`
- All collection endpoints are paginated

**Example Request:**
```
GET /api/v1/pages?page=2&size=20
```

**Example Response:**
```json
{
  "page": 2,
  "size": 20,
  "total": 45,
  "result": [...]
}
```

---

## 8. Appendix

### A. File Structure

```
submodules/core/
├── app/
│   ├── controllers/
│   │   └── api/
│   │       └── v1/
│   │           ├── base_controller.rb (exists)
│   │           ├── pages_controller.rb (exists - needs update for pagination)
│   │           ├── categories_controller.rb (new)
│   │           ├── posts_controller.rb (new)
│   │           ├── images_controller.rb (new)
│   │           ├── revisions_controller.rb (new)
│   │           ├── newsletters_controller.rb (new)
│   │           ├── subscribers_controller.rb (new)
│   │           ├── emails_controller.rb (new)
│   │           └── concerns/
│   │               ├── api_response.rb (new)
│   │               └── paginatable.rb (new)
│   └── services/
│       └── content_converter.rb (new)
└── test/
    ├── controllers/
    │   └── api/
    │       └── v1/
    │           ├── categories_controller_test.rb (new)
    │           ├── posts_controller_test.rb (new)
    │           ├── images_controller_test.rb (new)
    │           ├── revisions_controller_test.rb (new)
    │           ├── newsletters_controller_test.rb (new)
    │           ├── subscribers_controller_test.rb (new)
    │           └── emails_controller_test.rb (new)
    └── services/
        └── content_converter_test.rb (new)
```

### B. API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| **Pages** | | |
| GET | /api/v1/pages | List pages |
| GET | /api/v1/pages/:id | Get page |
| POST | /api/v1/pages | Create page |
| PATCH | /api/v1/pages/:id | Update page |
| **Categories** | | |
| GET | /api/v1/pages/:page_id/categories | List categories |
| GET | /api/v1/pages/:page_id/categories/:id | Get category |
| POST | /api/v1/pages/:page_id/categories | Create category |
| PATCH | /api/v1/pages/:page_id/categories/:id | Update category |
| DELETE | /api/v1/pages/:page_id/categories/:id | Delete category |
| **Posts** | | |
| GET | /api/v1/pages/:page_id/posts | List posts |
| GET | /api/v1/pages/:page_id/posts/:id | Get post |
| POST | /api/v1/pages/:page_id/posts | Create post |
| PATCH | /api/v1/pages/:page_id/posts/:id | Update post |
| DELETE | /api/v1/pages/:page_id/posts/:id | Delete post |
| POST | /api/v1/pages/:page_id/posts/:id/publish | Publish post |
| **Post Images** | | |
| POST | /api/v1/pages/:page_id/posts/:post_id/images | Upload image |
| DELETE | /api/v1/pages/:page_id/posts/:post_id/images/:id | Delete image |
| **Post Revisions** | | |
| GET | /api/v1/pages/:page_id/posts/:post_id/revisions | List revisions |
| POST | /api/v1/pages/:page_id/posts/:post_id/revisions | Create revision |
| GET | /api/v1/pages/:page_id/posts/:post_id/revisions/last | Get last revision |
| PATCH | /api/v1/pages/:page_id/posts/:post_id/revisions/last | Update last revision |
| POST | /api/v1/pages/:page_id/posts/:post_id/revisions/last/apply | Apply last revision |
| POST | /api/v1/pages/:page_id/posts/:post_id/revisions/last/share | Share last revision |
| **Newsletters** | | |
| GET | /api/v1/newsletters | List newsletters |
| GET | /api/v1/newsletters/:id | Get newsletter |
| POST | /api/v1/newsletters | Create newsletter |
| PATCH | /api/v1/newsletters/:id | Update newsletter |
| **Subscribers** | | |
| GET | /api/v1/newsletters/:newsletter_id/subscribers | List subscribers |
| POST | /api/v1/newsletters/:newsletter_id/subscribers | Create subscriber |
| DELETE | /api/v1/newsletters/:newsletter_id/subscribers/:id | Delete subscriber |
| **Newsletter Emails** | | |
| GET | /api/v1/newsletters/:newsletter_id/emails | List emails |
| GET | /api/v1/newsletters/:newsletter_id/emails/:id | Get email |
| POST | /api/v1/newsletters/:newsletter_id/emails | Create email |
| PATCH | /api/v1/newsletters/:newsletter_id/emails/:id | Update email |
| POST | /api/v1/newsletters/:newsletter_id/emails/:id/send | Send email |

---

**Document Status:** Final - Ready for implementation
