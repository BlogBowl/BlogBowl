class Rack::Attack
  # Rate limit for API v1
  throttle('api/v1/ip', limit: 1000, period: 1.minute) do |req|
    if req.path.start_with?('/api/v1')
      req.ip
    end
  end
end
