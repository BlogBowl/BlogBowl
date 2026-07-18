require "test_helper"

class PostRedirectTest < ActiveSupport::TestCase
  setup do
    @page = pages(:one)
    @source = create_post("Source")
    @target = create_post("Target")
  end

  test "post without a redirect is not redirected" do
    assert_not @source.redirected?
    assert_nil @source.redirect_destination
  end

  test "redirects to another post by path" do
    @source.update!(redirect_post: @target)

    assert @source.redirected?
    assert_equal "/#{@target.slug}", @source.redirect_destination
  end

  test "honours the path prefix of a subfolder page" do
    @source.update!(redirect_post: @target)

    assert_equal "/blog/#{@target.slug}", @source.redirect_destination(path_prefix: "/blog")
  end

  test "redirects to a custom url" do
    @source.update!(redirect_url: "https://example.com/elsewhere")

    assert @source.redirected?
    assert_equal "https://example.com/elsewhere", @source.redirect_destination
  end

  test "collapses a post to post chain into a single hop" do
    final = create_post("Final")
    @target.update!(redirect_post: final)
    @source.update!(redirect_post: @target)

    assert_equal "/#{final.slug}", @source.redirect_destination
  end

  test "a redirect cycle resolves to nil rather than pointing at itself" do
    @source.update!(redirect_post: @target)
    @target.update_column(:redirect_post_id, @source.id)

    assert_nil @source.redirect_destination
  end

  test "resolves to nil when the target has been archived" do
    @source.update!(redirect_post: @target)
    @target.update_column(:archived_at, Time.current)

    assert_nil @source.reload.redirect_destination
  end

  test "the post stays editable after its redirect target is archived" do
    @source.update!(redirect_post: @target)
    @target.update_column(:archived_at, Time.current)

    assert @source.reload.update(title: "Renamed"), @source.errors.full_messages.to_sentence
  end

  test "rejects redirecting to itself" do
    @source.redirect_post_id = @source.id

    assert_not @source.valid?
    assert_includes @source.errors[:redirect_post], "cannot be the post itself"
  end

  test "rejects a target on another page" do
    other = pages(:two).posts.create!(title: "Elsewhere", content_html: "x")
    @source.redirect_post = other

    assert_not @source.valid?
    assert_includes @source.errors[:redirect_post], "must belong to the same page"
  end

  test "rejects setting both a post and a url" do
    @source.redirect_post = @target
    @source.redirect_url = "https://example.com"

    assert_not @source.valid?
    assert_includes @source.errors[:base], "Redirect to a post or to a URL, not both"
  end

  test "rejects a malformed redirect url" do
    @source.redirect_url = "not a url"

    assert_not @source.valid?
    assert_predicate @source.errors[:redirect_url], :any?
  end

  test "accepts a relative path as a redirect url" do
    @source.redirect_url = "/some-other-post"

    assert @source.valid?, @source.errors.full_messages.to_sentence
  end

  test "blank redirect url is stored as nil so not_redirected matches" do
    @source.update!(redirect_url: "")

    assert_nil @source.redirect_url
    assert_not @source.redirected?
    assert_includes Post.not_redirected, @source
  end

  test "not_redirected excludes both kinds of redirect" do
    @source.update!(redirect_post: @target)
    url_redirected = create_post("Url redirected")
    url_redirected.update!(redirect_url: "https://example.com")

    scope = @page.posts.not_redirected
    assert_not_includes scope, @source
    assert_not_includes scope, url_redirected
    assert_includes scope, @target
  end

  test "as_json exposes the redirect target without recursing" do
    @source.update!(redirect_post: @target)
    @target.update_column(:redirect_post_id, @source.id)

    # as_json merges symbol keys onto the string-keyed attribute hash, matching
    # how cover_image/authors are already exposed.
    json = @source.as_json
    assert_equal @target.id, json[:redirect_post]["id"]
    assert_equal @target.slug, json[:redirect_post]["slug"]
  end

  private

  def create_post(title)
    @page.posts.create!(title: title, content_html: "<p>#{title}</p>")
  end
end
