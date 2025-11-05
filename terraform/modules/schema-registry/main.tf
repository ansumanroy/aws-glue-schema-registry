# Glue Schema Registry Module
# This module creates a Glue Schema Registry and automatically discovers and registers schemas
# from the specified schemas directory.

# Glue Schema Registry
resource "aws_glue_registry" "schema_registry" {
  registry_name = var.registry_name
  description   = var.registry_description
  tags          = var.tags
}

# Discover schema files from schemas directory
locals {
  # Discover Avro schema files (returns empty set if directory doesn't exist)
  avro_schema_files = try(fileset("${var.schemas_base_path}/avro", "*.avsc"), toset([]))

  # Discover JSON schema files (returns empty set if directory doesn't exist)
  # Exclude metadata.json files from discovery
  json_schema_files = try([for f in fileset("${var.schemas_base_path}/json", "*.json") : f if !endswith(f, ".metadata.json")], toset([]))

  # Create a map of Avro schemas: filename (without extension) -> full path
  avro_schemas = {
    for file in local.avro_schema_files :
    replace(basename(file), ".avsc", "") => {
      file_path     = "${var.schemas_base_path}/avro/${file}"
      data_format   = "AVRO"
      metadata_file = "${var.schemas_base_path}/avro/${replace(basename(file), ".avsc", "")}.metadata.json"
    }
  }

  # Create a map of JSON schemas: filename (without extension) -> full path
  json_schemas = {
    for file in local.json_schema_files :
    replace(basename(file), ".json", "") => {
      file_path     = "${var.schemas_base_path}/json/${file}"
      data_format   = "JSON"
      metadata_file = "${var.schemas_base_path}/json/${replace(basename(file), ".json", "")}.metadata.json"
    }
  }

  # Merge both schema types
  file_based_schemas = merge(local.avro_schemas, local.json_schemas)

  # Helper function to read metadata file if it exists, otherwise return null
  read_metadata = {
    for name, schema in local.file_based_schemas :
    name => fileexists(schema.metadata_file) ? jsondecode(file(schema.metadata_file)) : null
  }

  # Build final schema configuration with metadata or defaults
  schemas_from_files = {
    for name, schema in local.file_based_schemas :
    name => {
      schema_definition = file(schema.file_path)
      data_format       = schema.data_format
      description = try(
        local.read_metadata[name].description,
        "${replace(name, "-", " ")} schema" # Auto-generate from name: "salesforce-audit" -> "salesforce audit schema"
      )
      compatibility = try(
        local.read_metadata[name].compatibility,
        var.default_compatibility
      )
      tags = try(
        merge(var.tags, local.read_metadata[name].tags),
        var.tags
      )
    }
  }

  # Merge file-based schemas with manually defined schemas (var.schemas takes precedence)
  all_schemas = merge(local.schemas_from_files, var.schemas)
}

# Glue Schemas from file-based discovery and var.schemas
resource "aws_glue_schema" "schemas" {
  for_each = local.all_schemas

  registry_arn      = aws_glue_registry.schema_registry.arn
  schema_name       = each.key
  description       = each.value.description
  data_format       = each.value.data_format
  schema_definition = each.value.schema_definition

  compatibility = lookup(each.value, "compatibility", var.default_compatibility)
  tags          = merge(var.tags, lookup(each.value, "tags", {}))
}

