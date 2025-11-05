# Outputs from the Glue Schema Registry module
output "registry_name" {
  description = "Name of the Glue Schema Registry"
  value       = module.glue_schema_registry.registry_name
}

output "registry_arn" {
  description = "ARN of the Glue Schema Registry"
  value       = module.glue_schema_registry.registry_arn
}

output "registry_id" {
  description = "ID of the Glue Schema Registry"
  value       = module.glue_schema_registry.registry_id
}

output "schemas" {
  description = "Map of all created schemas with their information"
  value       = module.glue_schema_registry.schemas
}

output "schema_names" {
  description = "List of all schema names"
  value       = module.glue_schema_registry.schema_names
}
