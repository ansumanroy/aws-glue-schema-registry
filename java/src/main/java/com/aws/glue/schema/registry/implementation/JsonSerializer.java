package com.aws.glue.schema.registry.implementation;

import com.aws.glue.schema.registry.client.GlueSchemaRegistryClient;
import com.aws.glue.schema.registry.client.SchemaRegistryException;
import com.aws.glue.schema.registry.implementation.model.SalesforceAudit;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.nio.charset.StandardCharsets;

/**
 * Utility class for serializing and deserializing SalesforceAudit objects
 * using JSON schemas retrieved from Glue Schema Registry.
 * Provides static methods for backward compatibility.
 */
public class JsonSerializer {
    
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
        try {
            // Get schema definition from Glue Schema Registry
            var schemaResponse = client.getSchema(schemaName);
            // Get the latest schema version to get the schema definition
            Long latestVersion = schemaResponse.latestSchemaVersion();
            var schemaVersionResponse = client.getSchemaVersion(schemaName, latestVersion);
            @SuppressWarnings("unused")
            String schemaDefinition = schemaVersionResponse.schemaDefinition();
            
            // Note: In a production environment, you might want to validate the JSON
            // against the schema definition before serialization using a JSON Schema validator
            // For now, we rely on Jackson's serialization and Glue's compatibility checking
            
            // Serialize to JSON bytes
            String json = objectMapper.writeValueAsString(auditEvent);
            return json.getBytes(StandardCharsets.UTF_8);
            
        } catch (Exception e) {
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
        try {
            // Get schema definition from Glue Schema Registry
            var schemaResponse = client.getSchema(schemaName);
            // Get the latest schema version to get the schema definition
            Long latestVersion = schemaResponse.latestSchemaVersion();
            var schemaVersionResponse = client.getSchemaVersion(schemaName, latestVersion);
            @SuppressWarnings("unused")
            String schemaDefinition = schemaVersionResponse.schemaDefinition();
            
            // Note: In a production environment, you might want to validate the JSON
            // against the schema definition after deserialization using a JSON Schema validator
            
            // Deserialize from JSON bytes
            String json = new String(data, StandardCharsets.UTF_8);
            return objectMapper.readValue(json, SalesforceAudit.class);
            
        } catch (Exception e) {
            throw new SchemaRegistryException("Failed to deserialize JSON to SalesforceAudit", e);
        }
    }
}
