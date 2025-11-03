# Makefile Usage Guide

This project includes a Makefile wrapper that simplifies building and deploying the Java client and Terraform infrastructure.

## Prerequisites

- **Make** - Usually pre-installed on Unix systems
- **Terraform** >= 1.0 - [Installation Guide](https://www.terraform.io/downloads)
- **AWS CLI** - [Installation Guide](https://aws.amazon.com/cli/)
- **Gradle** (optional, wrapper will be created automatically)

## Quick Start

### Initial Setup

```bash
# Set up the project (creates Gradle wrapper, terraform.tfvars, etc.)
make setup

# View all available targets
make help
```

### Configuration

1. **AWS Credentials**: Configure using `aws configure` or environment variables
   ```bash
   aws configure
   ```

2. **Terraform Variables**: Copy and edit the example file
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # Edit terraform.tfvars with your configuration
   ```

3. **Makefile Variables** (optional): Create `.makefile.env` for custom variables
   ```bash
   cp .makefile.env.example .makefile.env
   # Edit .makefile.env with your settings
   ```

## Common Tasks

### Java Build Tasks

```bash
# Build the Java project
make java-build

# Run tests
make java-test

# Clean build artifacts
make java-clean

# Build JAR file
make java-jar

# Generate Avro classes
make java-avro
```

### Terraform Tasks

```bash
# Initialize Terraform
make terraform-init

# Validate Terraform configuration
make terraform-validate

# Format Terraform files
make terraform-fmt

# Generate execution plan
make terraform-plan

# Deploy to AWS (with confirmation)
make terraform-apply

# Deploy (full: validate, plan, apply)
make deploy

# Destroy infrastructure (with confirmation)
make terraform-destroy

# Show Terraform outputs
make terraform-output
```

### Combined Tasks

```bash
# Build everything
make build

# Run all tests
make test

# Clean all artifacts
make clean

# Build and validate everything
make all
```

## Deployment to AWS

### Quick Deployment

```bash
# Full deployment workflow (recommended)
make deploy
```

This will:
1. Check AWS credentials
2. Validate Terraform configuration
3. Generate a plan
4. Apply the configuration (creates the Glue Schema Registry and SalesforceAudit schema)

### Step-by-Step Deployment

```bash
# 1. Initialize Terraform
make terraform-init

# 2. Validate configuration
make terraform-validate

# 3. Review the plan
make terraform-plan

# 4. Apply the configuration
make terraform-apply
```

### Custom Variables

You can override variables using environment variables or Makefile variables:

```bash
# Using environment variables
export TF_VAR_REGISTRY_NAME=my-custom-registry
export TF_VAR_AWS_REGION=us-west-2
make terraform-apply

# Using command line
make terraform-apply TF_VAR_REGISTRY_NAME=my-registry TF_VAR_AWS_REGION=us-west-2
```

## Available Variables

- `AWS_REGION` - AWS region (default: us-east-1)
- `TF_VAR_REGISTRY_NAME` - Glue Schema Registry name (default: auto-generated)
- `TF_VAR_AWS_REGION` - AWS region for Terraform (default: us-east-1)
- `TF_VAR_SALESFORCE_AUDIT_COMPATIBILITY` - Compatibility mode (default: BACKWARD)

## Examples

### Deploy to Development Environment

```bash
export TF_VAR_REGISTRY_NAME=glue-schema-registry-dev
export TF_VAR_AWS_REGION=us-east-1
make deploy
```

### Deploy to Production Environment

```bash
export TF_VAR_REGISTRY_NAME=glue-schema-registry-prod
export TF_VAR_AWS_REGION=us-east-1
export TF_VAR_SALESFORCE_AUDIT_COMPATIBILITY=FULL
make terraform-plan
make terraform-apply
```

### Build and Test Java Code

```bash
# Build the project
make java-build

# Run tests
make java-test

# Build JAR
make java-jar
```

## Troubleshooting

### AWS Credentials Not Configured

```bash
# Check AWS configuration
make check-aws

# Configure AWS credentials
aws configure
```

### Terraform Not Found

```bash
# Install Terraform
# macOS: brew install terraform
# Linux: See https://www.terraform.io/downloads
```

### Gradle Issues

```bash
# Create Gradle wrapper
cd java && gradle wrapper
```

## Safety Features

- **Confirmation Prompts**: Destructive operations (apply, destroy) require confirmation
- **Pre-flight Checks**: Commands check for prerequisites before running
- **Validation**: Terraform validation runs before planning/applying
- **Colored Output**: Visual feedback for different operations

## Help

```bash
# View all available targets with descriptions
make help

# Display project information
make info
```
