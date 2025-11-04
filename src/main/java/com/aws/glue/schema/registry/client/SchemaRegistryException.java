package com.aws.glue.schema.registry.client;

/**
 * Custom exception for Glue Schema Registry operations.
 */
public class SchemaRegistryException extends RuntimeException {
    
    public SchemaRegistryException(String message) {
        super(message);
    }
    
    public SchemaRegistryException(String message, Throwable cause) {
        super(message, cause);
    }
}
