# Terraform Infrastructure as Code for Glue Schema Registry

This directory contains Terraform configuration to deploy and manage schemas in AWS Glue Schema Registry.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- AWS provider access to create Glue resources
- Access to S3 bucket: `aws-glue-assets-651914028873-us-east-1` (for Terraform state storage)

## Usage

### Quick Start - File-Based Schema Management (Recommended)

1. **Add Schema Files**: Place your schema files in the appropriate directories:
   - `schemas/avro/*.avsc` for Avro schemas
   - `schemas/json/*.json` for JSON schemas

2. **Customize `terraform.tfvars`** with your registry configuration:

```hcl
aws_region         = "us-east-1"
registry_name      = "my-schema-registry"
registry_description = "My application schemas"
default_compatibility = "BACKWARD"
```

3. **Optional**: Add metadata files for custom descriptions, compatibility, or tags:
   - `schemas/avro/my-schema.metadata.json`
   - `schemas/json/my-schema.metadata.json`

See `schemas/README.md` for detailed instructions on adding schemas.

### Manual Schema Definition (Advanced)

You can still define schemas manually in `terraform.tfvars`:

```hcl
schemas = {
  "user-schema" = {
    description       = "User schema definition"
    data_format       = "AVRO"
    schema_definition = file("schemas/user.avsc")
    compatibility     = "BACKWARD"
  }
}
```

Note: File-based schemas are automatically discovered, and manually defined schemas take precedence if there's a name conflict.

2. Initialize Terraform (with S3 backend):

The configuration uses an S3 backend for storing Terraform state. The backend is configured in `main.tf`:

```hcl
backend "s3" {
  bucket         = "aws-glue-assets-651914028873-us-east-1"
  key            = "terraform/glue-schema-registry/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
}
```

Initialize Terraform:

```bash
# Using Makefile (recommended)
make terraform-init

# Or manually
terraform init
```

3. Review the plan:

```bash
terraform plan
```

4. Apply the configuration:

```bash
terraform apply
```

## Structure

- `main.tf` - Main Terraform configuration for Glue Schema Registry and schemas (includes S3 backend configuration)
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `terraform.tfvars.example` - Example variables file
- `backend.hcl.example` - Example backend configuration (alternative approach)

## S3 Backend Configuration

The Terraform state is stored in S3 bucket `aws-glue-assets-651914028873-us-east-1` for:
- **State Management**: Centralized state storage
- **Team Collaboration**: Multiple team members can work with the same state
- **State Locking**: (Optional) Add DynamoDB table for state locking to prevent concurrent modifications

### Backend Details

- **Bucket**: `aws-glue-assets-651914028873-us-east-1`
- **Key**: `terraform/glue-schema-registry/terraform.tfstate`
- **Region**: `us-east-1`
- **Encryption**: Enabled

### Optional: DynamoDB State Locking

For team environments, consider adding DynamoDB state locking:

1. Create a DynamoDB table with:
   - Primary key: `LockID` (String)
   - Billing mode: On-demand or Provisioned

2. Update `main.tf` backend configuration:
   ```hcl
   backend "s3" {
     # ... existing config ...
     dynamodb_table = "terraform-state-lock"
   }
   ```

## Schema Management

### File-Based Schema Discovery

The Terraform configuration automatically discovers schema files from:
- `schemas/avro/*.avsc` - Avro schema files
- `schemas/json/*.json` - JSON Schema files

Schema names are derived from filenames (without extension). For example:
- `schemas/avro/salesforce-audit.avsc` → schema name: `salesforce-audit`
- `schemas/json/salesforce-event.json` → schema name: `salesforce-event`

### Metadata Files (Optional)

You can create optional metadata files alongside schema files to customize:
- Description
- Compatibility mode
- Tags

Example: `schemas/avro/my-schema.metadata.json`
```json
{
  "description": "Custom description",
  "compatibility": "FORWARD",
  "tags": {
    "Environment": "production",
    "Team": "data-engineering"
  }
}
```

### Defaults

If no metadata file exists, defaults are used:
- **Description**: Auto-generated from schema name
- **Compatibility**: Value from `default_compatibility` variable (default: `BACKWARD`)
- **Tags**: Global tags from `terraform.tfvars`

See `schemas/README.md` for detailed documentation on adding and managing schemas.
