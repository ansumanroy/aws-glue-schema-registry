package com.aws.glue.schema.registry.mule;

import com.aws.glue.schema.registry.client.GlueSchemaRegistryClient;
import com.aws.glue.schema.registry.client.SchemaRegistryException;
import com.aws.glue.schema.registry.config.GlueSchemaRegistryConfig;
import com.aws.glue.schema.registry.config.MuleSoftConfigProvider;
import com.aws.glue.schema.registry.implementation.AvroSerializer;
import com.aws.glue.schema.registry.implementation.JsonSerializer;
import com.aws.glue.schema.registry.implementation.model.SalesforceAudit;

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
    
    private final GlueSchemaRegistryClient client;
    
    /**
     * Creates a new GlueSchemaRegistryMuleModule using MuleSoft configuration.
     * Reads configuration from MuleSoft secure properties.
     * 
     * @return GlueSchemaRegistryMuleModule instance
     */
    public static GlueSchemaRegistryMuleModule create() {
        GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties();
        return new GlueSchemaRegistryMuleModule(config);
    }
    
    /**
     * Creates a new GlueSchemaRegistryMuleModule with explicit configuration.
     * 
     * @param config GlueSchemaRegistryConfig
     * @return GlueSchemaRegistryMuleModule instance
     */
    public static GlueSchemaRegistryMuleModule create(GlueSchemaRegistryConfig config) {
        return new GlueSchemaRegistryMuleModule(config);
    }
    
    /**
     * Creates a new GlueSchemaRegistryMuleModule with a client instance.
     * 
     * @param client GlueSchemaRegistryClient instance
     * @return GlueSchemaRegistryMuleModule instance
     */
    public static GlueSchemaRegistryMuleModule create(GlueSchemaRegistryClient client) {
        return new GlueSchemaRegistryMuleModule(client);
    }
    
    /**
     * Private constructor using configuration.
     */
    private GlueSchemaRegistryMuleModule(GlueSchemaRegistryConfig config) {
        this.client = new GlueSchemaRegistryClient(config);
    }
    
    /**
     * Private constructor using client.
     */
    private GlueSchemaRegistryMuleModule(GlueSchemaRegistryClient client) {
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
        try {
            return AvroSerializer.serialize(client, schemaName, auditEvent);
        } catch (SchemaRegistryException e) {
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
        try {
            return AvroSerializer.deserialize(client, schemaName, data);
        } catch (SchemaRegistryException e) {
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
        try {
            return JsonSerializer.serialize(client, schemaName, auditEvent);
        } catch (SchemaRegistryException e) {
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
        try {
            return JsonSerializer.deserialize(client, schemaName, data);
        } catch (SchemaRegistryException e) {
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
        // AWS SDK v2 clients don't need explicit closing in most cases
        // This method is provided for API consistency
    }
}

