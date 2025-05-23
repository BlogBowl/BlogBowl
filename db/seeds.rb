# FOR OSS

ActiveRecord::Base.transaction do
  user = User.create!(email: "admin@example.com", password: "changeme")

  workspace = Workspace.new(title: "My Workspace")
  user.members.create!(workspace:, permissions: ["owner"])
  author = user.members.first.create_or_activate_author!

  first_page = workspace.pages.first
  unless first_page.nil?
    first_page.create_default_first_post(author.id)
  end

end
