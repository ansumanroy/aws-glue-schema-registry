# Terraform Infrastructure as Code for Glue Schema Registry

This directory contains Terraform configuration to deploy and manage schemas in AWS Glue Schema Registry using a reusable module.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- AWS provider access to create Glue resources
- Access to S3 bucket: `aws-glue-assets-651914028873-us-east-1` (for Terraform state storage)

## Usage

### Quick Start - File-Based Schema Management (Recommended)

1. **Add Schema Files**: Place your schema files in the appropriate directories at the project root:
   - `schemas/avro/*.avsc` for Avro schemas
   - `schemas/json/*.json` for JSON schemas

2. **Customize `terraform.tfvars`** with your registry configuration:

```hcl
create_registry = true  # Set to false to disable registry creation

aws_region         = "us-east-1"
registry_name      = "my-schema-registry"
registry_description = "My application schemas"
default_compatibility = "BACKWARD"
```

3. **Optional**: Add metadata files for custom descriptions, compatibility, or tags:
   - `schemas/avro/my-schema.metadata.json` (at project root)
   - `schemas/json/my-schema.metadata.json` (at project root)

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

2. **Initialize Terraform** (with S3 backend):

The configuration uses an S3 backend for storing Terraform state. The backend is configured in `backend.tf`:

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

3. **Review the plan**:

```bash
# Using Makefile (recommended)
make terraform-plan

# Or manually
terraform plan
```

4. **Apply the configuration**:

```bash
# Using Makefile (recommended)
make terraform-apply

# Or manually
terraform apply
```

### Conditional Creation

You can disable registry creation by setting `create_registry = false` in `terraform.tfvars`:

```hcl
create_registry = false  # Disables registry and schema creation
```

When disabled, all outputs will return `null` or empty values. This is useful for:
- Testing Terraform configuration without creating resources
- Temporarily disabling resource creation
- Managing schemas manually outside of Terraform

## Module Usage

This configuration uses the `schema-registry` module located at `modules/schema-registry/`. 

### As a Root Module

The current setup uses the module as a root module (directly in this directory). To use it in another Terraform configuration:

```hcl
module "glue_schema_registry" {
  source = "path/to/terraform/modules/schema-registry"

  registry_name        = "my-registry"
  schemas_base_path    = "${path.module}/schemas"
  default_compatibility = "BACKWARD"
}
```

See `modules/schema-registry/README.md` for complete module documentation.

## Structure

```
terraform/
├── main.tf                          # Root configuration that calls the module
├── variables.tf                      # Root input variables
├── outputs.tf                        # Root output values
├── terraform.tfvars.example         # Example variables file
├── backend.tf                        # Backend configuration
├── backend.hcl.example               # Example backend configuration (alternative approach)
├── modules/
│   └── schema-registry/              # Reusable Glue Schema Registry module
│       ├── main.tf                   # Module resource definitions
│       ├── variables.tf              # Module input variables
│       ├── outputs.tf                # Module outputs
│       └── README.md                 # Module documentation
../schemas/                           # Schema files directory (at project root)
    ├── avro/                         # Avro schema files (.avsc)
    ├── json/                         # JSON Schema files (.json)
    └── README.md                     # Schema management guide
```

### Module Structure

This configuration uses a reusable Terraform module located in `modules/schema-registry/`. The module:
- Creates the Glue Schema Registry
- Automatically discovers schema files from directories
- Supports file-based and manual schema definitions
- Provides comprehensive outputs

See `modules/schema-registry/README.md` for detailed module documentation.

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

The Terraform configuration automatically discovers schema files from the `schemas/` directory at the project root:
- `schemas/avro/*.avsc` - Avro schema files
- `schemas/json/*.json` - JSON Schema files

Schema names are derived from filenames (without extension). For example:
- `schemas/avro/salesforce-audit.avsc` → schema name: `salesforce-audit`
- `schemas/json/salesforce-event.json` → schema name: `salesforce-event`

**Note**: The schemas directory is located at the project root level (outside the `terraform/` directory) to separate configuration data from infrastructure code.

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
