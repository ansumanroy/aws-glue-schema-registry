package com.aws.glue.schema.registry.mule;

import com.aws.glue.schema.registry.client.GlueSchemaRegistryClient;
import com.aws.glue.schema.registry.client.SchemaRegistryException;
import com.aws.glue.schema.registry.config.GlueSchemaRegistryConfig;
import com.aws.glue.schema.registry.config.MuleSoftConfigProvider;
import com.aws.glue.schema.registry.implementation.AvroSerializer;
import com.aws.glue.schema.registry.implementation.JsonSerializer;
import com.aws.glue.schema.registry.implementation.model.SalesforceAudit;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * MuleSoft module wrapper for Glue Schema Registry operations.
 * Provides MuleSoft-friendly operations that integrate with MuleSoft's
 * error handling and data transformation systems.
 * 
 * Note: This class uses reflection to avoid hard dependencies on MuleSoft
 * classes when used in standalone mode. MuleSoft-specific functionality
 * is only available when MuleSoft runtime is present.
 */
public class GlueSchemaRegistryMuleModule {
    
    private static final Logger logger = LogManager.getLogger(GlueSchemaRegistryMuleModule.class);
    
    private final GlueSchemaRegistryClient client;
    
    /**
     * Creates a new GlueSchemaRegistryMuleModule using MuleSoft configuration.
     * Reads configuration from MuleSoft secure properties.
     * 
     * @return GlueSchemaRegistryMuleModule instance
     */
    public static GlueSchemaRegistryMuleModule create() {
        logger.debug("Creating GlueSchemaRegistryMuleModule from MuleSoft properties");
        GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties();
        GlueSchemaRegistryMuleModule module = new GlueSchemaRegistryMuleModule(config);
        logger.info("GlueSchemaRegistryMuleModule created with registry: {}", config.getRegistryName());
        return module;
    }
    
    /**
     * Creates a new GlueSchemaRegistryMuleModule with explicit configuration.
     * 
     * @param config GlueSchemaRegistryConfig
     * @return GlueSchemaRegistryMuleModule instance
     */
    public static GlueSchemaRegistryMuleModule create(GlueSchemaRegistryConfig config) {
        logger.debug("Creating GlueSchemaRegistryMuleModule with explicit configuration");
        GlueSchemaRegistryMuleModule module = new GlueSchemaRegistryMuleModule(config);
        logger.info("GlueSchemaRegistryMuleModule created with registry: {}", config.getRegistryName());
        return module;
    }
    
    /**
     * Creates a new GlueSchemaRegistryMuleModule with a client instance.
     * 
     * @param client GlueSchemaRegistryClient instance
     * @return GlueSchemaRegistryMuleModule instance
     */
    public static GlueSchemaRegistryMuleModule create(GlueSchemaRegistryClient client) {
        logger.debug("Creating GlueSchemaRegistryMuleModule with existing client");
        GlueSchemaRegistryMuleModule module = new GlueSchemaRegistryMuleModule(client);
        logger.info("GlueSchemaRegistryMuleModule created with existing client");
        return module;
    }
    
    /**
     * Private constructor using configuration.
     */
    private GlueSchemaRegistryMuleModule(GlueSchemaRegistryConfig config) {
        logger.debug("Initializing GlueSchemaRegistryMuleModule with config - registry: {}, region: {}", 
                config.getRegistryName(), config.getRegion());
        this.client = new GlueSchemaRegistryClient(config);
    }
    
    /**
     * Private constructor using client.
     */
    private GlueSchemaRegistryMuleModule(GlueSchemaRegistryClient client) {
        logger.debug("Initializing GlueSchemaRegistryMuleModule with existing client");
        this.client = client;
    }
    
    /**
     * Serializes a SalesforceAudit object to Avro format.
     * 
     * @param schemaName Name of the schema in the registry
     * @param auditEvent SalesforceAudit object to serialize
     * @return Serialized byte array
     * @throws RuntimeException MuleSoft-compatible exception if serialization fails
     */
    public byte[] serializeAvro(String schemaName, SalesforceAudit auditEvent) {
        logger.debug("Serializing SalesforceAudit to Avro format - schema: {}, eventId: {}", 
                schemaName, auditEvent != null ? auditEvent.getEventId() : "null");
        try {
            byte[] result = AvroSerializer.serialize(client, schemaName, auditEvent);
            logger.info("Successfully serialized SalesforceAudit to Avro - schema: {}, size: {} bytes", 
                    schemaName, result.length);
            return result;
        } catch (SchemaRegistryException e) {
            logger.error("Failed to serialize SalesforceAudit to Avro - schema: {}, error: {}", 
                    schemaName, e.getMessage(), e);
            throw e.toMuleSoftException();
        }
    }
    
    /**
     * Deserializes Avro data to a SalesforceAudit object.
     * 
     * @param schemaName Name of the schema in the registry
     * @param data Serialized byte array
     * @return Deserialized SalesforceAudit object
     * @throws RuntimeException MuleSoft-compatible exception if deserialization fails
     */
    public SalesforceAudit deserializeAvro(String schemaName, byte[] data) {
        logger.debug("Deserializing Avro data to SalesforceAudit - schema: {}, data size: {} bytes", 
                schemaName, data != null ? data.length : 0);
        try {
            SalesforceAudit result = AvroSerializer.deserialize(client, schemaName, data);
            logger.info("Successfully deserialized Avro data to SalesforceAudit - schema: {}, eventId: {}", 
                    schemaName, result != null ? result.getEventId() : "null");
            return result;
        } catch (SchemaRegistryException e) {
            logger.error("Failed to deserialize Avro data to SalesforceAudit - schema: {}, error: {}", 
                    schemaName, e.getMessage(), e);
            throw e.toMuleSoftException();
        }
    }
    
