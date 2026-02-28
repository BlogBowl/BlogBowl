Apipie.configure do |config|
  config.app_name                = "BlogBowl API"
  config.api_base_url            = "/api/v1"
  config.doc_base_url            = "/apidoc"
  config.app_info                = "REST API for managing blog pages, posts, authors, newsletters, and subscribers."
  config.api_controllers_matcher = ["#{Rails.root}/submodules/core/app/controllers/api/v1/**/*.rb"]
  config.validate                = false
  config.generator.swagger.content_type_input = :json
end
