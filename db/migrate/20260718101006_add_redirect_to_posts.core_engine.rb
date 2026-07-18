# This migration comes from core_engine (originally 20260718000000)
class AddRedirectToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :redirect_url, :string
    # Nullify rather than restrict: deleting the target should drop the
    # redirect, not block the delete.
    add_reference :posts, :redirect_post, null: true,
                  foreign_key: { to_table: :posts, on_delete: :nullify }
  end
end
