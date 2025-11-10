# AWS Glue Schema Registry - Multi-Language Client

Multi-language wrapper clients for AWS Glue Schema Registry with Avro and JSON serialization support.

## Overview

This project provides client libraries in three languages:
- **Java**: Full-featured client with Gradle build system
- **Python**: Python package with pytest test suite
- **Golang**: Go module with standard testing

All implementations support:
- AWS Glue Schema Registry client operations
- Avro serialization/deserialization
- JSON serialization/deserialization
- SalesforceAudit model example

## Quick Start

### Prerequisites

- **Java**: Java 17 and Gradle (wrapper included) or Maven
- **Python**: Python 3.8+ and pip (virtual environment will be created automatically)
- **Golang**: Go 1.21+
- **AWS CLI**: Configured with appropriate credentials

### Build and Test

```bash
# Build all projects
make build

# Run all tests
make test

# Build individual projects
make java-build          # Uses Gradle (default)
make java-build-gradle   # Explicitly use Gradle
make java-build-maven    # Use Maven instead
make python-build        # Creates venv and builds package
make golang-build

# Run individual tests
make java-test           # Uses Gradle (default)
make java-test-gradle    # Explicitly use Gradle
make java-test-maven     # Use Maven instead
make python-test         # Uses virtual environment
make golang-test

# Generate documentation
make java-javadoc        # Generate Javadoc (default: Gradle)
make python-docs         # Generate Python documentation
make golang-docs         # Generate Golang documentation
make docs                # Generate all documentation
```

### Python Virtual Environment

The Python implementation uses a virtual environment to isolate dependencies:

```bash
# Create virtual environment
make python-venv

# Install dependencies
make python-install

# Install development dependencies (includes pytest, build tools)
make python-install-dev

# Build Python package (wheel and source distribution)
make python-build

# Install the built package
make python-install-package
```

## Project Structure

```
aws-glue-schema-registry/
├── java/                    # Java implementation
│   ├── src/
│   │   ├── main/java/       # Source code
│   │   └── test/java/       # Tests
│   ├── build.gradle         # Gradle build configuration
│   └── README.md            # Java-specific documentation
├── python/                  # Python implementation
│   ├── glue_schema_registry/ # Package source
│   ├── tests/               # Test files
│   ├── requirements.txt     # Dependencies
│   └── README.md            # Python-specific documentation
├── golang/                  # Golang implementation
│   ├── client/              # Client package
│   ├── model/               # Model package
│   ├── serializer/          # Serializer package
│   ├── go.mod               # Go module
│   └── README.md            # Golang-specific documentation
├── schemas/                 # Schema definition files
│   ├── avro/               # Avro schema files
│   └── json/               # JSON Schema files
├── Makefile                 # Build automation
└── README.md               # This file
```

## Language-Specific Documentation

- **[Java README](java/README.md)** - Java client documentation
- **[Python README](python/README.md)** - Python client documentation
- **[Golang README](golang/README.md)** - Golang client documentation

## Common Commands

```bash
# View all available commands
make help

# Build all projects
make build

# Run all tests
make test

# Clean all build artifacts
make clean

# Setup project (create Gradle wrapper, etc.)
make setup

# Display project information
make info
```

## Features

- ✅ Multi-language support (Java, Python, Golang)
- ✅ AWS Glue Schema Registry client wrapper
- ✅ Avro serialization/deserialization
- ✅ JSON serialization/deserialization
- ✅ Comprehensive test suites for each language
- ✅ SalesforceAudit schema example
- ✅ Unified Makefile for build automation

## CI/CD

CI/CD pipelines are available for automated builds and tests in both Azure DevOps and GitHub Actions. Two approaches are provided for each platform:

### GitHub Actions

#### Using Makefile (Recommended)
- **Full Workflow**: `.github/workflows/build.yml` - Uses `make build`, `make test`, `make docs` targets
- **Simple Workflow**: `.github/workflows/build-simple.yml` - Uses `make build` and `make test`

#### Using Explicit Steps
- **Full Workflow**: `.github/workflows/build-explicit.yml` - Explicit Gradle/Maven, Python, Golang commands

