output "registry_name" {
  description = "Name of the Glue Schema Registry"
  value       = aws_glue_registry.schema_registry.registry_name
}

output "registry_arn" {
  description = "ARN of the Glue Schema Registry"
  value       = aws_glue_registry.schema_registry.arn
}

output "schemas" {
  description = "Map of created schemas with their ARNs"
  value = {
    for k, v in aws_glue_schema.schema : k => {
      schema_name = v.schema_name
      schema_arn  = v.arn
      version_id  = v.latest_schema_version
    }
  }
}

output "salesforce_audit_schema" {
  description = "SalesforceAudit schema information"
  value = {
    schema_name = aws_glue_schema.salesforce_audit.schema_name
    schema_arn  = aws_glue_schema.salesforce_audit.arn
    version_id  = aws_glue_schema.salesforce_audit.latest_schema_version
  }
}
