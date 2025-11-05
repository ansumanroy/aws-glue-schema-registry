# Outputs from the Glue Schema Registry module
# All outputs return null if create_registry is false
output "registry_name" {
  description = "Name of the Glue Schema Registry"
  value       = var.create_registry ? module.glue_schema_registry[0].registry_name : null
}

output "registry_arn" {
  description = "ARN of the Glue Schema Registry"
  value       = var.create_registry ? module.glue_schema_registry[0].registry_arn : null
}

output "registry_id" {
  description = "ID of the Glue Schema Registry"
  value       = var.create_registry ? module.glue_schema_registry[0].registry_id : null
}

output "schemas" {
  description = "Map of all created schemas with their information"
  value       = var.create_registry ? module.glue_schema_registry[0].schemas : {}
}

output "schema_names" {
  description = "List of all schema names"
  value       = var.create_registry ? module.glue_schema_registry[0].schema_names : []
}
