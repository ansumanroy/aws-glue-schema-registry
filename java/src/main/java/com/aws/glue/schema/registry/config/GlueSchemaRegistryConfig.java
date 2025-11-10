package com.aws.glue.schema.registry.config;

import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;

import java.util.Optional;

/**
 * Configuration class for Glue Schema Registry Client.
 * Supports multiple credential sources and configuration options for both
 * standalone and MuleSoft environments.
 */
public class GlueSchemaRegistryConfig {
    
    private final String registryName;
    private final Region region;
    private final AwsCredentialsProvider credentialsProvider;
    private final String accessKeyId;
    private final String secretAccessKey;
    private final String sessionToken;
    private final Integer connectionTimeout;
    private final Integer socketTimeout;
    
    private GlueSchemaRegistryConfig(Builder builder) {
        this.registryName = builder.registryName;
        this.region = builder.region;
        this.credentialsProvider = builder.credentialsProvider;
        this.accessKeyId = builder.accessKeyId;
        this.secretAccessKey = builder.secretAccessKey;
        this.sessionToken = builder.sessionToken;
        this.connectionTimeout = builder.connectionTimeout;
        this.socketTimeout = builder.socketTimeout;
    }
    
    public String getRegistryName() {
        return registryName;
    }
    
    public Region getRegion() {
        return region;
    }
    
    public AwsCredentialsProvider getCredentialsProvider() {
        return credentialsProvider != null 
            ? credentialsProvider 
            : DefaultCredentialsProvider.create();
    }
    
    public Optional<String> getAccessKeyId() {
        return Optional.ofNullable(accessKeyId);
    }
    
    public Optional<String> getSecretAccessKey() {
        return Optional.ofNullable(secretAccessKey);
    }
    
    public Optional<String> getSessionToken() {
        return Optional.ofNullable(sessionToken);
    }
    
    public Optional<Integer> getConnectionTimeout() {
        return Optional.ofNullable(connectionTimeout);
    }
    
    public Optional<Integer> getSocketTimeout() {
        return Optional.ofNullable(socketTimeout);
    }
    
    /**
     * Builder pattern for creating GlueSchemaRegistryConfig.
     */
    public static class Builder {
        private String registryName;
        private Region region;
        private AwsCredentialsProvider credentialsProvider;
        private String accessKeyId;
        private String secretAccessKey;
        private String sessionToken;
        private Integer connectionTimeout;
        private Integer socketTimeout;
        
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
        
        public Builder credentialsProvider(AwsCredentialsProvider credentialsProvider) {
            this.credentialsProvider = credentialsProvider;
            return this;
        }
        
        public Builder accessKeyId(String accessKeyId) {
            this.accessKeyId = accessKeyId;
            return this;
        }
        
        public Builder secretAccessKey(String secretAccessKey) {
            this.secretAccessKey = secretAccessKey;
            return this;
        }
        
        public Builder sessionToken(String sessionToken) {
            this.sessionToken = sessionToken;
            return this;
        }
        
        public Builder connectionTimeout(Integer connectionTimeout) {
            this.connectionTimeout = connectionTimeout;
            return this;
        }
        
        public Builder socketTimeout(Integer socketTimeout) {
            this.socketTimeout = socketTimeout;
            return this;
        }
        
        public GlueSchemaRegistryConfig build() {
            if (registryName == null || registryName.isEmpty()) {
                throw new IllegalArgumentException("Registry name is required");
            }
            if (region == null) {
                throw new IllegalArgumentException("Region is required");
            }
            return new GlueSchemaRegistryConfig(this);
        }
    }
    
    public static Builder builder() {
        return new Builder();
    }
    
    /**
     * Creates a config from environment variables.
     * Reads GLUE_REGISTRY_NAME and AWS_REGION from environment.
     */
    public static GlueSchemaRegistryConfig fromEnvironment() {
        String registryName = System.getenv("GLUE_REGISTRY_NAME");
        String regionName = System.getenv("AWS_REGION");
        
        if (registryName == null || registryName.isEmpty()) {
            registryName = System.getProperty("glue.registry.name", "glue-schema-registry");
        }
        if (regionName == null || regionName.isEmpty()) {
            regionName = System.getProperty("aws.region", "us-east-1");
        }
        
        return builder()
            .registryName(registryName)
            .region(regionName)
            .build();
    }
}

