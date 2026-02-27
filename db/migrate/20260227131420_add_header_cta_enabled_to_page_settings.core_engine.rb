# This migration comes from core_engine (originally 20260118120500)
class AddHeaderCtaEnabledToPageSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :page_settings, :header_cta_enabled, :boolean, default: true
  end
end
