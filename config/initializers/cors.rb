# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  if Rails.env.development?
    allow do
      # assets in prod are server by caddy, so allow only in dev
      origins '*'
      resource '/assets/*', headers: :any, methods: [:get]
    end

    allow do
      origins 'http://editor.blogbowl.test'
      resource '/api/internal/*', headers: :any, methods: [:get, :post, :put, :delete, :patch], credentials: true
    end

    allow do
      origins 'https://analytics.blogbowl.test'
      resource '/api/internal/*', headers: :any, methods: [:get, :post, :put, :delete, :patch], credentials: true
    end
  end

  allow do
    origins 'https://analytics.blogbowl.io'
    resource '/api/internal/*', headers: :any, methods: [:get, :post, :put, :delete, :patch], credentials: true
  end
end
