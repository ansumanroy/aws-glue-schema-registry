variable "create_registry" {
  description = "Whether to create the Glue Schema Registry and schemas"
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWS region for Glue Schema Registry"
  type        = string
  default     = "us-east-1"
}

variable "registry_name" {
  description = "Name of the Glue Schema Registry"
  type        = string
}

variable "registry_description" {
  description = "Description of the Glue Schema Registry"
  type        = string
  default     = "Glue Schema Registry managed by Terraform"
}

variable "schemas_base_path" {
  description = "Base path for schema files directory (absolute path or relative to terraform directory)"
  type        = string
  default     = "../schemas"
}

variable "default_compatibility" {
  description = "Default compatibility mode for schemas without metadata files"
  type        = string
  default     = "BACKWARD"
}

variable "schemas" {
  description = "Map of manually defined schemas to create in the registry (takes precedence over file-based schemas)"
  type = map(object({
    description       = optional(string)
    data_format       = string # AVRO, JSON, PROTOBUF
    schema_definition = string
    compatibility     = optional(string, "BACKWARD") # BACKWARD, BACKWARD_ALL, DISABLED, FORWARD, FORWARD_ALL, FULL, FULL_ALL, NONE
    tags              = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Deprecated: kept for backward compatibility
variable "salesforce_audit_compatibility" {
  description = "Compatibility mode for SalesforceAudit schema (deprecated - use metadata files or default_compatibility)"
  type        = string
  default     = "BACKWARD"
}
