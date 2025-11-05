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
  description = "Base path for schema files directory (relative to module or absolute path)"
  type        = string
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

