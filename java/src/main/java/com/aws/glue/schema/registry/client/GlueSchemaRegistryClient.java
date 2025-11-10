package com.aws.glue.schema.registry.client;

import com.aws.glue.schema.registry.config.GlueSchemaRegistryConfig;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.glue.GlueClient;
import software.amazon.awssdk.services.glue.model.*;

import java.util.List;

/**
 * Java wrapper client for AWS Glue Schema Registry.
 * Provides a simplified interface to interact with Glue Schema Registry.
 * Supports both standalone and MuleSoft environments.
 */
public class GlueSchemaRegistryClient {
    
    private final GlueClient glueClient;
    private final String registryName;
    
    /**
     * Constructs a new GlueSchemaRegistryClient with default AWS credentials and specified region.
     * 
     * @param region AWS region where the schema registry is located
     * @param registryName Name of the Glue Schema Registry
     */
    public GlueSchemaRegistryClient(Region region, String registryName) {
        this.glueClient = GlueClient.builder()
                .region(region)
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
        this.registryName = registryName;
    }
    
    /**
     * Constructs a new GlueSchemaRegistryClient with a custom GlueClient.
     * 
     * @param glueClient Pre-configured GlueClient instance
     * @param registryName Name of the Glue Schema Registry
     */
    public GlueSchemaRegistryClient(GlueClient glueClient, String registryName) {
        this.glueClient = glueClient;
        this.registryName = registryName;
    }
    
    /**
     * Constructs a new GlueSchemaRegistryClient from a configuration object.
     * This constructor supports flexible credential management and configuration.
     * 
     * @param config GlueSchemaRegistryConfig containing all configuration
     */
    public GlueSchemaRegistryClient(GlueSchemaRegistryConfig config) {
        this.glueClient = GlueClient.builder()
                .region(config.getRegion())
                .credentialsProvider(config.getCredentialsProvider())
                .build();
        this.registryName = config.getRegistryName();
    }
    
    /**
     * Builder pattern for creating GlueSchemaRegistryClient.
     */
    public static class Builder {
        private String registryName;
        private Region region;
        private GlueClient glueClient;
        private GlueSchemaRegistryConfig config;
        
        public Builder registryName(String registryName) {
            this.registryName = registryName;
            return this;
        }
        
        public Builder region(Region region) {
            this.region = region;
            return this;
        }
        
        public Builder region(String regionName) {
            this.region = Region.of(regionName);
            return this;
        }
        
        public Builder glueClient(GlueClient glueClient) {
            this.glueClient = glueClient;
            return this;
        }
        
        public Builder config(GlueSchemaRegistryConfig config) {
            this.config = config;
            return this;
        }
        
        public GlueSchemaRegistryClient build() {
            if (config != null) {
                return new GlueSchemaRegistryClient(config);
            }
            if (glueClient != null && registryName != null) {
                return new GlueSchemaRegistryClient(glueClient, registryName);
            }
            if (region != null && registryName != null) {
                return new GlueSchemaRegistryClient(region, registryName);
            }
            throw new IllegalArgumentException(
                "Either config, or (glueClient and registryName), or (region and registryName) must be provided");
        }
    }
    
    public static Builder builder() {
        return new Builder();
    }
    
    /**
     * Creates a new schema in the registry.
     * 
     * @param schemaName Name of the schema
     * @param dataFormat Data format (AVRO, JSON, PROTOBUF)
     * @param schemaDefinition Schema definition string
     * @param compatibility Compatibility mode
     * @return Created schema information
     */
    public CreateSchemaResponse createSchema(String schemaName, String dataFormat, 
                                            String schemaDefinition, Compatibility compatibility) {
        CreateSchemaRequest request = CreateSchemaRequest.builder()
                .registryId(RegistryId.builder().registryName(registryName).build())
                .schemaName(schemaName)
                .dataFormat(DataFormat.valueOf(dataFormat.toUpperCase()))
                .schemaDefinition(schemaDefinition)
                .compatibility(compatibility)
                .build();
        
        return glueClient.createSchema(request);
    }
    
    /**
     * Gets a schema by name.
     * 
     * @param schemaName Name of the schema
     * @return Schema information
     */
    public GetSchemaResponse getSchema(String schemaName) {
        GetSchemaRequest request = GetSchemaRequest.builder()
                .schemaId(SchemaId.builder()
                        .registryName(registryName)
                        .schemaName(schemaName)
                        .build())
                .build();
        
        return glueClient.getSchema(request);
    }
    
    /**
     * Gets a specific version of a schema.
     * 
     * @param schemaName Name of the schema
     * @param versionNumber Version number of the schema
     * @return Schema version information
     */
    public GetSchemaVersionResponse getSchemaVersion(String schemaName, Long versionNumber) {
        GetSchemaVersionRequest request = GetSchemaVersionRequest.builder()
                .schemaId(SchemaId.builder()
                        .registryName(registryName)
                        .schemaName(schemaName)
                        .build())
                .schemaVersionNumber(SchemaVersionNumber.builder()
                        .versionNumber(versionNumber)
                        .build())
                .build();
        
        return glueClient.getSchemaVersion(request);
    }
    
    /**
     * Lists all schemas in the registry.
     * 
     * @return List of schema summaries
     */
    public List<SchemaListItem> listSchemas() {
        ListSchemasRequest request = ListSchemasRequest.builder()
                .registryId(RegistryId.builder().registryName(registryName).build())
                .build();
        
        return glueClient.listSchemas(request).schemas();
    }
    
    /**
     * Updates schema compatibility mode.
     * 
     * @param schemaName Name of the schema
     * @param compatibility New compatibility mode
     * @return Update response
     */
    public UpdateSchemaResponse updateSchemaCompatibility(String schemaName, Compatibility compatibility) {
        GetSchemaResponse schema = getSchema(schemaName);
        
        UpdateSchemaRequest request = UpdateSchemaRequest.builder()
                .schemaId(SchemaId.builder()
                        .registryName(registryName)
                        .schemaName(schemaName)
                        .build())
                .compatibility(compatibility)
                .description(schema.description())
                .build();
        
        return glueClient.updateSchema(request);
    }
    
    /**
     * Registers a new version of a schema.
     * 
     * @param schemaName Name of the schema
     * @param schemaDefinition New schema definition
     * @return Registered schema version
     */
    public RegisterSchemaVersionResponse registerSchemaVersion(String schemaName, String schemaDefinition) {
        RegisterSchemaVersionRequest request = RegisterSchemaVersionRequest.builder()
                .schemaId(SchemaId.builder()
                        .registryName(registryName)
                        .schemaName(schemaName)
                        .build())
                .schemaDefinition(schemaDefinition)
                .build();
        
        return glueClient.registerSchemaVersion(request);
    }
    
    /**
     * Closes the underlying Glue client.
     */
    public void close() {
        glueClient.close();
    }
}
