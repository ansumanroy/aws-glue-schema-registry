# Terraform Infrastructure as Code for Glue Schema Registry

This directory contains Terraform configuration to deploy and manage schemas in AWS Glue Schema Registry.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- AWS provider access to create Glue resources
- Access to S3 bucket: `aws-glue-assets-651914028873-us-east-1` (for Terraform state storage)

## Usage

1. Customize `terraform.tfvars` with your configuration:

```hcl
aws_region         = "us-east-1"
registry_name      = "my-schema-registry"
registry_description = "My application schemas"

schemas = {
  "user-schema" = {
    description       = "User schema definition"
    data_format       = "AVRO"
    schema_definition = file("schemas/user.avsc")
    compatibility     = "BACKWARD"
  }
}
```

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

## SalesforceAudit Schema

The Terraform configuration automatically creates a `SalesforceAudit` schema in the registry. This schema is read from the Java resources file at `../java/src/main/resources/salesforce-audit.avsc`.

The SalesforceAudit schema includes:
- **Event ID** (string) - Unique identifier for the audit event
- **Event Name** (string) - Name of the audit event
- **Timestamp** (long) - Timestamp in milliseconds since epoch
- **Event Details** (string) - Detailed information about the audit event

You can configure the compatibility mode using the `salesforce_audit_compatibility` variable in your `terraform.tfvars` file.
