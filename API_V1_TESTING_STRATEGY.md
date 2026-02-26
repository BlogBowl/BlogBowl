# API v1 Testing Strategy (Postman + curl)

This document outlines a local testing strategy for the current API v1 PRs on branch `feat/api-v1`.
It covers required setup, Postman usage, and curl examples for all endpoints currently routed
and implemented in the codebase.

Scope references:
- `API_V1_IMPLEMENTATION_PLAN.md`
- `API_V1_IMPLEMENTATION_LOG.md`
- `submodules/core/config/routes.rb`

## 1) Prerequisites

1. App running locally:
   - Start the app using your standard dev flow (for example `bin/dev`).
   - Confirm the API base URL is reachable.
   - API requests require `Host: blogbowl.test` header due to route constraints. In production this will be the actual domain.

2. Test data:
   - You need a user, workspace, and API token.
   - Create an API token via the UI (Settings -> API Tokens) or Rails console:
     - `APIToken.create!(name: "Test Token", user: User.first, workspace: Workspace.first)`

3. TipTap parser (for content conversion tests):
   - Ensure `parse-tiptap-blogbowl` dependencies are installed.
   - `TIPTAP_PARSER_PATH` must resolve to `/Users/vika/projects/blogbowl/parse-tiptap-blogbowl`.
   - The API will call `bun run cli.ts` under the hood.

4. Optional: Postmark-related tests
   - Sending emails locally may fail if SSL is not configured. This is an environment issue.

## 2) Common Variables

Set these once for Postman and curl:

- `BASE_URL` (default `http://localhost:3000`)
- `TOKEN` (API token)
- `PAGE_ID`
- `CATEGORY_ID`
- `POST_ID`
- `NEWSLETTER_ID`
- `SUBSCRIBER_ID`
- `EMAIL_ID`

Example for curl:

```bash
export BASE_URL="http://localhost:3000"
export TOKEN="YOUR_TOKEN"
```

## 3) Postman Strategy

### 3.1 Environment

Create a Postman environment with variables:
- `base_url`
- `token`
- `page_id`
- `category_id`
- `post_id`
- `newsletter_id`
- `subscriber_id`
- `email_id`

Set a collection-level authorization:
- Type: Bearer Token
- Token: `{{token}}`

### 3.2 Collection Structure

Create folders by resource:
- Pages
- Categories
- Posts
- Cover Image
- Newsletters
- Subscribers
- Emails
- Auth/Errors (negative tests)
- Rate Limit (optional)

### 3.3 Typical Flow (Happy Path)

1. Create Page
2. Create Category (under Page)
3. Create Post (under Page)
4. Publish Post (optional schedule)
5. Upload Cover Image (optional)
6. Create Newsletter
7. Create Subscriber
8. Create Email (draft)
9. Send Email (requires active + verified subscriber)

### 3.4 Negative Tests

For each resource:
- Missing/invalid token -> 401
- Wrong workspace -> 404
- Invalid payload -> 422
- Invalid schedule date -> 422

## 4) curl Examples by Endpoint

All examples assume:

```bash
export BASE_URL="http://localhost:3000"
export TOKEN="YOUR_TOKEN"
```

### 4.1 Pages

List pages:
```bash
curl -s "$BASE_URL/api/v1/pages?page=1&size=10" \
  -H "Authorization: Bearer $TOKEN"
```

Create page:
```bash
curl -s -X POST "$BASE_URL/api/v1/pages" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"page":{"name":"My Page","slug":"my-page"}}'
```

Show page:
```bash
curl -s "$BASE_URL/api/v1/pages/$PAGE_ID" \
  -H "Authorization: Bearer $TOKEN"
```

Update page:
```bash
curl -s -X PATCH "$BASE_URL/api/v1/pages/$PAGE_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"page":{"name":"Updated Page"}}'
```

### 4.2 Categories (nested under Pages)

