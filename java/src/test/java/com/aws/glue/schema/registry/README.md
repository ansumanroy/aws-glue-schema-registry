# Test Classes

## SalesforceAuditSerializationTest

This test class demonstrates serialization and deserialization of `SalesforceAudit` objects using the `GlueSchemaRegistryClient`.

### Prerequisites

1. **AWS Credentials**: Configure AWS credentials via:
   - AWS CLI: `aws configure`
   - Environment variables: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
   - IAM role (if running on EC2/Lambda)

2. **Glue Schema Registry**: The schema registry and `SalesforceAudit` schema must be deployed using Terraform:
   ```bash
   cd ../terraform
   terraform init
   terraform apply
   ```

3. **Environment Variables** (optional):
   - `GLUE_REGISTRY_NAME`: Name of your Glue Schema Registry (default: "test-schema-registry")
   - `AWS_REGION`: AWS region (default: "us-east-1")

### Running the Tests

```bash
# Run all tests
mvn test

# Run only serialization tests
mvn test -Dtest=SalesforceAuditSerializationTest

# Run with specific registry name
GLUE_REGISTRY_NAME=my-registry mvn test
```

### Test Coverage

The test class includes the following test cases:

1. **Schema Existence Test**: Verifies the SalesforceAudit schema exists in the registry
2. **Serialization Test**: Tests serialization of SalesforceAudit objects to Avro bytes
3. **Deserialization Test**: Tests deserialization of Avro bytes back to SalesforceAudit objects
4. **Round-Trip Test**: Tests complete serialization/deserialization cycle with multiple test cases
5. **Edge Cases**: Tests with empty strings and long event details
6. **Error Handling**: Tests deserialization with invalid data

### Usage Example

```java
// Create client
GlueSchemaRegistryClient client = new GlueSchemaRegistryClient(
    Region.US_EAST_1, 
    "my-registry"
);

// Create SalesforceAudit object
SalesforceAudit auditEvent = new SalesforceAudit(
    "event-123",
    "UserLogin",
    System.currentTimeMillis(),
    "User logged in successfully"
);

// Serialize
byte[] serialized = AvroSerializer.serialize(client, "SalesforceAudit", auditEvent);

// Deserialize
SalesforceAudit deserialized = AvroSerializer.deserialize(client, "SalesforceAudit", serialized);
```
