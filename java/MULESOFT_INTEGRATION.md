# MuleSoft Integration Guide

This guide explains how to integrate the AWS Glue Schema Registry Java client into MuleSoft applications.

## Overview

The Glue Schema Registry client can be used in MuleSoft applications in two ways:

1. **As a Maven Dependency**: Add the JAR as a dependency in your MuleSoft project
2. **Via Java Module**: Use MuleSoft's Java module to invoke client methods
3. **Via DataWeave**: Import and use Java classes directly in DataWeave scripts

## Prerequisites

- MuleSoft Runtime 4.x or higher
- Java 17 (required by the client)
- AWS credentials configured (via MuleSoft Secure Properties or environment variables)
- Glue Schema Registry with schemas already created

## Installation

### Step 1: Build the Client JAR

Build the client using Maven (required for MuleSoft):

```bash
cd java
mvn clean package
```

This creates `target/schema-registry-client-1.0.0-SNAPSHOT.jar`

### Step 2: Add Dependency to MuleSoft Project

#### Option A: Local Maven Repository

Install the JAR to your local Maven repository:

```bash
mvn install:install-file \
  -Dfile=target/schema-registry-client-1.0.0-SNAPSHOT.jar \
  -DgroupId=com.aws.glue \
  -DartifactId=schema-registry-client \
  -Dversion=1.0.0-SNAPSHOT \
  -Dpackaging=jar
```

Then add to your MuleSoft project's `pom.xml`:

```xml
<dependency>
    <groupId>com.aws.glue</groupId>
    <artifactId>schema-registry-client</artifactId>
    <version>1.0.0-SNAPSHOT</version>
</dependency>
```

#### Option B: Copy JAR to MuleSoft Project

1. Copy the JAR to your MuleSoft project's `lib` directory:
   ```
   src/main/resources/lib/schema-registry-client-1.0.0-SNAPSHOT.jar
   ```

2. Add to `pom.xml` as a system dependency:

```xml
<dependency>
    <groupId>com.aws.glue</groupId>
    <artifactId>schema-registry-client</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <scope>system</scope>
    <systemPath>${project.basedir}/src/main/resources/lib/schema-registry-client-1.0.0-SNAPSHOT.jar</systemPath>
</dependency>
```

### Step 3: Configure AWS Credentials

Configure AWS credentials using one of the following methods:

#### Method 1: MuleSoft Secure Properties (Recommended)

1. Create a secure properties file: `src/main/resources/secure.properties`
2. Add credentials:

```properties
aws.access.key.id=YOUR_ACCESS_KEY
aws.secret.access.key=YOUR_SECRET_KEY
glue.registry.name=your-registry-name
aws.region=us-east-1
```

3. Configure in `mule-artifact.json`:

```json
{
  "minMuleVersion": "4.6.0",
  "secureProperties": [
    "aws.access.key.id",
    "aws.secret.access.key"
  ]
}
```

#### Method 2: Environment Variables

Set environment variables:

```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export GLUE_REGISTRY_NAME=your-registry-name
export AWS_REGION=us-east-1
```

#### Method 3: AWS Credential Chain

Configure AWS credentials using AWS CLI or credential files:

```bash
aws configure
```

## Usage Examples

### Example 1: Using Java Module in MuleSoft Flow

```xml
<flow name="serializeAuditFlow">
    <http:listener path="/audit/serialize" config-ref="HTTP_Listener_config"/>
    
    <!-- Create GlueSchemaRegistryMuleModule -->
    <java:new class="com.aws.glue.schema.registry.mule.GlueSchemaRegistryMuleModule"
              constructor="create()"
              target="muleModule"/>
    
    <!-- Serialize to Avro -->
    <java:invoke class="com.aws.glue.schema.registry.mule.GlueSchemaRegistryMuleModule"
                 method="serializeAvro(java.lang.String, com.aws.glue.schema.registry.implementation.model.SalesforceAudit)"
                 instance="#[vars.muleModule]"
                 arguments="#['SalesforceAudit', payload]"/>
</flow>
```

