# AWS Glue Schema Registry Java Client

Java wrapper client for interacting with AWS Glue Schema Registry.

## Features

- Create and manage schemas in Glue Schema Registry
- Register schema versions
- Retrieve schemas and schema versions
- Update schema compatibility modes
- List all schemas in a registry

## Prerequisites

- Java 11 or higher
- Build tool: Maven 3.6+ or Gradle 7.0+
- AWS credentials configured (via AWS CLI, environment variables, or IAM role)

## Building

### Using Gradle

```bash
# Build the project
./gradlew build

# Compile only
./gradlew compileJava

# Run tests
./gradlew test

# Clean build
./gradlew clean build
```

### Using Maven

```bash
# Build the project
mvn clean compile

# Run tests
mvn test

# Clean build
mvn clean install
```

## Usage Example

```java
import com.aws.glue.schema.registry.client.GlueSchemaRegistryClient;
import com.aws.glue.schema.registry.implementation.AvroSerializer;
import com.aws.glue.schema.registry.implementation.model.SalesforceAudit;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.glue.model.Compatibility;

// Create a client
GlueSchemaRegistryClient client = new GlueSchemaRegistryClient(
    Region.US_EAST_1, 
    "my-schema-registry"
);

// Create a schema
String schemaDefinition = """
    {
      "type": "record",
      "name": "User",
      "fields": [
        {"name": "id", "type": "string"},
        {"name": "name", "type": "string"}
      ]
    }
    """;

client.createSchema(
    "user-schema",
    "AVRO",
    schemaDefinition,
    Compatibility.BACKWARD
);

// Get a schema
var schema = client.getSchema("user-schema");

// Serialize/Deserialize example
SalesforceAudit auditEvent = new SalesforceAudit(
    "event-123",
    "UserLogin",
    System.currentTimeMillis(),
    "User logged in"
);

byte[] serialized = AvroSerializer.serialize(client, "SalesforceAudit", auditEvent);
SalesforceAudit deserialized = AvroSerializer.deserialize(client, "SalesforceAudit", serialized);

// List all schemas
var schemas = client.listSchemas();

// Clean up
client.close();
```

## Project Structure

```
java/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/aws/glue/schema/registry/
│   │   │       ├── client/
│   │   │       │   ├── GlueSchemaRegistryClient.java
│   │   │       │   └── SchemaRegistryException.java
│   │   │       └── implementation/
│   │   │           ├── AvroSerializer.java
│   │   │           └── model/
│   │   │               └── SalesforceAudit.java
│   │   └── resources/
│   │       └── salesforce-audit.avsc
│   └── test/
│       └── java/
│           └── com/aws/glue/schema/registry/
│               └── SalesforceAuditSerializationTest.java
├── build.gradle
├── settings.gradle
├── pom.xml (Maven alternative)
└── README.md
```

## Package Organization

- **`com.aws.glue.schema.registry.client`**: Core client classes
  - `GlueSchemaRegistryClient`: Main client for interacting with Glue Schema Registry
  - `SchemaRegistryException`: Custom exception for schema registry operations

- **`com.aws.glue.schema.registry.implementation`**: Implementation classes
  - `AvroSerializer`: Utility for Avro serialization/deserialization
  - `model`: Data model classes
    - `SalesforceAudit`: Model representing Salesforce audit events

## Dependencies

- AWS SDK for Java v2 (Glue client)
- Jackson for JSON processing
- SLF4J for logging
- JUnit 5 for testing
