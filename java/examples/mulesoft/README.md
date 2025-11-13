# MuleSoft Integration Guide for AWS Glue Schema Registry

This guide provides complete examples for integrating AWS Glue Schema Registry with MuleSoft applications, including configuration, credential management, and end-to-end JSON payload processing.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Configuration Setup](#configuration-setup)
3. [Complete End-to-End Example](#complete-end-to-end-example)
4. [API Reference](#api-reference)
5. [Error Handling](#error-handling)

## Prerequisites

1. **Add the JAR dependency** to your MuleSoft project:
   - Add `schema-registry-client-1.0.0-SNAPSHOT-all.jar` to your MuleSoft project's classpath
   - Or add it as a Maven dependency in your `pom.xml`

2. **AWS Glue Schema Registry** must be set up with schemas:
   - Create a schema registry in AWS Glue
   - Register schemas (e.g., "SalesforceAudit" for Avro, "SalesAuditJSON" for JSON)

## Configuration Setup

The `GlueSchemaRegistryMuleModule` automatically reads configuration from multiple sources in the following order:

1. MuleSoft Secure Properties (recommended for production)
2. MuleSoft Application Properties
3. System Properties
4. Environment Variables
5. Default values

### Option 1: MuleSoft Secure Properties (Recommended)

In your MuleSoft application's secure properties file (`secure.properties` or via Anypoint Platform), add:

```properties
# AWS Credentials
secure::aws.access.key.id=YOUR_AWS_ACCESS_KEY_ID
secure::aws.secret.access.key=YOUR_AWS_SECRET_ACCESS_KEY

# Schema Registry Configuration
secure::glue.registry.name=your-glue-schema-registry-name
secure::aws.region=us-east-1
```

**Note:** Secure properties are encrypted and are the recommended approach for production environments.

### Option 2: System Properties

Set these as system properties in your MuleSoft runtime:

```properties
glue.registry.name=your-glue-schema-registry-name
aws.region=us-east-1
aws.access.key.id=YOUR_AWS_ACCESS_KEY_ID
aws.secret.access.key=YOUR_AWS_SECRET_ACCESS_KEY
```

### Option 3: Environment Variables

Set these environment variables:

```bash
export GLUE_REGISTRY_NAME=your-glue-schema-registry-name
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
```

### Option 4: Using Default Credentials Provider

If you don't provide explicit credentials, the module will use AWS SDK's default credential provider chain:
- Environment variables
- Java system properties
- Web identity token from AWS STS
- Shared credentials file (`~/.aws/credentials`)
- EC2 instance profile credentials (if running on EC2)

## Complete End-to-End Example

### Example: JSON Payload to Avro Serialization

This example demonstrates the complete flow:
1. Receives JSON payload via HTTP POST
2. Converts JSON string to `SalesforceAudit` object using utility method
3. Serializes to Avro format using Glue Schema Registry
4. Returns serialized bytes with metadata

#### Mule Flow Configuration

```xml
<flow name="jsonToAvroSerializationFlow">
    <http:listener config-ref="HTTP_Listener_config" 
                   path="/audit/json-to-avro"
                   allowedMethods="POST"/>
    
    <!-- Step 1: Create module instance (reads config from properties) -->
    <java:new class="com.aws.glue.schema.registry.mule.GlueSchemaRegistryMuleModule"
              constructor="create()"
              targetVariable="muleModule"/>
    
    <!-- Step 2: Convert JSON string to SalesforceAudit object -->
    <java:invoke class="com.aws.glue.schema.registry.mule.GlueSchemaRegistryMuleModule"
                 method="fromJsonString(java.lang.String)"
                 instance="#[vars.muleModule]"
                 arguments="#[payload]"
                 targetVariable="auditEvent"/>
    
    <!-- Step 3: Serialize to Avro using Glue Schema Registry -->
    <java:invoke class="com.aws.glue.schema.registry.mule.GlueSchemaRegistryMuleModule"
                 method="serializeAvro(java.lang.String, com.aws.glue.schema.registry.implementation.model.SalesforceAudit)"
                 instance="#[vars.muleModule]"
                 arguments="#['SalesforceAudit', vars.auditEvent]"
                 targetVariable="serializedAvro"/>
    
    <!-- Step 4: Return response -->
    <ee:transform>
        <ee:message>
            <ee:set-payload>
                <![CDATA[%dw 2.0
                output application/json
                ---
                {
                    success: true,
                    message: "JSON payload successfully converted and serialized to Avro",
                    originalEvent: {
                        eventId: vars.auditEvent.eventId,
                        eventName: vars.auditEvent.eventName,
                        timestamp: vars.auditEvent.timestamp
                    },
                    serializedSize: sizeOf(vars.serializedAvro),
                    serializedData: vars.serializedAvro,
                    format: "AVRO",
                    schemaName: "SalesforceAudit"
                }]]>
            </ee:set-payload>
        </ee:message>
    </ee:transform>
    
    <error-handler>
        <on-error-propagate type="JAVA:EXCEPTION" enableNotifications="true" logException="true">
            <ee:transform>
                <ee:message>
                    <ee:set-payload>
                        <![CDATA[%dw 2.0
                        output application/json
                        ---
                        {
                            success: false,
                            error: error.message,
                            errorType: error.class.simpleName,
                            timestamp: now()
                        }]]>
                    </ee:set-payload>
                </ee:message>
            </ee:transform>
        </on-error-propagate>
    </error-handler>
</flow>
```

#### Sample Request

```bash
curl -X POST http://localhost:8081/audit/json-to-avro \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "event-12345",
    "eventName": "UserLogin",
    "timestamp": 1704067200000,
    "eventDetails": "User logged in successfully"
  }'
```

#### Sample Response

```json
{
  "success": true,
  "message": "JSON payload successfully converted and serialized to Avro",
  "originalEvent": {
    "eventId": "event-12345",
    "eventName": "UserLogin",
    "timestamp": 1704067200000
  },
  "serializedSize": 71,
  "serializedData": [/* Avro binary data */],
  "format": "AVRO",
  "schemaName": "SalesforceAudit"
}
```

### DataWeave Example

You can also use DataWeave to process JSON payloads:

```dataweave
%dw 2.0
import java!com::aws::glue::schema::registry::mule::GlueSchemaRegistryMuleModule
output application/json
---
do {
    // Create module instance (reads AWS credentials and config from MuleSoft properties)
    var module = GlueSchemaRegistryMuleModule::create()
    
    // Step 1: Convert incoming JSON string to SalesforceAudit object
    var auditEvent = module.fromJsonString(payload as String)
    
    // Step 2: Serialize to Avro using Glue Schema Registry
    var serializedAvro = module.serializeAvro("SalesforceAudit", auditEvent)
    
    // Return result
    {
        success: true,
        originalEvent: {
            eventId: auditEvent.eventId,
            eventName: auditEvent.eventName,
            timestamp: auditEvent.timestamp,
            eventDetails: auditEvent.eventDetails
        },
        serializedSize: sizeOf(serializedAvro),
        serializedData: serializedAvro,
        format: "AVRO",
        schemaName: "SalesforceAudit"
    }
}
```

## API Reference

### GlueSchemaRegistryMuleModule Methods

#### Factory Methods

- `create()` - Creates module instance using MuleSoft configuration properties
- `create(GlueSchemaRegistryConfig config)` - Creates module with explicit configuration
- `create(GlueSchemaRegistryClient client)` - Creates module with existing client

#### JSON Conversion Methods (No Schema Registry Required)

- `fromJsonString(String jsonString)` - Converts JSON string to `SalesforceAudit`
- `fromJsonBytes(byte[] jsonBytes)` - Converts JSON byte array to `SalesforceAudit`

#### Serialization Methods (Requires Schema Registry)

- `serializeAvro(String schemaName, SalesforceAudit auditEvent)` - Serializes to Avro format
- `serializeJson(String schemaName, SalesforceAudit auditEvent)` - Serializes to JSON format

#### Deserialization Methods (Requires Schema Registry)

- `deserializeAvro(String schemaName, byte[] data)` - Deserializes Avro data
- `deserializeJson(String schemaName, byte[] data)` - Deserializes JSON data

## Error Handling

All methods throw `RuntimeException` (MuleSoft-compatible) on errors. Common error scenarios:

1. **Invalid JSON**: When `fromJsonString()` or `fromJsonBytes()` receives invalid JSON
2. **Schema Not Found**: When the specified schema doesn't exist in the registry
3. **AWS Credentials Error**: When AWS credentials are invalid or missing
4. **Network Errors**: When unable to connect to AWS Glue service

Example error response:

```json
{
  "success": false,
  "error": "[SCHEMA_NOT_FOUND] Schema not found in registry: Schema not found",
  "errorType": "RuntimeException",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## Best Practices

1. **Use Secure Properties** for AWS credentials in production
2. **Cache Module Instances** - Create the module once and reuse it (it's thread-safe)
3. **Handle Errors Gracefully** - Always include error handlers in your flows
4. **Logging** - The module includes comprehensive logging at DEBUG, INFO, and ERROR levels
5. **Schema Names** - Use consistent schema names across your application

## Troubleshooting

### Issue: "Schema not found in registry"

**Solution**: Ensure the schema exists in your AWS Glue Schema Registry and the name matches exactly.

### Issue: "AWS credentials not found"

**Solution**: Verify your credentials are configured in one of the supported locations (secure properties, system properties, or environment variables).

### Issue: "Region not specified"

**Solution**: Set the `aws.region` property or `AWS_REGION` environment variable to the region where your schema registry is located.

## Additional Examples

See the following files for more examples:
- `mule-config.xml` - Complete Mule flow configurations
- `dataweave-examples.dwl` - DataWeave script examples

