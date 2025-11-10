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

## Generating Documentation

### Javadoc

Generate API documentation using Javadoc:

#### Using Gradle
```bash
./gradlew javadoc
# Or
make java-javadoc-gradle
```

#### Using Maven
```bash
mvn javadoc:javadoc
# Or
make java-javadoc-maven
```

The documentation will be generated in:
- **Gradle**: `build/docs/javadoc/index.html`
- **Maven**: `target/docs/javadoc/index.html`

Open the `index.html` file in a browser to view the documentation.

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

## MuleSoft Integration

This client can be integrated into MuleSoft applications. See [MULESOFT_INTEGRATION.md](MULESOFT_INTEGRATION.md) for detailed instructions.

### Quick MuleSoft Setup

1. Build the JAR: `mvn clean package`
2. Add to MuleSoft project as Maven dependency
3. Configure AWS credentials in MuleSoft secure properties
4. Use `GlueSchemaRegistryMuleModule` in your flows

### MuleSoft Example

```java
// Create module from MuleSoft configuration
GlueSchemaRegistryMuleModule module = GlueSchemaRegistryMuleModule.create();

// Serialize to Avro
byte[] serialized = module.serializeAvro("SalesforceAudit", auditEvent);

// Deserialize from Avro
SalesforceAudit deserialized = module.deserializeAvro("SalesforceAudit", serialized);
```

See [MULESOFT_INTEGRATION.md](MULESOFT_INTEGRATION.md) for complete examples.

## Configuration

### Using Configuration Builder

```java
GlueSchemaRegistryConfig config = GlueSchemaRegistryConfig.builder()
    .registryName("my-registry")
    .region(Region.US_EAST_1)
    .accessKeyId("your-access-key")
    .secretAccessKey("your-secret-key")
    .build();

GlueSchemaRegistryClient client = new GlueSchemaRegistryClient(config);
```

### Using Environment Variables

```java
// Reads from GLUE_REGISTRY_NAME and AWS_REGION environment variables
GlueSchemaRegistryConfig config = GlueSchemaRegistryConfig.fromEnvironment();
GlueSchemaRegistryClient client = new GlueSchemaRegistryClient(config);
```

### Using Client Builder

```java
GlueSchemaRegistryClient client = GlueSchemaRegistryClient.builder()
    .registryName("my-registry")
    .region(Region.US_EAST_1)
    .build();
```

## Environment Variables

- `GLUE_REGISTRY_NAME`: Name of the Glue Schema Registry (default: "glue-schema-registry-ansumanroy-6219")
- `AWS_REGION`: AWS region (default: "us-east-1")
- `AWS_ACCESS_KEY_ID`: AWS access key ID (optional)
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key (optional)
- `AWS_SESSION_TOKEN`: AWS session token (optional)

AWS credentials can be configured via:
1. Environment variables
2. AWS credential chain (IAM roles, credential files, etc.)
3. MuleSoft secure properties (in MuleSoft environment)
4. Explicit configuration (programmatic)

## Examples

See the `examples/` directory for usage examples:
- `examples/standalone/`: Standalone Java usage examples
- `examples/mulesoft/`: MuleSoft integration examples

## License

See [LICENSE](../LICENSE) file for details.
