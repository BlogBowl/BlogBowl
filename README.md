<p align="center">
  <img src="https://framerusercontent.com/images/tjgm6B1wvt21XiKVxIqd25n6aQ.png" alt="BlogBowl Logo" width="100">
</p>

<h1 align="center">BlogBowl</h1>

<p align="center">
  <i>Launch a Blog, Changelog, and Help Center in 60 seconds - No code, no headaches. Plug-and-play blogging platform. Built-in notion editor. SEO optimized templates.</i>
</p>

<p align="center">
  <a href="https://github.com/BlogBowl/BlogBowl/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/BlogBowl/BlogBowl.svg" alt="MIT License" />
  </a>
</p>

---

## 🚀 What is BlogBowl?
BlogBowl is an open-source, self-hosted blogging platform designed for **blogs, product changelogs, and help documentation**.

- 🕐 Launch a full-featured blog or help center **in minutes**
- ⚡ Prebuilt templates that are **SEO-optimized and lightning fast**
- ✍️ Write with a clean, **Notion-like editor**
- 💌 Built-in newsletter support with **Postmark** integration
- 🌍 Bring your own **custom domain** or use reverse proxy for subfolder setup
- 👥 Collect subscribers
- 📩 Manage and send newsletters

![Alt Text for your GIF](https://blogbowl-gen.sfo3.cdn.digitaloceanspaces.com/other/blogbowl-demo.gif)

### [📺 Watch the full 5-minute demo video](https://www.blogbowl.io/blog-hosting#demo)

---

## 🛠 Getting started:

### 🐳 Installing with Docker (Production)
1. Create .env file and paste content from `.env.example`.
2. Adjust the values in `.env` to your setup.
3. To start BlogBowl with postgres and redis run:
    ```bash
    docker compose up -d
    ```
4. Open your browser and visit:
    ```
    http://localhost:3000
    ```

### 💻 Local Development Setup

**Prerequisites:** Ruby 3.2.2, Bun, Docker

1. Clone with submodules:
    ```bash
    git clone --recurse-submodules https://github.com/BlogBowl/BlogBowl.git
    cd BlogBowl
    ```

2. Create `.env` file from example and set the database URL:
    ```bash
    cp .env.example .env
    ```
    Update `DATABASE_URL` in `.env`:
    ```
    DATABASE_URL=postgresql://development:development@localhost:5435/blogbowl
    ```

3. Add hostname to `/etc/hosts`:
    ```bash
    echo "127.0.0.1 blogbowl.test" | sudo tee -a /etc/hosts
    ```

4. Start infrastructure and install dependencies:
    ```bash
    docker compose -f docker-compose.dev.yaml up -d
    bundle install
    bun install
    ```

5. Setup database and start the server:
    ```bash
    RAILS_ENV=development bin/rails db:migrate db:seed
    bin/dev
    ```

6. Open your browser and visit:
    ```
    http://blogbowl.test:3000/sign_in
    ```

### 🔧 Troubleshooting

<details>
<summary><b>Docker services not starting</b></summary>

```bash
# Check if ports are already in use
lsof -i :5435  # PostgreSQL
lsof -i :6380  # Redis

# Restart Docker services
docker compose -f docker-compose.dev.yaml down
docker compose -f docker-compose.dev.yaml up -d

# Check service health
docker compose -f docker-compose.dev.yaml ps
```
</details>

<details>
<summary><b>Database connection errors</b></summary>

```bash
# Verify PostgreSQL is running and healthy
docker compose -f docker-compose.dev.yaml ps postgres

# Test connection manually
psql postgresql://development:development@localhost:5435/blogbowl

# Reset database if corrupted (Warning: deletes data)
docker compose -f docker-compose.dev.yaml down -v
docker compose -f docker-compose.dev.yaml up -d
bin/rails db:prepare
```
</details>

<details>
<summary><b>Submodule issues</b></summary>

```bash
# Initialize submodules after fresh clone
git submodule update --init --recursive

# Update submodules to latest
git submodule update --remote

# Reset submodule to tracked commit
git submodule update --force
```
</details>

<details>
<summary><b>Asset compilation errors</b></summary>

```bash
# Clear build artifacts and reinstall
rm -rf node_modules app/assets/builds
bun install
bun build
bun build:css
```
</details>

<details>
<summary><b>Host not resolving (blogbowl.test)</b></summary>

Ensure `/etc/hosts` contains:
```
127.0.0.1 blogbowl.test
```
Flush DNS cache (macOS):
```bash
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```
</details>

<details>
<summary><b>Redis connection errors</b></summary>

```bash
# Check Redis is running
docker compose -f docker-compose.dev.yaml ps redis

# Test connection
redis-cli -p 6380 ping  # Should return PONG
```
</details>

### 🔐 Default Credentials

When the server starts for the first time, the database is automatically seeded with a default admin user.

| Field       | Value               |
|--------------|---------------------|
| **Email**    | `admin@example.com` |
| **Password** | `changeme`          |

👉 After your first login, make sure to **update the default credentials** for security.

---

## 💌 Sending Newsletters
Newsletter support is optional - you can enable it if you want to send updates to your readers.

BlogBowl uses [Postmark](https://www.postmarkapp.com/?via=db92a4) for email delivery.
Postmark offers up to 100 free emails per month, perfect for testing.

To enable it:
1. Create a free Postmark account.
2. Set these environment variables in your .env:
   ```
    POSTMARK_ACCOUNT_TOKEN=your-postmark-account-token
    POSTMARK_X_API_KEY=your-random-webhook-secret
    ```
> Pro tip: If you want to **support BlogBowl**, register on PostmarkApp using our [referral link](https://www.postmarkapp.com/?via=db92a4).
## 🧩 Tech Stack
- Ruby on Rails
- PostgreSQL (database)
- Redis (cache)
- Sidekiq - background jobs
- Postmark (email delivery)

---

## 📄 License

BlogBowl is open-source under the [MIT License](https://github.com/BlogBowl/BlogBowl/blob/main/LICENSE).

---
<p align="center">Built with ❤️ by creators, for creators.</p> 


