# AWS Glue Schema Registry

Java wrapper client for AWS Glue Schema Registry with Terraform infrastructure as code.

## Overview

This project provides:
- **Java Client**: A wrapper library for interacting with AWS Glue Schema Registry
- **Terraform IAC**: Infrastructure as Code to deploy schemas to Glue Schema Registry
- **Makefile Wrapper**: Simplified build and deployment commands

## Quick Start

### Prerequisites

- Java 11+
- Terraform >= 1.0
- AWS CLI configured
- Make (for convenience wrapper)

### Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd aws-glue-schema-registry

# Set up the project
make setup

# Configure AWS credentials
aws configure

# Configure Terraform variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform/terraform.tfvars with your settings
```

### Deploy to AWS

```bash
# Deploy the Glue Schema Registry and SalesforceAudit schema
make deploy

# Or step by step:
make terraform-init
make terraform-plan
make terraform-apply
```

### Build and Test

```bash
# Build Java project
make java-build

# Run tests
make java-test

# Build everything
make build
```

## Project Structure

```
aws-glue-schema-registry/
├── java/                    # Java client wrapper
│   ├── src/
│   │   ├── main/java/       # Source code
│   │   └── test/java/       # Tests
│   ├── build.gradle         # Gradle build file
│   └── pom.xml              # Maven build file (alternative)
├── terraform/               # Terraform IAC
│   ├── main.tf             # Main Terraform configuration
│   ├── variables.tf        # Variable definitions
│   └── outputs.tf          # Output definitions
├── Makefile                # Build and deployment wrapper
└── README.md              # This file
```

## Documentation

- **[Makefile Guide](Makefile.md)** - Detailed Makefile usage and examples
- **[Java Client README](java/README.md)** - Java client documentation
- **[Terraform README](terraform/README.md)** - Terraform configuration guide

## Common Commands

```bash
# View all available commands
make help

# Deploy to AWS
make deploy

# Build Java project
make java-build

# Run tests
make java-test

# Destroy infrastructure
make terraform-destroy
```

## Features

- ✅ Java wrapper client for Glue Schema Registry
- ✅ Avro serialization/deserialization support
- ✅ Terraform infrastructure as code
- ✅ Automated deployment with Makefile
- ✅ Comprehensive test suite
- ✅ SalesforceAudit schema example

## License

See [LICENSE](LICENSE) file for details.
