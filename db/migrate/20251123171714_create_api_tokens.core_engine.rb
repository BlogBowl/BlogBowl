# This migration comes from core_engine (originally 20251123000000)
class CreateAPITokens < ActiveRecord::Migration[8.0]
  def change
    create_table :api_tokens do |t|
      t.references :workspace, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :name
      t.string :token, null: false
      t.datetime :last_used_at
      t.datetime :expires_at

      t.timestamps
    end
    add_index :api_tokens, :token, unique: true
  end
end
