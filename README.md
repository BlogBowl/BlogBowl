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

### 🐳 Installing with Docker
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


