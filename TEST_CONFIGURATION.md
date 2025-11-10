# Test Configuration Guide

This document explains how to configure test settings for the AWS Glue Schema Registry client tests across all language implementations.

## Overview

Test configuration values (registry name, AWS region, schema names) are loaded from configuration files, with support for environment variable overrides. This allows you to:

1. Use default values from configuration files
2. Override values via environment variables
3. Maintain different configurations for different environments

## Configuration Priority

Configuration values are loaded in the following order (highest priority first):

1. **Environment Variables** - Highest priority
2. **System Properties** (Java only) - Medium priority
3. **Configuration Files** - Default values

## Configuration Files

### Java

- **Config File**: `java/src/test/resources/test-config.properties`
- **Utility Class**: `com.aws.glue.schema.registry.config.TestConfig`

Example:
```properties
glue.registry.name=glue-schema-registry-ansumanroy-6219
aws.region=us-east-1
schema.name.avro=SalesforceAudit
schema.name.json=SalesAuditJSON
```

### Python

- **Config File**: `python/tests/test-config.ini`
- **Utility Class**: `tests.test_config.TestConfig`

Example:
```ini
[test]
glue.registry.name=glue-schema-registry-ansumanroy-6219
aws.region=us-east-1
schema.name.avro=SalesforceAudit
schema.name.json=SalesAuditJSON
```

### Golang

- **Config File**: `golang/testdata/test-config.properties`
- **Package**: `github.com/aws-glue-schema-registry/golang/testconfig`

Example:
```properties
glue.registry.name=glue-schema-registry-ansumanroy-6219
aws.region=us-east-1
schema.name.avro=SalesforceAudit
schema.name.json=SalesAuditJSON
```

## Environment Variables

All languages support the following environment variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `GLUE_REGISTRY_NAME` | Glue Schema Registry name | `my-registry` |
| `AWS_REGION` | AWS region | `us-east-1` |
| `SCHEMA_NAME_AVRO` | Avro schema name | `SalesforceAudit` |
| `SCHEMA_NAME_JSON` | JSON schema name | `SalesAuditJSON` |

## Usage Examples

### Java

```java
import com.aws.glue.schema.registry.config.TestConfig;

String registryName = TestConfig.getRegistryName();
Region awsRegion = TestConfig.getAWSRegion();
String avroSchemaName = TestConfig.getAvroSchemaName();
String jsonSchemaName = TestConfig.getJsonSchemaName();
```

### Python

```python
from tests.test_config import TestConfig

registry_name = TestConfig.get_registry_name()
aws_region = TestConfig.get_aws_region()
avro_schema_name = TestConfig.get_avro_schema_name()
json_schema_name = TestConfig.get_json_schema_name()
```

### Golang

```go
import "github.com/aws-glue-schema-registry/golang/testconfig"

cfg := testconfig.LoadConfig()
registryName := cfg.RegistryName
awsRegion := cfg.AWSRegion
avroSchemaName := cfg.AvroSchemaName
jsonSchemaName := cfg.JsonSchemaName
```

## Running Tests with Custom Configuration

### Using Environment Variables

```bash
# Java
export GLUE_REGISTRY_NAME=my-custom-registry
export AWS_REGION=us-west-2
cd java && ./gradlew test

# Python
export GLUE_REGISTRY_NAME=my-custom-registry
export AWS_REGION=us-west-2
cd python && python -m pytest tests/

# Golang
export GLUE_REGISTRY_NAME=my-custom-registry
export AWS_REGION=us-west-2
cd golang && go test ./...
```

### Using Configuration Files

Simply edit the appropriate configuration file for your language:

1. **Java**: Edit `java/src/test/resources/test-config.properties`
2. **Python**: Edit `python/tests/test-config.ini`
3. **Golang**: Edit `golang/testdata/test-config.properties`

## Default Values

If no configuration file is found and no environment variables are set, the following default values are used:

- **Registry Name**: `glue-schema-registry-ansumanroy-6219`
- **AWS Region**: `us-east-1`
- **Avro Schema Name**: `SalesforceAudit`
- **JSON Schema Name**: `SalesAuditJSON`

## Best Practices

1. **Don't commit sensitive values**: Use environment variables for production-like test environments
2. **Use configuration files for defaults**: Keep common test values in configuration files
3. **Document custom configurations**: If your team uses specific values, document them in the config files
4. **Test with different environments**: Use environment variables to test against different AWS accounts/regions

## Troubleshooting

### Configuration not loading

- **Java**: Ensure `test-config.properties` is in `src/test/resources/`
- **Python**: Ensure `test-config.ini` is in `tests/` directory
- **Golang**: Ensure `test-config.properties` is in `testdata/` directory

### Environment variables not taking effect

- Ensure environment variables are set before running tests
- Check that environment variable names are correct (case-sensitive)
- For Java, you can also use system properties: `-Dglue.registry.name=my-registry`

### Schema names not matching

- Verify schema names in your Glue Schema Registry match the configuration
- Check that schemas exist in the specified registry
- Ensure you have appropriate AWS credentials and permissions

