# This migration comes from core_engine (originally 20250906135424)
# This migration comes from core_engine (originally 20250906135424)
# This migration comes from core_engine (originally 20250906135424)
class CreateInitialSchema < ActiveRecord::Migration[8.0]
  def change

    # workspace & settings
    create_table :workspaces do |t|
      t.string :title, null: false
      t.string :uuid

      t.timestamps
    end
    add_index :workspaces, :uuid, unique: true

    create_table :workspace_settings do |t|
      t.string :html_lang
      t.string :locale
      t.references :workspace, null: false, foreign_key: { on_delete: :cascade }
      t.string :title
      t.boolean :with_watermark, default: true, null: false

      t.timestamps
    end

    # members & authors
    create_table :members, force: :cascade do |t|
      t.string :permissions, default: [], array: true
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :workspace, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    create_table :authors do |t|
      t.string :first_name
      t.string :last_name
      t.string :email, null: false
      t.string :position
      t.text :short_description
      t.text :long_description
      t.boolean :active, default: true
      t.string :slug
      t.references :member, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    create_table :author_links do |t|
      t.string :title
      t.string :url
      t.decimal :order
      t.references :author, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    # newsletter
    create_table :newsletters, force: :cascade do |t|
      t.references :workspace, null: false, foreign_key: { on_delete: :cascade }
      t.text :name
      t.text :name_slug
      t.bigint :postmark_server_id
      t.text :postmark_server_token
      t.text :uuid

      t.timestamps
    end

    add_index :newsletters, :postmark_server_id, unique: true
    add_index :newsletters, :postmark_server_token, unique: true
    add_index :newsletters, :uuid, unique: true
    add_index :newsletters, [:workspace_id, :name_slug], unique: true

    create_table :newsletter_emails, force: :cascade do |t|
      t.string :subject
      t.string :preview
      t.string :content_html
      t.jsonb :content_json
      t.datetime :sent_at
      t.string :status, null: false, default: "draft"
      t.string :slug
      t.datetime :scheduled_at
      t.string :postmark_tag
      t.string :postmark_bulk_id
      t.string :job_id
      t.integer :deliver_count, default: 0
      t.integer :open_count, default: 0
      t.integer :click_count, default: 0
      t.integer :bounce_count, default: 0
      t.integer :spam_count, default: 0
      t.references :author, foreign_key: { on_delete: :nullify }
      t.references :newsletter, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
    add_index :newsletter_emails, :postmark_tag, unique: true

    create_table :newsletter_settings, force: :cascade do |t|
      t.string :webhook_url
      t.string :webhook_auth
      t.string :domain
      t.integer :postmark_domain_id
      t.string :sender_name
      t.string :reply_to_email
      t.string :sender
      t.string :sender_email
      t.string :footer
      t.references :newsletter, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
    add_index :newsletter_settings, :domain
    add_index :newsletter_settings, :postmark_domain_id, unique: true

    # page, categories and page settings
    create_table :pages do |t|
      t.references :workspace, null: false, foreign_key: { on_delete: :cascade }
      t.string :slug, null: false
      t.string :name
      t.string :domain
      t.string :name_slug
      t.string :base_domain

      t.timestamps
    end
    add_index :pages, :domain, unique: true
    add_index :pages, [:workspace_id, :name_slug], unique: true

    create_table :page_settings do |t|
      t.references :page, null: false, foreign_key: { on_delete: :cascade }
      t.text :seo_title
      t.text :seo_description
      t.text :title
      t.text :description
      t.text :head_html
      t.text :body_html
      t.string :template, default: "default", null: false
      t.string :cta_title
      t.text :cta_description
      t.string :cta_button
      t.string :cta_button_link
      t.boolean :subfolder_enabled, default: false
      t.string :theme
      t.boolean :cta_enabled
      t.boolean :newsletter_cta_enabled
      t.string :newsletter_cta_title
      t.string :newsletter_cta_description
      t.string :newsletter_cta_button
      t.string :newsletter_cta_disclaimer
      t.string :logo_text
      t.string :logo_link
      t.string :copyright
      t.boolean :with_sitemap
      t.boolean :with_search
      t.boolean :with_rss
      t.string :name
      t.string :header_cta_button
      t.string :header_cta_button_link
      t.references :newsletter, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    create_table :categories do |t|
      t.string :name
      t.text :description
      t.integer :parent_id
      t.string :slug
      t.string :color
      t.string :image_url
      t.references :page, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :categories, [:page_id, :parent_id, :name], unique: true, name: 'index_categories_on_page_id_and_parent_id_and_name', where: 'parent_id IS NOT NULL'
    add_index :categories, [:page_id, :name], unique: true, name: 'index_categories_on_page_id_and_name', where: 'parent_id IS NULL'
    add_index :categories, [:page_id, :parent_id, :slug], unique: true, name: 'index_categories_on_page_id_and_parent_id_and_slug', where: 'parent_id IS NOT NULL'
    add_index :categories, [:page_id, :slug], unique: true, name: 'index_categories_on_page_id_and_slug', where: 'parent_id IS NULL'

    create_table :links, force: :cascade do |t|
      t.string :title
      t.string :url
      t.string :link_type
      t.string :location
      t.integer :order
      t.string :domain
      t.references :page, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    # posts
    create_table :posts do |t|
      t.string :title
      t.text :content_html
      t.integer :status, default: 0, null: false
      t.string :slug
      t.jsonb :content_json
      t.text :seo_title
      t.text :seo_description
      t.text :og_title
      t.text :og_description
      t.datetime :archived_at
      t.datetime :first_published_at
      t.string :description
      t.references :page, null: false, foreign_key: { on_delete: :cascade }
      t.references :category, foreign_key: { to_table: :categories, on_delete: :nullify }

      t.timestamps
    end
    add_index :posts, [:page_id, :slug], unique: true

    create_table :post_authors do |t|
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.references :author, null: false, foreign_key: { on_delete: :cascade }
      t.integer :role, default: 0

      t.timestamps
    end

    create_table :post_revisions do |t|
      t.string :title
      t.text :content_html
      t.integer :kind, default: 0, null: false
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.jsonb :content_json
      t.text :seo_title
      t.text :seo_description
      t.text :og_title
      t.text :og_description
      t.string :share_id
      t.datetime :shared_at

      t.timestamps
    end
    add_index :post_revisions, :share_id, unique: true

    # subscribers
    create_table :subscribers do |t|
      t.string :email, null: false
      t.boolean :verified, default: false, null: false
      t.boolean :active, default: false, null: false
      t.string :verification_token
      t.string :status, null: false
      t.datetime :verified_at
      t.datetime :suppressed_at
      t.datetime :verification_email_sent_at
      t.string :suppression_reason
      t.string :note
      t.string :ip_address
      t.integer :deliver_count, default: 0
      t.integer :open_count, default: 0
      t.integer :click_count, default: 0
      t.integer :bounce_count, default: 0
      t.integer :spam_count, default: 0
      t.string :country
      t.string :city
      t.references :newsletter, foreign_key: { on_delete: :cascade }
      t.references :page, foreign_key: { on_delete: :nullify }

      t.timestamps
    end

    add_index :subscribers, :email
    add_index :subscribers, :ip_address
    add_index :subscribers, :verification_token, unique: true
  end
end
