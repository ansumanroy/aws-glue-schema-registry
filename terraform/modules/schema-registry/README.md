# Glue Schema Registry Terraform Module

This module creates an AWS Glue Schema Registry and automatically discovers and registers schemas from a directory structure.

## Features

- **Automatic Schema Discovery**: Discovers Avro (`.avsc`) and JSON (`.json`) schema files from configured directories
- **Metadata Support**: Optional metadata files for custom descriptions, compatibility modes, and tags
- **Manual Override**: Supports manually defined schemas via variables
- **File-Based Management**: Easy to add new schemas by simply adding files to directories

## Usage

```hcl
module "glue_schema_registry" {
  source = "./modules/schema-registry"

  registry_name        = "my-schema-registry"
  registry_description = "My application schemas"
  schemas_base_path    = "../schemas"  # Path to schemas directory (relative or absolute)
  default_compatibility = "BACKWARD"

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

## Requirements

- Terraform >= 1.0
- AWS Provider >= 5.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| registry_name | Name of the Glue Schema Registry | `string` | n/a | yes |
| registry_description | Description of the Glue Schema Registry | `string` | `"Glue Schema Registry managed by Terraform"` | no |
| schemas_base_path | Base path for schema files directory | `string` | n/a | yes |
| default_compatibility | Default compatibility mode for schemas without metadata files | `string` | `"BACKWARD"` | no |
| schemas | Map of manually defined schemas (takes precedence over file-based) | `map(object)` | `{}` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| registry_name | Name of the Glue Schema Registry |
| registry_arn | ARN of the Glue Schema Registry |
| registry_id | ID of the Glue Schema Registry |
| schemas | Map of all created schemas with their information |
| schema_names | List of all schema names |

## Schema File Structure

The module expects schema files in the following structure:

```
schemas/
├── avro/              # Avro schema files (.avsc)
│   ├── schema1.avsc
│   ├── schema1.metadata.json  # Optional metadata
│   └── schema2.avsc
└── json/              # JSON Schema files (.json)
    ├── schema1.json
    ├── schema1.metadata.json  # Optional metadata
    └── schema2.json
```

### Schema Discovery

- **Avro Schemas**: All `.avsc` files in `schemas/avro/` directory
- **JSON Schemas**: All `.json` files in `schemas/json/` directory (excluding `.metadata.json` files)
- **Schema Names**: Derived from filenames (without extension)
  - Example: `salesforce-audit.avsc` → schema name: `salesforce-audit`

### Metadata Files (Optional)

Create a `.metadata.json` file alongside your schema file to customize:

- **Description**: Custom description for the schema
- **Compatibility**: Compatibility mode (BACKWARD, FORWARD, FULL, etc.)
- **Tags**: Additional tags specific to the schema

Example: `schemas/avro/my-schema.metadata.json`
```json
{
  "description": "Custom schema description",
  "compatibility": "FORWARD",
  "tags": {
    "Environment": "production",
    "Team": "data-engineering"
  }
}
```

## Examples

### Basic Usage

```hcl
module "glue_schema_registry" {
  source = "./modules/schema-registry"

  registry_name     = "my-registry"
  schemas_base_path = "../schemas"  # Relative to terraform directory
}
```

### With Custom Compatibility

```hcl
module "glue_schema_registry" {
  source = "./modules/schema-registry"

  registry_name        = "my-registry"
  schemas_base_path    = "../schemas"
  default_compatibility = "FULL"
}
```

### With Manual Schema Override

```hcl
module "glue_schema_registry" {
  source = "./modules/schema-registry"

  registry_name     = "my-registry"
  schemas_base_path = "../schemas"

  schemas = {
    "manual-schema" = {
      description       = "Manually defined schema"
      data_format       = "AVRO"
      schema_definition = file("../schemas/custom-schema.avsc")
      compatibility     = "BACKWARD"
    }
  }
}
```

## Notes

- File-based schemas are automatically discovered on each `terraform plan`/`apply`
- Manually defined schemas in `var.schemas` take precedence over file-based schemas with the same name
- Deleting a schema file will mark the schema for deletion in Terraform
- Schema names must be unique within the registry

