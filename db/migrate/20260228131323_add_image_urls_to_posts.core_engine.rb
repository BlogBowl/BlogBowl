# This migration comes from core_engine (originally 20260227120000)
class AddImageUrlsToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :cover_image_url, :string
    add_column :posts, :og_image_url, :string
  end
end
