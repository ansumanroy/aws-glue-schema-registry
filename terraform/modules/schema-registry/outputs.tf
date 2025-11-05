output "registry_name" {
  description = "Name of the Glue Schema Registry"
  value       = aws_glue_registry.schema_registry.registry_name
}

output "registry_arn" {
  description = "ARN of the Glue Schema Registry"
  value       = aws_glue_registry.schema_registry.arn
}

output "registry_id" {
  description = "ID of the Glue Schema Registry"
  value       = aws_glue_registry.schema_registry.id
}

output "schemas" {
  description = "Map of all created schemas with their information"
  value = {
    for k, v in aws_glue_schema.schemas :
    k => {
      schema_name = v.schema_name
      schema_arn  = v.arn
      version_id  = v.latest_schema_version
      data_format = v.data_format
    }
  }
}

output "schema_names" {
  description = "List of all schema names"
  value       = [for k, v in aws_glue_schema.schemas : v.schema_name]
}

