# This migration comes from core_engine (originally 20250523120947)
class Init < ActiveRecord::Migration[8.0]
  def change
    create_table :workspaces do |t|
      t.string :title, null: false
      t.string :uuid

      t.timestamps
    end
    add_index :workspaces, :uuid, unique: true

    create_table :members do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :workspace, null: false, foreign_key: { on_delete: :cascade }
      t.string :permissions, array: true, default: []

      t.timestamps
    end

    # Authors & their links
    create_table :authors do |t|
      t.string :first_name
      t.string :last_name
      t.string :email, null: false
      t.string :position
      t.text :short_description
      t.text :long_description
      t.boolean :active, default: true
      t.references :member, null: false, foreign_key: { on_delete: :cascade }
      t.string :slug

      t.timestamps
    end

    create_table :author_links do |t|
      t.string :title
      t.string :url
      t.decimal :order
      t.references :author, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    # Pages, categories, posts
    create_table :pages do |t|
      t.references :workspace, null: false, foreign_key: { on_delete: :cascade }
      t.string :slug, null: false
      t.string :name
      t.string :domain
      t.string :name_slug

      t.timestamps
    end
    add_index :pages, :domain, unique: true
    add_index :pages, [:workspace_id, :name_slug], unique: true

    create_table :categories do |t|
      t.references :page, null: false, foreign_key: { on_delete: :cascade }
      t.string :name
      t.text :description
      t.integer :parent_id
      t.string :slug
      t.string :color
      t.string :image_url

      t.timestamps
    end
    add_index :categories, [:page_id, :parent_id, :name], unique: true, name: 'index_categories_on_page_id_and_parent_id_and_name', where: 'parent_id IS NOT NULL'
    add_index :categories, [:page_id, :name], unique: true, name: 'index_categories_on_page_id_and_name', where: 'parent_id IS NULL'
    add_index :categories, [:page_id, :parent_id, :slug], unique: true, name: 'index_categories_on_page_id_and_parent_id_and_slug', where: 'parent_id IS NOT NULL'
    add_index :categories, [:page_id, :slug], unique: true, name: 'index_categories_on_page_id_and_slug', where: 'parent_id IS NULL'

    create_table :posts do |t|
      t.references :page, null: false, foreign_key: { on_delete: :cascade }
      t.references :category, foreign_key: { to_table: :categories, on_delete: :nullify }
      t.string :title
      t.text :content_html
      t.jsonb :content_json
      t.text :seo_title
      t.text :seo_description
      t.text :og_title
      t.text :og_description
      t.string :slug
      t.string :description
      t.integer :status, null: false, default: 0
      t.datetime :archived_at
      t.datetime :first_published_at

      t.timestamps
    end
    add_index :posts, [:page_id, :slug], unique: true

    # Post revisions & authorship
    create_table :post_revisions do |t|
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.string :title
      t.text :content_html
      t.jsonb :content_json
      t.integer :kind, null: false, default: 0
      t.text :seo_title
      t.text :seo_description
      t.text :og_title
      t.text :og_description
      t.string :share_id
      t.datetime :shared_at

      t.timestamps
    end
    add_index :post_revisions, :share_id, unique: true

    create_table :post_authors do |t|
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.references :author, null: false, foreign_key: { on_delete: :cascade }
      t.integer :role, default: 0

      t.timestamps
    end

    # Links (general)
    create_table :links do |t|
      t.string :title
      t.string :url
      t.string :link_type
      t.string :location
      t.integer :order
      t.string :domain
      t.references :page, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    # Page settings & workspace settings
    create_table :page_settings do |t|
      t.references :page, null: false, foreign_key: { on_delete: :cascade }
      t.text :seo_title
      t.text :seo_description
      t.text :title
      t.text :description
      t.text :head_html
      t.text :body_html
      t.string :template, null: false, default: "default"
      t.string :cta_title
      t.text :cta_description
      t.string :cta_button
      t.string :cta_button_link
      t.boolean :subfolder_enabled, null: false, default: false
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

      t.timestamps
    end

    create_table :workspace_settings do |t|
      t.references :workspace, null: false, foreign_key: { on_delete: :cascade }
      t.string :html_lang
      t.string :locale
      t.string :title
      t.boolean :with_watermark, default: true, null: false

      t.timestamps
    end
  end
end
