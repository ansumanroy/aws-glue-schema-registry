# AWS Glue Schema Registry - Java Client

Java wrapper client for AWS Glue Schema Registry with Avro and JSON serialization support.

## Overview

This Java package provides:
- **Client**: A wrapper library for interacting with AWS Glue Schema Registry
- **Avro Serialization**: Serialize/deserialize objects using Avro schemas
- **JSON Serialization**: Serialize/deserialize objects using JSON schemas
- **Model Classes**: Data models for schema objects

## Installation

This project supports both **Gradle** and **Maven** builds and requires **Java 17**.

### Using Gradle (Default)

The Gradle wrapper is included, so you can build without installing Gradle:

```bash
# Verify Java version (should be 17)
java -version

# Build the project
./gradlew build

# Or using Makefile
make java-build-gradle
```

### Using Maven

Maven build is also supported for MuleSoft and other Maven-based projects:

```bash
# Verify Java version (should be 17)
java -version

# Build the project
mvn clean compile

# Run tests
mvn test

# Build JAR
mvn package

# Or using Makefile
make java-build-maven
make java-test-maven
make java-jar-maven
```

## Quick Start

```java
import com.aws.glue.schema.registry.client.GlueSchemaRegistryClient;
import com.aws.glue.schema.registry.implementation.AvroSerializer;
import com.aws.glue.schema.registry.implementation.model.SalesforceAudit;
import software.amazon.awssdk.regions.Region;

// Initialize client
GlueSchemaRegistryClient client = new GlueSchemaRegistryClient(
    Region.US_EAST_1, "my-registry");

// Create an audit event
SalesforceAudit auditEvent = new SalesforceAudit(
    "event-123",
    "UserLogin",
    1704067200000L,
    "User logged in"
);

// Serialize
byte[] serialized = AvroSerializer.serialize(
    client, "SalesforceAudit", auditEvent);

// Deserialize
SalesforceAudit deserialized = AvroSerializer.deserialize(
    client, "SalesforceAudit", serialized);
```

## Running Tests

### Using Gradle
```bash
./gradlew test
# Or
make java-test-gradle
```

### Using Maven
```bash
mvn test
# Or
make java-test-maven
```

## Project Structure

```
java/
├── src/
│   ├── main/java/
│   │   └── com/aws/glue/schema/registry/
│   │       ├── client/              # Glue Schema Registry client
│   │       ├── implementation/      # Serializers
│   │       └── implementation/model/ # Data models
│   └── test/java/                   # Tests
├── build.gradle                     # Gradle build configuration
├── pom.xml                          # Maven build configuration
└── README.md
```

## Dependencies

- AWS SDK for Java v2 (Glue)
- Apache Avro
- Jackson (for JSON)
- JUnit 5 (for testing)

## Environment Variables

- `GLUE_REGISTRY_NAME`: Name of the Glue Schema Registry (default: "glue-schema-registry-ansumanroy-6219")
- `AWS_REGION`: AWS region (default: "us-east-1")
- AWS credentials should be configured via AWS CLI or environment variables

## License

See [LICENSE](../LICENSE) file for details.
