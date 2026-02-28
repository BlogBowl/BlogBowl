require "json"

namespace :openapi do
  desc "Generate OpenAPI spec with clean metadata, capitalized tags, and correct content types"
  task generate: :environment do
    Rake::Task["apipie:static_swagger_json"].invoke

    spec_path = Rails.root.join("doc", "apidoc", "schema_swagger_json.json")
    spec = JSON.parse(File.read(spec_path))

    # Clean up info block
    spec["info"]["title"]       = "BlogBowl API"
    spec["info"]["description"] = "REST API for managing blog pages, posts, authors, newsletters, and subscribers."
    spec["info"]["version"]     = "1.0.0"

    spec["paths"].each do |path, methods|
      methods.each do |_method, operation|
        next unless operation.is_a?(Hash)

        # Capitalize tags
        operation["tags"] = operation["tags"].map(&:capitalize) if operation["tags"]

        # Fix file upload endpoints: switch from JSON body to multipart/form-data
        next unless file_upload_operation?(operation)

        operation["consumes"] = ["multipart/form-data"]
        file_params = extract_file_params(operation)
        operation["parameters"] = file_params
      end
    end

    # Populate top-level tags array so clients (e.g. Swagger UI) can group endpoints
    all_tags = spec["paths"].flat_map do |_path, methods|
      methods.flat_map { |_method, op| op.is_a?(Hash) ? (op["tags"] || []) : [] }
    end.uniq.sort

    spec["tags"] = all_tags.map { |tag| { "name" => tag } }

    File.write(spec_path, JSON.pretty_generate(spec))
    puts "OpenAPI spec written to #{spec_path}"
  end

  private

  def file_upload_operation?(operation)
    body_param = operation["parameters"]&.find { |p| p["in"] == "body" }
    return false unless body_param

    properties = body_param.dig("schema", "properties") || {}
    properties.any? { |_, prop| prop["type"] == "file" }
  end

  def extract_file_params(operation)
    body_param   = operation["parameters"].find { |p| p["in"] == "body" }
    other_params = operation["parameters"].reject { |p| p["in"] == "body" }

    properties = body_param.dig("schema", "properties") || {}
    required   = body_param.dig("schema", "required") || []

    form_params = properties.map do |name, prop|
      {
        "name"        => name,
        "in"          => "formData",
        "type"        => prop["type"],
        "required"    => required.include?(name),
        "description" => prop["description"] || ""
      }
    end

    other_params + form_params
  end
end