### Example 2: Using DataWeave

```dataweave
%dw 2.0
import java!com::aws::glue::schema::registry::mule::GlueSchemaRegistryMuleModule
output application/json
---
do {
    var module = GlueSchemaRegistryMuleModule::create()
    var auditEvent = {
        eventId: "event-123",
        eventName: "UserLogin",
        timestamp: now() as Number,
        eventDetails: "User logged in"
    }
    
    var serialized = module.serializeAvro("SalesforceAudit", auditEvent)
    
    {
        serialized: serialized,
        size: sizeOf(serialized)
    }
}
```

### Example 3: Using Configuration Builder

```java
// In a Java class used in MuleSoft
import com.aws.glue.schema.registry.config.GlueSchemaRegistryConfig;
import com.aws.glue.schema.registry.config.MuleSoftConfigProvider;
import com.aws.glue.schema.registry.mule.GlueSchemaRegistryMuleModule;

// Create configuration from MuleSoft properties
GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties();

// Create module
GlueSchemaRegistryMuleModule module = GlueSchemaRegistryMuleModule.create(config);

// Use module
byte[] serialized = module.serializeAvro("SalesforceAudit", auditEvent);
```

## Configuration Options

### Configuration Properties

The client supports the following configuration properties:

- `glue.registry.name`: Name of the Glue Schema Registry (required)
- `aws.region`: AWS region (required, default: us-east-1)
- `aws.access.key.id`: AWS access key ID (optional, uses credential chain if not provided)
- `aws.secret.access.key`: AWS secret access key (optional)
- `aws.session.token`: AWS session token (optional, for temporary credentials)

### Configuration Priority

The client resolves configuration in the following order:

1. **Explicit Configuration**: Programmatically provided configuration
2. **MuleSoft Secure Properties**: Properties defined in `secure.properties` with `secure::` prefix
3. **MuleSoft Application Properties**: Properties in `mule-artifact.json` or application properties
4. **System Properties**: Java system properties
5. **Environment Variables**: Environment variables (AWS_ACCESS_KEY_ID, etc.)
6. **AWS Credential Chain**: Default AWS credential chain (IAM roles, credential files, etc.)

## Error Handling

The client provides MuleSoft-compatible error handling:

```xml
<error-handler>
    <on-error-propagate type="JAVA:EXCEPTION">
        <logger level="ERROR" message="#[error.description]"/>
        <ee:transform>
            <ee:message>
                <ee:set-payload value='#["Error: " ++ error.description]'/>
            </ee:message>
        </ee:transform>
    </on-error-propagate>
</error-handler>
```

## Best Practices

1. **Reuse Client Instances**: Create `GlueSchemaRegistryMuleModule` once and reuse it across flows
2. **Use Secure Properties**: Store AWS credentials in MuleSoft secure properties
3. **Error Handling**: Always implement proper error handling for schema registry operations
4. **Connection Pooling**: The client manages connections automatically, but avoid creating too many instances
5. **Schema Validation**: Ensure schemas exist in the registry before using them

## Troubleshooting

### Issue: ClassNotFoundException for MuleSoft classes

**Solution**: This is expected in standalone mode. The client uses reflection to detect MuleSoft environment and gracefully falls back to standard exceptions.

### Issue: Credentials not found

**Solution**: 
1. Verify credentials are configured in secure properties
2. Check environment variables are set correctly
3. Verify AWS credential chain is working

### Issue: Schema not found

**Solution**:
1. Verify schema name is correct
2. Check schema exists in the registry
3. Verify registry name is correct
4. Check AWS region matches the registry region

## Examples

See the `examples/mulesoft/` directory for complete examples:

- `mule-config.xml`: Complete MuleSoft flow configuration
- `dataweave-examples.dwl`: DataWeave script examples

## Support

For issues or questions:
1. Check the main README.md for general usage
2. Review the Java API documentation
3. Check MuleSoft integration examples

