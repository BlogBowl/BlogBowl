# This migration comes from core_engine (originally 20260118120000)
class AddIndexToPostsFirstPublishedAt < ActiveRecord::Migration[8.0]
  def change
    add_index :posts, [ :page_id, :first_published_at ]
  end
end
