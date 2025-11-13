/**
 * DataWeave Examples for Glue Schema Registry
 * 
 * These examples demonstrate how to use the Glue Schema Registry client
 * from DataWeave scripts in MuleSoft.
 * 
 * Configuration Requirements:
 * ===========================
 * 
 * Before using these examples, ensure you have configured:
 * 
 * 1. AWS Credentials (one of the following):
 *    - MuleSoft Secure Properties: secure::aws.access.key.id and secure::aws.secret.access.key
 *    - System Properties: aws.access.key.id and aws.secret.access.key
 *    - Environment Variables: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
 * 
 * 2. Schema Registry Configuration (one of the following):
 *    - MuleSoft Secure Properties: secure::glue.registry.name and secure::aws.region
 *    - System Properties: glue.registry.name and aws.region
 *    - Environment Variables: GLUE_REGISTRY_NAME and AWS_REGION
 * 
 * The GlueSchemaRegistryMuleModule.create() method will automatically read
 * from these configuration sources in the order listed above.
 */

/**
 * Example 1: Import and use GlueSchemaRegistryMuleModule in DataWeave
 */
%dw 2.0
import java!com::aws::glue::schema::registry::mule::GlueSchemaRegistryMuleModule
import java!com::aws::glue::schema::registry::implementation::model::SalesforceAudit
output application/json
---
{
    // Create module instance (reads from MuleSoft configuration)
    module: GlueSchemaRegistryMuleModule::create(),
    
    // Create audit event
    auditEvent: {
        eventId: "event-12345",
        eventName: "UserLogin",
        timestamp: now() as Number,
        eventDetails: "User logged in successfully"
    },
    
    // Serialize to Avro bytes
    avroBytes: module.serializeAvro("SalesforceAudit", auditEvent),
    
    // Serialize to JSON bytes
    jsonBytes: module.serializeJson("SalesAuditJSON", auditEvent)
}

/**
 * Example 2: Serialize and deserialize in DataWeave
 */
%dw 2.0
import java!com::aws::glue::schema::registry::mule::GlueSchemaRegistryMuleModule
import java!com::aws::glue::schema::registry::implementation::model::SalesforceAudit
output application/json
---
do {
    // Create module
    var module = GlueSchemaRegistryMuleModule::create()
    
    // Create audit event
    var auditEvent = {
        eventId: "event-67890",
        eventName: "DataAccess",
        timestamp: now() as Number,
        eventDetails: "User accessed customer data"
    }
    
    // Serialize to Avro
    var serialized = module.serializeAvro("SalesforceAudit", auditEvent)
    
    // Deserialize from Avro
    var deserialized = module.deserializeAvro("SalesforceAudit", serialized)
    
    // Return result
    {
        original: auditEvent,
        serializedSize: sizeOf(serialized),
        deserialized: {
            eventId: deserialized.eventId,
            eventName: deserialized.eventName,
            timestamp: deserialized.timestamp,
            eventDetails: deserialized.eventDetails
        }
    }
}

/**
 * Example 3: Using with MuleSoft flow variables
 */
%dw 2.0
import java!com::aws::glue::schema::registry::mule::GlueSchemaRegistryMuleModule
output application/json
---
{
    // Get module from flow variable (if created in previous step)
    module: vars.muleModule default GlueSchemaRegistryMuleModule::create(),
    
    // Serialize incoming payload
    serialized: module.serializeAvro(
        vars.schemaName default "SalesforceAudit",
        payload
    )
}

/**
 * Example 4: Error handling in DataWeave
 */
%dw 2.0
import java!com::aws::glue::schema::registry::mule::GlueSchemaRegistryMuleModule
output application/json
---
try {
    var module = GlueSchemaRegistryMuleModule::create()
    var serialized = module.serializeAvro("SalesforceAudit", payload)
    {
        success: true,
        data: serialized,
        size: sizeOf(serialized)
    }
} catch (e) {
    {
        success: false,
        error: e.message,
        errorType: e.class.simpleName
    }
}

/**
 * Example 5: Complete End-to-End: JSON Payload to Avro Serialization
 * ===================================================================
 * This example shows the complete flow:
 * 1. Receives JSON string payload
 * 2. Converts JSON to SalesforceAudit using utility method
 * 3. Serializes to Avro using Glue Schema Registry
 */
%dw 2.0
import java!com::aws::glue::schema::registry::mule::GlueSchemaRegistryMuleModule
output application/json
---
do {
    // Create module instance (reads AWS credentials and config from MuleSoft properties)
    var module = GlueSchemaRegistryMuleModule::create()
    
    // Step 1: Convert incoming JSON string to SalesforceAudit object
    // This utility method doesn't require schema registry access
    var auditEvent = module.fromJsonString(payload as String)
    
    // Step 2: Serialize to Avro using Glue Schema Registry
    var serializedAvro = module.serializeAvro("SalesforceAudit", auditEvent)
    
    // Return result with metadata
    {
        success: true,
        message: "JSON payload successfully converted and serialized to Avro",
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

/**
 * Example 6: JSON Payload to JSON Serialization (using Schema Registry)
 * =====================================================================
 * Similar to Example 5, but serializes to JSON format instead of Avro
 */
%dw 2.0
import java!com::aws::glue::schema::registry::mule::GlueSchemaRegistryMuleModule
output application/json
---
do {
    var module = GlueSchemaRegistryMuleModule::create()
    
    // Convert JSON string to SalesforceAudit
    var auditEvent = module.fromJsonString(payload as String)
    
    // Serialize to JSON using Glue Schema Registry
    var serializedJson = module.serializeJson("SalesAuditJSON", auditEvent)
    
    {
        success: true,
        message: "JSON payload successfully converted and serialized to JSON",
        originalEvent: {
            eventId: auditEvent.eventId,
            eventName: auditEvent.eventName,
            timestamp: auditEvent.timestamp
        },
        serializedSize: sizeOf(serializedJson),
        serializedData: serializedJson,
        format: "JSON",
        schemaName: "SalesAuditJSON"
    }
}

/**
 * Example 7: Using fromJsonBytes() with byte array payload
 * ========================================================
 * This example shows how to convert JSON bytes to SalesforceAudit
 */
%dw 2.0
import java!com::aws::glue::schema::registry::mule::GlueSchemaRegistryMuleModule
output application/json
---
do {
    var module = GlueSchemaRegistryMuleModule::create()
    
    // Convert JSON bytes to SalesforceAudit
    var auditEvent = module.fromJsonBytes(payload as Array)
    
    // Serialize to Avro
    var serialized = module.serializeAvro("SalesforceAudit", auditEvent)
    
    {
        success: true,
        eventId: auditEvent.eventId,
        serializedSize: sizeOf(serialized)
    }
}

/**
 * Example 8: Error handling with JSON conversion
 * ================================================
 * Shows how to handle errors when converting JSON payloads
 */
%dw 2.0
import java!com::aws::glue::schema::registry::mule::GlueSchemaRegistryMuleModule
output application/json
---
try {
    var module = GlueSchemaRegistryMuleModule::create()
    
    // Try to convert JSON string
    var auditEvent = module.fromJsonString(payload as String)
    
    // Try to serialize
    var serialized = module.serializeAvro("SalesforceAudit", auditEvent)
    
    {
        success: true,
        message: "Successfully processed JSON payload",
        serializedSize: sizeOf(serialized)
    }
} catch (e) {
    {
        success: false,
        error: e.message,
        errorType: e.class.simpleName,
        // Check if it's a JSON parsing error or schema registry error
        isJsonError: e.message contains "JSON",
        isSchemaError: e.message contains "Schema"
    }
}

