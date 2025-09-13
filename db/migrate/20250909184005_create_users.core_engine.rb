# This migration comes from core_engine (originally 20250523084615)
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name
      t.string :last_name
      t.jsonb "dismissed_notices", default: {}

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