List categories:
```bash
curl -s "$BASE_URL/api/v1/pages/$PAGE_ID/categories" \
  -H "Authorization: Bearer $TOKEN"
```

Create category:
```bash
curl -s -X POST "$BASE_URL/api/v1/pages/$PAGE_ID/categories" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"category":{"name":"Tech","description":"Tech posts"}}'
```

Show category:
```bash
curl -s "$BASE_URL/api/v1/pages/$PAGE_ID/categories/$CATEGORY_ID" \
  -H "Authorization: Bearer $TOKEN"
```

Update category:
```bash
curl -s -X PATCH "$BASE_URL/api/v1/pages/$PAGE_ID/categories/$CATEGORY_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"category":{"name":"Updated Tech"}}'
```

Delete category:
```bash
curl -s -X DELETE "$BASE_URL/api/v1/pages/$PAGE_ID/categories/$CATEGORY_ID" \
  -H "Authorization: Bearer $TOKEN"
```

### 4.3 Posts (nested under Pages)

List posts:
```bash
curl -s "$BASE_URL/api/v1/pages/$PAGE_ID/posts?status=draft" \
  -H "Authorization: Bearer $TOKEN"
```

Create post (HTML -> JSON conversion):
```bash
curl -s -X POST "$BASE_URL/api/v1/pages/$PAGE_ID/posts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"post":{"title":"My Post","content_html":"<p>Hello</p>"}}'
```

Create post (JSON -> HTML conversion):
```bash
curl -s -X POST "$BASE_URL/api/v1/pages/$PAGE_ID/posts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"post":{"title":"JSON Post","content_json":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Hello JSON"}]}]}}}'
```

Show post:
```bash
curl -s "$BASE_URL/api/v1/pages/$PAGE_ID/posts/$POST_ID" \
  -H "Authorization: Bearer $TOKEN"
```

Update post:
```bash
curl -s -X PATCH "$BASE_URL/api/v1/pages/$PAGE_ID/posts/$POST_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"post":{"title":"Updated Title"}}'
```

Delete post:
```bash
curl -s -X DELETE "$BASE_URL/api/v1/pages/$PAGE_ID/posts/$POST_ID" \
  -H "Authorization: Bearer $TOKEN"
```

Publish post (immediate):
```bash
curl -s -X POST "$BASE_URL/api/v1/pages/$PAGE_ID/posts/$POST_ID/publish" \
  -H "Authorization: Bearer $TOKEN"
```

Publish post (scheduled):
```bash
curl -s -X POST "$BASE_URL/api/v1/pages/$PAGE_ID/posts/$POST_ID/publish" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scheduled_at":"2030-01-01T10:00:00Z"}'
```

### 4.4 Cover Image (resource under Posts)

Full CRUD for cover images. Endpoints accept multipart file upload.

Show cover image:
```bash
curl -s "$BASE_URL/api/v1/pages/$PAGE_ID/posts/$POST_ID/cover_image" \
  -H "Authorization: Bearer $TOKEN"
```

Upload cover image:
```bash
curl -s -X POST "$BASE_URL/api/v1/pages/$PAGE_ID/posts/$POST_ID/cover_image" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/image.png"
```

Replace cover image:
```bash
curl -s -X PATCH "$BASE_URL/api/v1/pages/$PAGE_ID/posts/$POST_ID/cover_image" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/new-image.png"
```

Delete cover image:
```bash
curl -s -X DELETE "$BASE_URL/api/v1/pages/$PAGE_ID/posts/$POST_ID/cover_image" \
  -H "Authorization: Bearer $TOKEN"
```

### 4.5 Revisions (auto-created on post update)

Revisions are no longer exposed as a public API endpoint. Instead, a history
revision is automatically created whenever a post is updated via `PATCH /posts/:id`.
No manual revision management is needed by API consumers.

### 4.6 Newsletters

