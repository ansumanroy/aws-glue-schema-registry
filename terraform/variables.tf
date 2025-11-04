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

variable "schemas" {
  description = "Map of schemas to create in the registry"
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
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "salesforce_audit_compatibility" {
  description = "Compatibility mode for SalesforceAudit schema"
  type        = string
  default     = "BACKWARD"
}
