# AWS Glue Schema Registry - Python Client

Python wrapper client for AWS Glue Schema Registry with Avro and JSON serialization support.

## Overview

This Python package provides:
- **Client**: A wrapper library for interacting with AWS Glue Schema Registry
- **Avro Serialization**: Serialize/deserialize objects using Avro schemas
- **JSON Serialization**: Serialize/deserialize objects using JSON schemas
- **Model Classes**: Data models for schema objects

## Installation

### Using Virtual Environment (Recommended)

The project uses a virtual environment to isolate dependencies. Use the Makefile commands:

```bash
# From project root
make python-venv          # Create virtual environment
make python-install       # Install dependencies
make python-install-dev   # Install development dependencies
```

Or manually:

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# For development
pip install -r requirements-dev.txt
```

### Installing the Package

After building the package:

```bash
# Build the package (creates wheel and source distribution)
make python-build

# Install the built package
make python-install-package

# Or manually:
pip install dist/glue_schema_registry-*.whl
```

## Quick Start

```python
from glue_schema_registry.client import GlueSchemaRegistryClient
from glue_schema_registry.avro_serializer import AvroSerializer
from glue_schema_registry.model import SalesforceAudit

# Initialize client
client = GlueSchemaRegistryClient("us-east-1", "my-registry")

# Create an audit event
audit_event = SalesforceAudit(
    event_id="event-123",
    event_name="UserLogin",
    timestamp=1704067200000,
    event_details="User logged in"
)

# Serialize
serialized = AvroSerializer.serialize(client, "SalesforceAudit", audit_event)

# Deserialize
deserialized = AvroSerializer.deserialize(client, "SalesforceAudit", serialized)
```

## Running Tests

Using Makefile (recommended - uses virtual environment):

```bash
# From project root
make python-test
```

Or manually (with virtual environment activated):

```bash
pytest tests/ -v
```

With coverage:

```bash
pytest tests/ --cov=glue_schema_registry --cov-report=html
```

## Building the Package

The package can be built as a wheel and source distribution:

```bash
# Using Makefile (recommended)
make python-build

# Output will be in dist/:
# - glue_schema_registry-1.0.0-py3-none-any.whl (wheel)
# - glue_schema_registry-1.0.0.tar.gz (source distribution)
```

## Project Structure

```
python/
├── glue_schema_registry/      # Package source
│   ├── __init__.py
│   ├── client.py              # Glue Schema Registry client
│   ├── model.py               # Data models
│   ├── avro_serializer.py     # Avro serialization
│   └── json_serializer.py     # JSON serialization
├── tests/                      # Test files
│   ├── __init__.py
│   ├── test_avro_serialization.py
│   └── test_json_serialization.py
├── venv/                      # Virtual environment (created by make python-venv)
├── dist/                      # Built packages (created by make python-build)
├── build/                     # Build artifacts (created by make python-build)
├── requirements.txt           # Runtime dependencies
├── requirements-dev.txt       # Development dependencies
├── setup.py                   # Package configuration
└── README.md
```

## Environment Variables

- `GLUE_REGISTRY_NAME`: Name of the Glue Schema Registry (default: "glue-schema-registry-ansumanroy-6219")
- `AWS_REGION`: AWS region (default: "us-east-1")
- AWS credentials should be configured via AWS CLI or environment variables

## License

See [LICENSE](../LICENSE) file for details.

