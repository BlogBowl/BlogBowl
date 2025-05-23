cookie_domain = ['', 'analytics.'].map do |subdomain|
  subdomain + Rails.application.routes.default_url_options[:host]
end

Rails.application.config.session_store :cookie_store,
                                       key: '_blogbowl_session',
                                       domain: cookie_domain
