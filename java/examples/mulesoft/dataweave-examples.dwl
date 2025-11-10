/**
 * DataWeave Examples for Glue Schema Registry
 * 
 * These examples demonstrate how to use the Glue Schema Registry client
 * from DataWeave scripts in MuleSoft.
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

