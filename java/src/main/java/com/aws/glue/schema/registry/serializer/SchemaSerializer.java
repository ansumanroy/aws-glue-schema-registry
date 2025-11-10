package com.aws.glue.schema.registry.serializer;

import com.aws.glue.schema.registry.client.GlueSchemaRegistryClient;

/**
 * Generic interface for schema serialization and deserialization.
 * Implementations provide type-safe serialization for different data formats
 * (Avro, JSON, etc.) and model types.
 * 
 * @param <T> The type of object to serialize/deserialize
 */
public interface SchemaSerializer<T> {
    
    /**
     * Serializes an object to bytes using the schema from Glue Schema Registry.
     * 
     * @param client GlueSchemaRegistryClient instance
     * @param schemaName Name of the schema in the registry
     * @param object Object to serialize
     * @return Serialized byte array
     * @throws com.aws.glue.schema.registry.client.SchemaRegistryException if serialization fails
     */
    byte[] serialize(GlueSchemaRegistryClient client, String schemaName, T object);
    
    /**
     * Deserializes bytes to an object using the schema from Glue Schema Registry.
     * 
     * @param client GlueSchemaRegistryClient instance
     * @param schemaName Name of the schema in the registry
     * @param data Serialized byte array
     * @return Deserialized object
     * @throws com.aws.glue.schema.registry.client.SchemaRegistryException if deserialization fails
     */
    T deserialize(GlueSchemaRegistryClient client, String schemaName, byte[] data);
}

