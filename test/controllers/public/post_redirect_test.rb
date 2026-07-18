require "test_helper"

class Public::PostRedirectTest < ActionDispatch::IntegrationTest
  setup do
    @page = pages(:blog_with_domain_1)
    host! @page.domain

    @author = Author.create!(
      member: members(:six),
      first_name: "Ann",
      last_name: "Author",
      email: "ann@example.com"
    )
    @source = publish_post("Source post")
    @target = publish_post("Target post")
  end

  test "a post without a redirect renders normally" do
    get public_post_path(id: @source.slug)
    assert_response :success
  end

  test "redirects permanently to the target post" do
    @source.update!(redirect_post: @target)

    get public_post_path(id: @source.slug)
    assert_response :moved_permanently
    assert_redirected_to "/#{@target.slug}"
  end

  test "redirects permanently to a custom url" do
    @source.update!(redirect_url: "https://example.com/elsewhere")

    get public_post_path(id: @source.slug)
    assert_response :moved_permanently
    assert_redirected_to "https://example.com/elsewhere"
  end

  test "renders the post when its redirect target has been archived" do
    @source.update!(redirect_post: @target)
    @target.update_column(:archived_at, Time.current)

    get public_post_path(id: @source.slug)
    assert_response :success
  end

  test "a redirected post is dropped from the sitemap" do
    @source.update!(redirect_post: @target)

    get public_sitemap_path(format: :xml)
    assert_response :success
    assert_not_includes @response.body, "/#{@source.slug}<"
    assert_includes @response.body, "/#{@target.slug}<"
  end

  test "a redirected post is dropped from the home listing" do
    @source.update!(redirect_url: "https://example.com")

    get public_root_path
    assert_response :success
    assert_not_includes @response.body, @source.title
    assert_includes @response.body, @target.title
  end

  private

  def publish_post(title)
    post = @page.posts.create!(title: title, content_html: "<p>#{title}</p>")
    PostAuthor.create!(post: post, author: @author, role: "author")
    post.update!(status: :published, first_published_at: Time.current)
    post.reload
  end
end