    /**
     * Serializes a SalesforceAudit object to JSON format.
     * 
     * @param schemaName Name of the schema in the registry
     * @param auditEvent SalesforceAudit object to serialize
     * @return Serialized byte array (JSON)
     * @throws RuntimeException MuleSoft-compatible exception if serialization fails
     */
    public byte[] serializeJson(String schemaName, SalesforceAudit auditEvent) {
        logger.debug("Serializing SalesforceAudit to JSON format - schema: {}, eventId: {}", 
                schemaName, auditEvent != null ? auditEvent.getEventId() : "null");
        try {
            byte[] result = JsonSerializer.serialize(client, schemaName, auditEvent);
            logger.info("Successfully serialized SalesforceAudit to JSON - schema: {}, size: {} bytes", 
                    schemaName, result.length);
            return result;
        } catch (SchemaRegistryException e) {
            logger.error("Failed to serialize SalesforceAudit to JSON - schema: {}, error: {}", 
                    schemaName, e.getMessage(), e);
            throw e.toMuleSoftException();
        }
    }
    
    /**
     * Deserializes JSON data to a SalesforceAudit object.
     * 
     * @param schemaName Name of the schema in the registry
     * @param data Serialized JSON byte array
     * @return Deserialized SalesforceAudit object
     * @throws RuntimeException MuleSoft-compatible exception if deserialization fails
     */
    public SalesforceAudit deserializeJson(String schemaName, byte[] data) {
        logger.debug("Deserializing JSON data to SalesforceAudit - schema: {}, data size: {} bytes", 
                schemaName, data != null ? data.length : 0);
        try {
            SalesforceAudit result = JsonSerializer.deserialize(client, schemaName, data);
            logger.info("Successfully deserialized JSON data to SalesforceAudit - schema: {}, eventId: {}", 
                    schemaName, result != null ? result.getEventId() : "null");
            return result;
        } catch (SchemaRegistryException e) {
            logger.error("Failed to deserialize JSON data to SalesforceAudit - schema: {}, error: {}", 
                    schemaName, e.getMessage(), e);
            throw e.toMuleSoftException();
        }
    }
    
    /**
     * Converts a JSON string to a SalesforceAudit object.
     * This is a utility method that does not require schema registry access.
     * Useful for converting JSON payloads directly to audit objects.
     * 
     * @param jsonString JSON string representation of SalesforceAudit
     * @return Deserialized SalesforceAudit object
     * @throws RuntimeException MuleSoft-compatible exception if conversion fails
     */
    public SalesforceAudit fromJsonString(String jsonString) {
        logger.debug("Converting JSON string to SalesforceAudit via utility method");
        try {
            SalesforceAudit result = JsonSerializer.fromJsonString(jsonString);
            logger.info("Successfully converted JSON string to SalesforceAudit - eventId: {}", 
                    result != null ? result.getEventId() : "null");
            return result;
        } catch (SchemaRegistryException e) {
            logger.error("Failed to convert JSON string to SalesforceAudit - error: {}", e.getMessage(), e);
            throw e.toMuleSoftException();
        }
    }
    
    /**
     * Converts a JSON byte array to a SalesforceAudit object.
     * This is a utility method that does not require schema registry access.
     * Useful for converting JSON payloads directly to audit objects.
     * 
     * @param jsonBytes JSON byte array representation of SalesforceAudit
     * @return Deserialized SalesforceAudit object
     * @throws RuntimeException MuleSoft-compatible exception if conversion fails
     */
    public SalesforceAudit fromJsonBytes(byte[] jsonBytes) {
        logger.debug("Converting JSON bytes to SalesforceAudit via utility method - size: {} bytes", 
                jsonBytes != null ? jsonBytes.length : 0);
        try {
            SalesforceAudit result = JsonSerializer.fromJsonBytes(jsonBytes);
            logger.info("Successfully converted JSON bytes to SalesforceAudit - eventId: {}", 
                    result != null ? result.getEventId() : "null");
            return result;
        } catch (SchemaRegistryException e) {
            logger.error("Failed to convert JSON bytes to SalesforceAudit - error: {}", e.getMessage(), e);
            throw e.toMuleSoftException();
        }
    }
    
    /**
     * Gets the underlying GlueSchemaRegistryClient.
     * 
     * @return GlueSchemaRegistryClient instance
     */
    public GlueSchemaRegistryClient getClient() {
        return client;
    }
    
    /**
     * Closes the underlying client and releases resources.
     * Note: GlueClient doesn't implement Closeable in AWS SDK v2,
     * but this method is provided for future compatibility.
     */
    public void close() {
        logger.debug("Closing GlueSchemaRegistryMuleModule");
        // AWS SDK v2 clients don't need explicit closing in most cases
        // This method is provided for API consistency
        logger.info("GlueSchemaRegistryMuleModule closed");
    }
}

