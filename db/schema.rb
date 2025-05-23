# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_23_122831) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "author_links", force: :cascade do |t|
    t.string "title"
    t.string "url"
    t.decimal "order"
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_author_links_on_author_id"
  end

  create_table "authors", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email", null: false
    t.string "position"
    t.text "short_description"
    t.text "long_description"
    t.boolean "active", default: true
    t.bigint "member_id", null: false
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_authors_on_member_id"
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "page_id", null: false
    t.string "name"
    t.text "description"
    t.integer "parent_id"
    t.string "slug"
    t.string "color"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id", "name"], name: "index_categories_on_page_id_and_name", unique: true, where: "(parent_id IS NULL)"
    t.index ["page_id", "parent_id", "name"], name: "index_categories_on_page_id_and_parent_id_and_name", unique: true, where: "(parent_id IS NOT NULL)"
    t.index ["page_id", "parent_id", "slug"], name: "index_categories_on_page_id_and_parent_id_and_slug", unique: true, where: "(parent_id IS NOT NULL)"
    t.index ["page_id", "slug"], name: "index_categories_on_page_id_and_slug", unique: true, where: "(parent_id IS NULL)"
    t.index ["page_id"], name: "index_categories_on_page_id"
  end

  create_table "links", force: :cascade do |t|
    t.string "title"
    t.string "url"
    t.string "link_type"
    t.string "location"
    t.integer "order"
    t.string "domain"
    t.bigint "page_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id"], name: "index_links_on_page_id"
  end

  create_table "members", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.string "permissions", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_members_on_user_id"
    t.index ["workspace_id"], name: "index_members_on_workspace_id"
  end

  create_table "page_settings", force: :cascade do |t|
    t.bigint "page_id", null: false
    t.text "seo_title"
    t.text "seo_description"
    t.text "title"
    t.text "description"
    t.text "head_html"
    t.text "body_html"
    t.string "template", default: "default", null: false
    t.string "cta_title"
    t.text "cta_description"
    t.string "cta_button"
    t.string "cta_button_link"
    t.boolean "subfolder_enabled", default: false, null: false
    t.string "theme"
    t.boolean "cta_enabled"
    t.boolean "newsletter_cta_enabled"
    t.string "newsletter_cta_title"
    t.string "newsletter_cta_description"
    t.string "newsletter_cta_button"
    t.string "newsletter_cta_disclaimer"
    t.string "logo_text"
    t.string "logo_link"
    t.string "copyright"
    t.boolean "with_sitemap"
    t.boolean "with_search"
    t.boolean "with_rss"
    t.string "name"
    t.string "header_cta_button"
    t.string "header_cta_button_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id"], name: "index_page_settings_on_page_id"
  end

  create_table "pages", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.string "slug", null: false
    t.string "name"
    t.string "domain"
    t.string "name_slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_pages_on_domain", unique: true
    t.index ["workspace_id", "name_slug"], name: "index_pages_on_workspace_id_and_name_slug", unique: true
    t.index ["workspace_id"], name: "index_pages_on_workspace_id"
  end

  create_table "post_authors", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.bigint "author_id", null: false
    t.integer "role", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_post_authors_on_author_id"
    t.index ["post_id"], name: "index_post_authors_on_post_id"
  end

  create_table "post_revisions", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.string "title"
    t.text "content_html"
    t.jsonb "content_json"
    t.integer "kind", default: 0, null: false
    t.text "seo_title"
    t.text "seo_description"
    t.text "og_title"
    t.text "og_description"
    t.string "share_id"
    t.datetime "shared_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_post_revisions_on_post_id"
    t.index ["share_id"], name: "index_post_revisions_on_share_id", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "page_id", null: false
    t.bigint "category_id"
    t.string "title"
    t.text "content_html"
    t.jsonb "content_json"
    t.text "seo_title"
    t.text "seo_description"
    t.text "og_title"
    t.text "og_description"
    t.string "slug"
    t.string "description"
    t.integer "status", default: 0, null: false
    t.datetime "archived_at"
    t.datetime "first_published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_posts_on_category_id"
    t.index ["page_id", "slug"], name: "index_posts_on_page_id_and_slug", unique: true
    t.index ["page_id"], name: "index_posts_on_page_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "workspace_settings", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.string "html_lang"
    t.string "locale"
    t.string "title"
    t.boolean "with_watermark", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workspace_id"], name: "index_workspace_settings_on_workspace_id"
  end

  create_table "workspaces", force: :cascade do |t|
    t.string "title", null: false
    t.string "uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_workspaces_on_uuid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "author_links", "authors", on_delete: :cascade
  add_foreign_key "authors", "members", on_delete: :cascade
  add_foreign_key "categories", "pages", on_delete: :cascade
  add_foreign_key "links", "pages", on_delete: :cascade
  add_foreign_key "members", "users", on_delete: :cascade
  add_foreign_key "members", "workspaces", on_delete: :cascade
  add_foreign_key "page_settings", "pages", on_delete: :cascade
  add_foreign_key "pages", "workspaces", on_delete: :cascade
  add_foreign_key "post_authors", "authors", on_delete: :cascade
  add_foreign_key "post_authors", "posts", on_delete: :cascade
  add_foreign_key "post_revisions", "posts", on_delete: :cascade
  add_foreign_key "posts", "categories", on_delete: :nullify
  add_foreign_key "posts", "pages", on_delete: :cascade
  add_foreign_key "sessions", "users"
  add_foreign_key "workspace_settings", "workspaces", on_delete: :cascade
end
