require "test_helper"

class TiptapConverterTest < ActiveSupport::TestCase
  test "html_to_json converts simple HTML to TipTap JSON" do
    html = '<p>Hello World</p>'
    result = TiptapConverter.html_to_json(html)

    assert_kind_of Hash, result
    assert_equal "doc", result["type"]
    assert_kind_of Array, result["content"]
    assert_equal "paragraph", result["content"].first["type"]
    assert_equal "Hello World", result["content"].first["content"].first["text"]
  end

  test "html_to_json converts complex HTML with multiple elements" do
    html = '<h2>Title</h2><p>Paragraph</p><ul><li>Item 1</li><li>Item 2</li></ul>'
    result = TiptapConverter.html_to_json(html)

    assert_equal "doc", result["type"]
    assert_equal 3, result["content"].length
    assert_equal "heading", result["content"][0]["type"]
    assert_equal "paragraph", result["content"][1]["type"]
    assert_equal "bulletList", result["content"][2]["type"]
  end

  test "html_to_json handles empty string" do
    html = ''
    result = TiptapConverter.html_to_json(html)

    assert_kind_of Hash, result
    assert_equal "doc", result["type"]
  end

  test "json_to_html converts TipTap JSON to HTML" do
    json = {
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

    result = TiptapConverter.json_to_html(json)

    assert_kind_of String, result
    assert_includes result, "Test content"
    assert_includes result, "<p"
  end

  test "json_to_html accepts JSON string input" do
    json_string = '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Test"}]}]}'
    result = TiptapConverter.json_to_html(json_string)

    assert_kind_of String, result
    assert_includes result, "Test"
  end

  test "json_to_html handles complex TipTap structures" do
    json = {
      "type" => "doc",
      "content" => [
        {
          "type" => "heading",
          "attrs" => { "level" => 2 },
          "content" => [{ "type" => "text", "text" => "Heading" }]
        },
        {
          "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "Paragraph" }]
        }
      ]
    }

    result = TiptapConverter.json_to_html(json)

    assert_includes result, "<h2"
    assert_includes result, "Heading"
    assert_includes result, "<p"
    assert_includes result, "Paragraph"
  end

  test "handles nil HTML gracefully" do
    # TipTap treats nil as empty string
    result = TiptapConverter.html_to_json(nil)
    assert_kind_of Hash, result
    assert_equal "doc", result["type"]
  end

  test "raises ConversionError on invalid JSON" do
    assert_raises(TiptapConverter::ConversionError) do
      TiptapConverter.json_to_html("invalid json")
    end
  end

  test "round-trip conversion preserves content" do
    original_html = '<h2>Title</h2><p>This is a <strong>test</strong> paragraph.</p>'
    json = TiptapConverter.html_to_json(original_html)
    html = TiptapConverter.json_to_html(json)

    # Convert back to JSON to verify content preservation
    json_again = TiptapConverter.html_to_json(html)

    assert_equal json["type"], json_again["type"]
    assert_equal json["content"].length, json_again["content"].length
  end

  test "handles special characters in HTML" do
    html = '<p>Test &amp; special chars: &lt;code&gt;</p>'
    result = TiptapConverter.html_to_json(html)

    assert_equal "doc", result["type"]
    assert_kind_of Array, result["content"]
  end

  test "handles links in HTML" do
    html = '<p>Check out <a href="https://example.com">this link</a></p>'
    result = TiptapConverter.html_to_json(html)

    assert_equal "doc", result["type"]
    assert_kind_of Array, result["content"]
  end

  test "conversion uses correct TIPTAP_PATH" do
    # Verify the path is set correctly
    assert TiptapConverter::TIPTAP_PATH.present?
    assert Dir.exist?(TiptapConverter::TIPTAP_PATH), "TipTap parser directory not found at #{TiptapConverter::TIPTAP_PATH}"
  end
end
