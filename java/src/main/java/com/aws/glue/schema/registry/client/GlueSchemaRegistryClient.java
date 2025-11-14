package com.aws.glue.schema.registry.client;

import com.aws.glue.schema.registry.config.GlueSchemaRegistryConfig;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
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
    
    private static final Logger logger = LogManager.getLogger(GlueSchemaRegistryClient.class);
    
    private final GlueClient glueClient;
    private final String registryName;
    
    /**
     * Constructs a new GlueSchemaRegistryClient with default AWS credentials and specified region.
     * 
     * @param region AWS region where the schema registry is located
     * @param registryName Name of the Glue Schema Registry
     */
    public GlueSchemaRegistryClient(Region region, String registryName) {
        logger.debug("Creating GlueSchemaRegistryClient - registry: {}, region: {}", registryName, region);
        this.glueClient = GlueClient.builder()
                .region(region)
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
        this.registryName = registryName;
        logger.info("GlueSchemaRegistryClient created - registry: {}, region: {}", registryName, region);
    }
    
    /**
     * Constructs a new GlueSchemaRegistryClient with a custom GlueClient.
     * 
     * @param glueClient Pre-configured GlueClient instance
     * @param registryName Name of the Glue Schema Registry
     */
    public GlueSchemaRegistryClient(GlueClient glueClient, String registryName) {
        logger.debug("Creating GlueSchemaRegistryClient with existing GlueClient - registry: {}", registryName);
        this.glueClient = glueClient;
        this.registryName = registryName;
        logger.info("GlueSchemaRegistryClient created with existing client - registry: {}", registryName);
    }
    
    /**
     * Constructs a new GlueSchemaRegistryClient from a configuration object.
     * This constructor supports flexible credential management and configuration.
     * 
     * @param config GlueSchemaRegistryConfig containing all configuration
     */
    public GlueSchemaRegistryClient(GlueSchemaRegistryConfig config) {
        logger.debug("Creating GlueSchemaRegistryClient from config - registry: {}, region: {}", 
                config.getRegistryName(), config.getRegion());
        this.glueClient = GlueClient.builder()
                .region(config.getRegion())
                .credentialsProvider(config.getCredentialsProvider())
                .build();
        this.registryName = config.getRegistryName();
        logger.info("GlueSchemaRegistryClient created from config - registry: {}, region: {}", 
                config.getRegistryName(), config.getRegion());
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
        logger.debug("Getting schema - registry: {}, schema: {}", registryName, schemaName);
        GetSchemaRequest request = GetSchemaRequest.builder()
                .schemaId(SchemaId.builder()
                        .registryName(registryName)
                        .schemaName(schemaName)
                        .build())
                .build();
        
        GetSchemaResponse response = glueClient.getSchema(request);
        logger.debug("Retrieved schema - registry: {}, schema: {}, latestVersion: {}", 
                registryName, schemaName, response.latestSchemaVersion());
        return response;
    }
    
    /**
     * Gets a specific version of a schema.
     * 
     * @param schemaName Name of the schema
     * @param versionNumber Version number of the schema
     * @return Schema version information
     */
    public GetSchemaVersionResponse getSchemaVersion(String schemaName, Long versionNumber) {
        logger.debug("Getting schema version - registry: {}, schema: {}, version: {}", 
                registryName, schemaName, versionNumber);
        GetSchemaVersionRequest request = GetSchemaVersionRequest.builder()
                .schemaId(SchemaId.builder()
                        .registryName(registryName)
                        .schemaName(schemaName)
                        .build())
                .schemaVersionNumber(SchemaVersionNumber.builder()
                        .versionNumber(versionNumber)
                        .build())
                .build();
        
        GetSchemaVersionResponse response = glueClient.getSchemaVersion(request);
        logger.debug("Retrieved schema version - registry: {}, schema: {}, version: {}, definition length: {} chars", 
                registryName, schemaName, versionNumber, 
                response.schemaDefinition() != null ? response.schemaDefinition().length() : 0);
        return response;
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
        logger.debug("Closing GlueSchemaRegistryClient - registry: {}", registryName);
        glueClient.close();
        logger.info("GlueSchemaRegistryClient closed - registry: {}", registryName);
    }
}