**Setup**: Configure GitHub Secrets: `GLUE_REGISTRY_NAME`, `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

### Azure DevOps

#### Using Makefile (Recommended)
- **Full Pipeline**: `azure-pipelines.yml` - Uses `make build`, `make test`, `make docs` targets
- **Simple Pipeline**: `.azure-pipelines/azure-pipelines-simple.yml` - Uses `make build` and `make test`

#### Using Explicit Steps
- **Full Pipeline**: `azure-pipelines-explicit.yml` - Explicit Gradle/Maven, Python, Golang commands
- **Simple Pipeline**: `.azure-pipelines/azure-pipelines-simple-explicit.yml` - Explicit commands for each language

**Benefits of Makefile approach**: Simpler pipeline, consistent with local development, easier to maintain

**Benefits of Explicit Steps**: More control, detailed logging, easier to debug individual steps

For detailed pipeline configuration, see:
- [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md) - GitHub Actions workflows
- [AZURE_PIPELINES.md](AZURE_PIPELINES.md) - Azure DevOps pipelines

## Test Configuration

Test configuration values (registry name, AWS region, schema names) can be configured via configuration files or environment variables. For detailed information, see [TEST_CONFIGURATION.md](TEST_CONFIGURATION.md).

## Environment Variables

All implementations use the following environment variables:

- `GLUE_REGISTRY_NAME`: Name of the Glue Schema Registry (default: "glue-schema-registry-ansumanroy-6219")
- `AWS_REGION`: AWS region (default: "us-east-1")
- `SCHEMA_NAME_AVRO`: Avro schema name (default: "SalesforceAudit")
- `SCHEMA_NAME_JSON`: JSON schema name (default: "SalesAuditJSON")
- AWS credentials should be configured via AWS CLI or environment variables

## Example Usage

### Java

```java
import com.aws.glue.schema.registry.client.GlueSchemaRegistryClient;
import com.aws.glue.schema.registry.implementation.AvroSerializer;
import com.aws.glue.schema.registry.implementation.model.SalesforceAudit;
import software.amazon.awssdk.regions.Region;

GlueSchemaRegistryClient client = new GlueSchemaRegistryClient(
    Region.US_EAST_1, "my-registry");

SalesforceAudit event = new SalesforceAudit(
    "event-123", "UserLogin", 1704067200000L, "User logged in");

byte[] serialized = AvroSerializer.serialize(client, "SalesforceAudit", event);
SalesforceAudit deserialized = AvroSerializer.deserialize(
    client, "SalesforceAudit", serialized);
```

### Python

```python
from glue_schema_registry.client import GlueSchemaRegistryClient
from glue_schema_registry.avro_serializer import AvroSerializer
from glue_schema_registry.model import SalesforceAudit

client = GlueSchemaRegistryClient("us-east-1", "my-registry")

event = SalesforceAudit(
    event_id="event-123",
    event_name="UserLogin",
    timestamp=1704067200000,
    event_details="User logged in"
)

serialized = AvroSerializer.serialize(client, "SalesforceAudit", event)
deserialized = AvroSerializer.deserialize(client, "SalesforceAudit", serialized)
```

### Golang

```go
import (
    "github.com/aws-glue-schema-registry/golang/client"
    "github.com/aws-glue-schema-registry/golang/model"
    "github.com/aws-glue-schema-registry/golang/serializer"
)

c, _ := client.NewGlueSchemaRegistryClient("us-east-1", "my-registry")
defer c.Close()

event := &model.SalesforceAudit{
    EventID:      "event-123",
    EventName:    "UserLogin",
    Timestamp:    1704067200000,
    EventDetails: "User logged in",
}

avroSerializer := &serializer.AvroSerializer{}
serialized, _ := avroSerializer.Serialize(c, "SalesforceAudit", event)
deserialized, _ := avroSerializer.Deserialize(c, "SalesforceAudit", serialized)
```

## Publishing to MuleSoft Exchange

This project can be published to MuleSoft Exchange for easy integration into MuleSoft applications.

### Quick Start

```bash
# Set Anypoint Platform credentials
export ANYPOINT_USERNAME=your-username
export ANYPOINT_PASSWORD=your-password
export ANYPOINT_ORG_ID=your-org-id

# Publish version 1.0.0
make java-publish-exchange VERSION=1.0.0
```

For detailed instructions, see [MULESOFT_EXCHANGE.md](MULESOFT_EXCHANGE.md).

## License

See [LICENSE](LICENSE) file for details.
