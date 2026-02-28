require "test_helper"

class PostRevisionTest < ActiveSupport::TestCase

  def create_post_revision(post, inserted_text = 'updated')
    post_revision = post.new_revision
    post_revision.title = "#{post.title} #{inserted_text}"
    post_revision.content_html = "#{post.content_html} #{inserted_text}"
    post_revision.content_json = {}
    post_revision.seo_title = "#{post.seo_title} #{inserted_text}"
    post_revision.seo_description = "#{post.seo_description} #{inserted_text}"
    post_revision.og_title = "#{post.og_title} #{inserted_text}"
    post_revision.og_description = "#{post.og_description} #{inserted_text}"
    post_revision
  end

  test "should save post revision" do
    post = pages(:one).posts.new(title: "This is a test title", content_html: "This is a test content")
    revision = post.new_revision
    assert revision.save, revision.errors.full_messages
  end

  test "should apply post revision" do
    post = pages(:one).posts.new(title: "This is a test title", content_html: "This is a test content")

    revision = create_post_revision(post)
    revision.save

    revision.apply!

    post_attributes = post.attributes.symbolize_keys.except(:id, :page_id, :category_id, :status, :slug, :archived_at, :created_at, :updated_at, :first_published_at, :description, :scheduled_at, :job_id, :content_json)
    revision_attributes = revision.attributes.symbolize_keys.except(:id, :post_id, :kind, :created_at, :updated_at, :share_id, :shared_at, :first_published_at, :description, :content_json)
    assert_equal post_attributes, revision_attributes
  end

  test "should return true when comparing identical post revision" do
    post = pages(:one).posts.new(title: "This is a test title", content_html: "This is a test content")

    revision = create_post_revision(post)
    revision2 = create_post_revision(post)

    revision.save
    revision2.save

    assert revision.equals?(revision2)
  end

  test "should return false when comparing different post revision" do
    post = pages(:one).posts.new(title: "This is a test title", content_html: "This is a test content")

    revision = create_post_revision(post)
    revision.save

    revision2 = create_post_revision(post, 'different')
    revision2.save

    assert_not revision.equals?(revision2)
  end
end