List newsletters:
```bash
curl -s "$BASE_URL/api/v1/newsletters" \
  -H "Authorization: Bearer $TOKEN"
```

Create newsletter:
```bash
curl -s -X POST "$BASE_URL/api/v1/newsletters" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"newsletter":{"name":"Weekly Digest"}}'
```

Show newsletter:
```bash
curl -s "$BASE_URL/api/v1/newsletters/$NEWSLETTER_ID" \
  -H "Authorization: Bearer $TOKEN"
```

Update newsletter:
```bash
curl -s -X PATCH "$BASE_URL/api/v1/newsletters/$NEWSLETTER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"newsletter":{"name":"Updated Digest"}}'
```

### 4.7 Subscribers (nested under Newsletters)

List subscribers:
```bash
curl -s "$BASE_URL/api/v1/newsletters/$NEWSLETTER_ID/subscribers" \
  -H "Authorization: Bearer $TOKEN"
```

Create subscriber (upsert by email):
```bash
curl -s -X POST "$BASE_URL/api/v1/newsletters/$NEWSLETTER_ID/subscribers" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"subscriber":{"email":"user@example.com"}}'
```

Delete subscriber:
```bash
curl -s -X DELETE "$BASE_URL/api/v1/newsletters/$NEWSLETTER_ID/subscribers/$SUBSCRIBER_ID" \
  -H "Authorization: Bearer $TOKEN"
```

### 4.8 Emails (nested under Newsletters)

List emails:
```bash
curl -s "$BASE_URL/api/v1/newsletters/$NEWSLETTER_ID/emails" \
  -H "Authorization: Bearer $TOKEN"
```

Create email (draft):
```bash
curl -s -X POST "$BASE_URL/api/v1/newsletters/$NEWSLETTER_ID/emails" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email":{"subject":"Hello","preview":"Preview text","content_html":"<p>Content</p>"}}'
```

Show email:
```bash
curl -s "$BASE_URL/api/v1/newsletters/$NEWSLETTER_ID/emails/$EMAIL_ID" \
  -H "Authorization: Bearer $TOKEN"
```

Update email (draft only):
```bash
curl -s -X PATCH "$BASE_URL/api/v1/newsletters/$NEWSLETTER_ID/emails/$EMAIL_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email":{"subject":"Updated Subject"}}'
```

Delete email (draft only):
```bash
curl -s -X DELETE "$BASE_URL/api/v1/newsletters/$NEWSLETTER_ID/emails/$EMAIL_ID" \
  -H "Authorization: Bearer $TOKEN"
```

Send email (requires active + verified subscribers):
```bash
curl -s -X POST "$BASE_URL/api/v1/newsletters/$NEWSLETTER_ID/emails/$EMAIL_ID/send" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scheduled_at":"2030-01-01T10:00:00Z"}'
```

## 5) Expected Response Patterns

- Collection responses:
  - `{"page":1,"size":10,"total":N,"result":[...] }`
- Single resource:
  - Unwrapped JSON object
- Validation errors:
  - `{"errors":[{"field":"name","message":"can't be blank"}]}`
- Simple errors:
  - `{"error":"Message"}`

## 6) Suggested Negative Tests

- Unauthorized:
  - Omit `Authorization` header -> 401
  - Invalid token -> 401

- Wrong workspace:
  - Use ID from another workspace -> 404

- Validation:
  - Create page with empty name -> 422
  - Create category with empty name -> 422
  - Create subscriber with empty email -> 422

- Scheduling:
  - `scheduled_at` in the past -> 422

## 7) Notes on Current Gaps

These are useful checkpoints while testing the current PRs:

- Subscribers update: route exists, but the controller does not implement `update`.

### Resolved gaps:

- ~~Revisions routes~~: The public revisions API has been removed. Revisions are now created automatically when a post is updated.
- ~~Cover image~~: The `ImagesController` now fully implements cover image CRUD (GET, POST, PATCH, DELETE).
