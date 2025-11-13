package com.aws.glue.schema.registry.implementation;

import com.aws.glue.schema.registry.client.GlueSchemaRegistryClient;
import com.aws.glue.schema.registry.client.SchemaRegistryException;
import com.aws.glue.schema.registry.implementation.model.SalesforceAudit;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.charset.StandardCharsets;

/**
 * Utility class for serializing and deserializing SalesforceAudit objects
 * using JSON schemas retrieved from Glue Schema Registry.
 * Provides static methods for backward compatibility.
 */
public class JsonSerializer {
    
    private static final Logger logger = LoggerFactory.getLogger(JsonSerializer.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();
    
    /**
     * Serializes a SalesforceAudit object to JSON format using the schema from Glue Schema Registry.
     * 
     * @param client GlueSchemaRegistryClient instance
     * @param schemaName Name of the schema in the registry
     * @param auditEvent SalesforceAudit object to serialize
     * @return Serialized byte array (JSON)
     * @throws SchemaRegistryException if serialization fails
     */
    public static byte[] serialize(GlueSchemaRegistryClient client, String schemaName, SalesforceAudit auditEvent) {
        logger.debug("Starting JSON serialization - schema: {}, eventId: {}", 
                schemaName, auditEvent != null ? auditEvent.getEventId() : "null");
        try {
            // Get schema definition from Glue Schema Registry
            var schemaResponse = client.getSchema(schemaName);
            // Get the latest schema version to get the schema definition
            Long latestVersion = schemaResponse.latestSchemaVersion();
            logger.debug("Retrieved schema version {} for schema {}", latestVersion, schemaName);
            var schemaVersionResponse = client.getSchemaVersion(schemaName, latestVersion);
            @SuppressWarnings("unused")
            String schemaDefinition = schemaVersionResponse.schemaDefinition();
            
            // Note: In a production environment, you might want to validate the JSON
            // against the schema definition before serialization using a JSON Schema validator
            // For now, we rely on Jackson's serialization and Glue's compatibility checking
            
            // Serialize to JSON bytes
            String json = objectMapper.writeValueAsString(auditEvent);
            byte[] result = json.getBytes(StandardCharsets.UTF_8);
            logger.debug("JSON serialization completed - schema: {}, size: {} bytes", schemaName, result.length);
            return result;
            
        } catch (Exception e) {
            logger.error("JSON serialization failed - schema: {}, error: {}", schemaName, e.getMessage(), e);
            throw new SchemaRegistryException("Failed to serialize SalesforceAudit to JSON", e);
        }
    }
    
    /**
     * Deserializes JSON data to a SalesforceAudit object using the schema from Glue Schema Registry.
     * 
     * @param client GlueSchemaRegistryClient instance
     * @param schemaName Name of the schema in the registry
     * @param data Serialized JSON byte array
     * @return Deserialized SalesforceAudit object
     * @throws SchemaRegistryException if deserialization fails
     */
    public static SalesforceAudit deserialize(GlueSchemaRegistryClient client, String schemaName, byte[] data) {
        logger.debug("Starting JSON deserialization - schema: {}, data size: {} bytes", 
                schemaName, data != null ? data.length : 0);
        try {
            // Get schema definition from Glue Schema Registry
            var schemaResponse = client.getSchema(schemaName);
            // Get the latest schema version to get the schema definition
            Long latestVersion = schemaResponse.latestSchemaVersion();
            logger.debug("Retrieved schema version {} for schema {}", latestVersion, schemaName);
            var schemaVersionResponse = client.getSchemaVersion(schemaName, latestVersion);
            @SuppressWarnings("unused")
            String schemaDefinition = schemaVersionResponse.schemaDefinition();
            
            // Note: In a production environment, you might want to validate the JSON
            // against the schema definition after deserialization using a JSON Schema validator
            
            // Deserialize from JSON bytes
            String json = new String(data, StandardCharsets.UTF_8);
            SalesforceAudit result = objectMapper.readValue(json, SalesforceAudit.class);
            logger.debug("JSON deserialization completed - schema: {}, eventId: {}", 
                    schemaName, result != null ? result.getEventId() : "null");
            return result;
            
        } catch (Exception e) {
            logger.error("JSON deserialization failed - schema: {}, error: {}", schemaName, e.getMessage(), e);
            throw new SchemaRegistryException("Failed to deserialize JSON to SalesforceAudit", e);
        }
    }
    
    /**
     * Converts a JSON string to a SalesforceAudit object.
     * This is a utility method that does not require schema registry access.
     * Useful for converting JSON payloads directly to audit objects.
     * 
     * @param jsonString JSON string representation of SalesforceAudit
     * @return Deserialized SalesforceAudit object
     * @throws SchemaRegistryException if deserialization fails
     */
    public static SalesforceAudit fromJsonString(String jsonString) {
        logger.debug("Converting JSON string to SalesforceAudit - length: {} chars", 
                jsonString != null ? jsonString.length() : 0);
        try {
            if (jsonString == null || jsonString.trim().isEmpty()) {
                throw new IllegalArgumentException("JSON string cannot be null or empty");
            }
            SalesforceAudit result = objectMapper.readValue(jsonString, SalesforceAudit.class);
            logger.debug("Successfully converted JSON string to SalesforceAudit - eventId: {}", 
                    result != null ? result.getEventId() : "null");
            return result;
        } catch (Exception e) {
            logger.error("Failed to convert JSON string to SalesforceAudit - error: {}", e.getMessage(), e);
            throw new SchemaRegistryException("Failed to convert JSON string to SalesforceAudit", e);
        }
    }
    
    /**
     * Converts a JSON byte array to a SalesforceAudit object.
     * This is a utility method that does not require schema registry access.
     * Useful for converting JSON payloads directly to audit objects.
     * 
     * @param jsonBytes JSON byte array representation of SalesforceAudit
     * @return Deserialized SalesforceAudit object
     * @throws SchemaRegistryException if deserialization fails
     */
    public static SalesforceAudit fromJsonBytes(byte[] jsonBytes) {
        logger.debug("Converting JSON bytes to SalesforceAudit - size: {} bytes", 
                jsonBytes != null ? jsonBytes.length : 0);
        try {
            if (jsonBytes == null || jsonBytes.length == 0) {
                throw new IllegalArgumentException("JSON bytes cannot be null or empty");
            }
            String jsonString = new String(jsonBytes, StandardCharsets.UTF_8);
            SalesforceAudit result = objectMapper.readValue(jsonString, SalesforceAudit.class);
            logger.debug("Successfully converted JSON bytes to SalesforceAudit - eventId: {}", 
                    result != null ? result.getEventId() : "null");
            return result;
        } catch (Exception e) {
            logger.error("Failed to convert JSON bytes to SalesforceAudit - error: {}", e.getMessage(), e);
            throw new SchemaRegistryException("Failed to convert JSON bytes to SalesforceAudit", e);
        }
    }
}
