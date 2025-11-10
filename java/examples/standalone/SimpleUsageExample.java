package com.aws.glue.schema.registry.examples.standalone;

import com.aws.glue.schema.registry.client.GlueSchemaRegistryClient;
import com.aws.glue.schema.registry.config.GlueSchemaRegistryConfig;
import com.aws.glue.schema.registry.implementation.AvroSerializer;
import com.aws.glue.schema.registry.implementation.JsonSerializer;
import com.aws.glue.schema.registry.implementation.model.SalesforceAudit;
import software.amazon.awssdk.regions.Region;

/**
 * Simple standalone usage example for Glue Schema Registry client.
 * Demonstrates basic serialization and deserialization operations.
 */
public class SimpleUsageExample {
    
    public static void main(String[] args) {
        // Example 1: Using constructor with Region and registry name
        GlueSchemaRegistryClient client = new GlueSchemaRegistryClient(
            Region.US_EAST_1, 
            "my-schema-registry"
        );
        
        try {
            // Create a SalesforceAudit event
            SalesforceAudit auditEvent = new SalesforceAudit(
                "event-12345",
                "UserLogin",
                System.currentTimeMillis(),
                "User logged in successfully"
            );
            
            // Serialize using Avro
            AvroSerializer avroSerializer = AvroSerializer.getInstance();
            byte[] avroData = avroSerializer.serialize(client, "SalesforceAudit", auditEvent);
            System.out.println("Serialized to Avro: " + avroData.length + " bytes");
            
            // Deserialize from Avro
            SalesforceAudit deserialized = avroSerializer.deserialize(client, "SalesforceAudit", avroData);
            System.out.println("Deserialized event: " + deserialized.getEventId());
            
            // Serialize using JSON
            JsonSerializer jsonSerializer = JsonSerializer.getInstance();
            byte[] jsonData = jsonSerializer.serialize(client, "SalesAuditJSON", auditEvent);
            System.out.println("Serialized to JSON: " + jsonData.length + " bytes");
            
            // Deserialize from JSON
            SalesforceAudit deserializedJson = jsonSerializer.deserialize(client, "SalesAuditJSON", jsonData);
            System.out.println("Deserialized JSON event: " + deserializedJson.getEventId());
            
        } finally {
            client.close();
        }
    }
    
    /**
     * Example using configuration builder pattern.
     */
    public static void exampleWithConfig() {
        // Create configuration using builder
        GlueSchemaRegistryConfig config = GlueSchemaRegistryConfig.builder()
            .registryName("my-schema-registry")
            .region(Region.US_EAST_1)
            .build();
        
        // Create client from configuration
        GlueSchemaRegistryClient client = new GlueSchemaRegistryClient(config);
        
        try {
            // Use client...
        } finally {
            client.close();
        }
    }
    
    /**
     * Example using environment variables for configuration.
     */
    public static void exampleWithEnvironment() {
        // Create configuration from environment variables
        GlueSchemaRegistryConfig config = GlueSchemaRegistryConfig.fromEnvironment();
        
        // Create client from configuration
        GlueSchemaRegistryClient client = new GlueSchemaRegistryClient(config);
        
        try {
            // Use client...
        } finally {
            client.close();
        }
    }
    
    /**
     * Example using client builder pattern.
     */
    public static void exampleWithBuilder() {
        GlueSchemaRegistryClient client = GlueSchemaRegistryClient.builder()
            .registryName("my-schema-registry")
            .region(Region.US_EAST_1)
            .build();
        
        try {
            // Use client...
        } finally {
            client.close();
        }
    }
}

