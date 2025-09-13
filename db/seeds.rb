# FOR OSS

ActiveRecord::Base.transaction do
  puts "Creating default user..."
  User.create!(email: "admin@example.com", password: "changeme")
  puts "Default user admin@example.com was created"
end
