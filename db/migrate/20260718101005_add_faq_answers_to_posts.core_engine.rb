# This migration comes from core_engine (originally 20260425000000)
class AddFaqAnswersToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :faq_answers, :jsonb, default: []
  end
end
