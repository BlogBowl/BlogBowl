require "active_support/core_ext/integer/time"
all_mailer_configs = Rails.application.config_for(:mailers)


Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  config.public_file_server.enabled = true

  # Do not fall back to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  config.assets.gzip = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).

  s3_enabled = ENV.fetch('S3_ACCESS_KEY_ID', Rails.application.credentials.dig(Rails.env.to_sym, :s3, :access_key_id)).present?
  if s3_enabled
    config.active_storage.service = :s3
  else
    config.active_storage.service = :local
  end

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = false

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true
  config.ssl_options = { redirect: { exclude: -> request {
    request.path == "/api/internal/domain/verify" ||
      request.path == "/api/internal/analytics/user" } } }

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  config.active_job.queue_adapter = :sidekiq

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  fronted_url = ENV.fetch('FRONTEND_URL', Rails.application.credentials.dig(Rails.env.to_sym, :frontend_url))
  config.action_mailer.default_url_options = { host: fronted_url }

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via rails credentials:edit.
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [:id]

  config.hosts = nil
  Rails.application.routes.default_url_options = { host: "#{URI.parse(fronted_url).host}" }
  config.action_controller.asset_host = fronted_url

  smtp_enabled = ENV.fetch('SMTP_MAIL_ADDRESS', Rails.application.credentials.dig(Rails.env.to_sym, :smtp_mail, :address)).present?
  if smtp_enabled
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = all_mailer_configs[:smtp][:smtp_settings]
  else
    config.action_mailer.delivery_method = :test
  end
end
