# Schema Files Directory

This directory contains schema files that will be automatically discovered and registered in AWS Glue Schema Registry.

**Location**: This directory is located at the project root level (outside the `terraform/` directory) to separate configuration data from infrastructure code, following Terraform best practices.

## Structure

```
schemas/
├── avro/          # Avro schema files (.avsc)
├── json/          # JSON Schema files (.json)
└── README.md      # This file
```

## Adding New Schemas

### Avro Schemas

1. Place your `.avsc` file in the `avro/` directory
2. The schema name will be derived from the filename (without extension)
   - Example: `salesforce-audit.avsc` → schema name: `salesforce-audit`
3. Run `terraform plan` to see the new schema
4. Apply with `terraform apply`

### JSON Schemas

1. Place your `.json` file in the `json/` directory
2. The schema name will be derived from the filename (without extension)
   - Example: `salesforce-event.json` → schema name: `salesforce-event`
3. Run `terraform plan` to see the new schema
4. Apply with `terraform apply`

## Custom Metadata (Optional)

You can optionally create a metadata file alongside your schema file to customize:
- Description
- Compatibility mode
- Tags

### Example: `salesforce-audit.metadata.json`

```json
{
  "description": "Salesforce audit event schema",
  "compatibility": "BACKWARD",
  "tags": {
    "Environment": "production",
    "Team": "data-engineering"
  }
}
```

If no metadata file exists, defaults will be used:
- **Description**: Auto-generated from schema name
- **Compatibility**: `BACKWARD` (or value from `default_compatibility` variable)
- **Tags**: Global tags from `terraform.tfvars`

## File Naming Conventions

- Use lowercase with hyphens: `my-schema-name.avsc`
- Avoid special characters except hyphens and underscores
- Schema names in Glue will be derived from filenames (hyphens converted to title case)

## Examples

### Avro Schema Example

File: `avro/user-profile.avsc`
```json
{
  "type": "record",
  "name": "UserProfile",
  "namespace": "com.example",
  "fields": [
    {"name": "userId", "type": "string"},
    {"name": "email", "type": "string"},
    {"name": "createdAt", "type": "long"}
  ]
}
```

### JSON Schema Example

File: `json/order-event.json`
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "orderId": {"type": "string"},
    "amount": {"type": "number"},
    "timestamp": {"type": "integer"}
  },
  "required": ["orderId", "amount", "timestamp"]
}
```

## Notes

- Schema files are automatically discovered by Terraform using `fileset()`
- Changes to schema files will trigger Terraform plan/apply
- Deleting a schema file will mark the schema for deletion in Terraform
- Schema names must be unique within the registry

