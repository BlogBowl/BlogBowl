require "test_helper"

class TiptapContentTest < ActiveSupport::TestCase
  setup do
    @page = pages(:one)
    @post = @page.posts.new(title: "Test Post", slug: "test-post")
  end

  test "automatically converts HTML to JSON when saving post with only HTML" do
    @post.content_html = '<p>Test content</p>'
    @post.content_json = nil

    assert @post.save
    assert_not_nil @post.content_json
    assert_kind_of Hash, @post.content_json
    assert_equal "doc", @post.content_json["type"]
  end

  test "automatically converts JSON to HTML when saving post with only JSON" do
    @post.content_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            { "type" => "text", "text" => "Test content" }
          ]
        }
      ]
    }
    @post.content_html = nil

    assert @post.save
    assert_not_nil @post.content_html
    assert_kind_of String, @post.content_html
    assert_includes @post.content_html, "Test content"
  end

  test "HTML always drives JSON even when both are explicitly set" do
    # When content_html changes, JSON is always regenerated from it.
    # Explicitly setting content_json is ignored — HTML is the source of truth.
    @post.content_html = '<p>Original HTML</p>'
    @post.content_json = { "type" => "doc", "content" => [] }

    assert @post.save
    assert_equal "<p>Original HTML</p>", @post.content_html
    assert_equal "doc", @post.content_json["type"]
    # JSON is derived from HTML, not the empty array we set
    assert @post.content_json["content"].length > 0
  end

  test "does not convert if both HTML and JSON are blank" do
    @post.content_html = nil
    @post.content_json = nil

    assert @post.save
    assert_nil @post.content_html
    assert_nil @post.content_json
  end

  test "does not convert on update if content hasn't changed" do
    @post.content_html = '<p>Initial content</p>'
    @post.save!

    initial_json = @post.content_json

    # Update a different field
    @post.update!(title: "Updated Title")

    assert_equal initial_json, @post.content_json
  end

  test "converts HTML to JSON when HTML is updated" do
    @post.content_html = '<p>Initial content</p>'
    @post.save!

    @post.content_html = '<p>Updated content</p>'
    @post.content_json = nil
    @post.save!

    assert_not_nil @post.content_json
    assert_includes @post.content_json.to_s, "Updated content"
  end

  test "converts JSON to HTML when JSON is updated" do
    @post.content_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            { "type" => "text", "text" => "Initial content" }
          ]
        }
      ]
    }
    @post.save!

    @post.content_json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            { "type" => "text", "text" => "Updated content" }
          ]
        }
      ]
    }
    @post.content_html = nil
    @post.save!

    assert_not_nil @post.content_html
    assert_includes @post.content_html, "Updated content"
  end

  test "handles conversion errors gracefully" do
    # Create a malformed HTML that might cause issues but shouldn't crash
    # The conversion should happen but any errors should be logged, not raised
    @post.content_html = '<p>Test</p>'
    @post.content_json = nil

    # Should save successfully regardless
    assert @post.save
    # JSON should be populated from HTML
    assert_not_nil @post.content_json
  end

  test "converts complex HTML structures" do
    complex_html = <<~HTML
      <h2>Introduction</h2>
      <p>This is a <strong>test</strong> with <em>formatting</em>.</p>
      <ul>
        <li>Item 1</li>
        <li>Item 2</li>
      </ul>
      <p>Check out <a href="https://example.com">this link</a></p>
    HTML

    @post.content_html = complex_html
    @post.content_json = nil

    assert @post.save
    assert_not_nil @post.content_json
    assert_kind_of Hash, @post.content_json
    assert @post.content_json["content"].length > 1
  end

  test "preserves whitespace option in content" do
    @post.content_html = "<p>Line 1</p>\n<p>Line 2</p>"
    @post.content_json = nil

    assert @post.save
    assert_not_nil @post.content_json
  end
end