package com.aws.glue.schema.registry.config;

import software.amazon.awssdk.regions.Region;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * Utility class for loading test configuration from resource file.
 * Supports environment variable overrides.
 */
public class TestConfig {
    
    private static final String CONFIG_FILE = "/test-config.properties";
    private static Properties properties;
    
    static {
        loadProperties();
    }
    
    private static void loadProperties() {
        properties = new Properties();
        try (InputStream inputStream = TestConfig.class.getResourceAsStream(CONFIG_FILE)) {
            if (inputStream != null) {
                properties.load(inputStream);
            }
        } catch (IOException e) {
            // If config file is not found, use defaults
            System.err.println("Warning: Could not load test-config.properties, using defaults");
        }
    }
    
    /**
     * Gets the registry name, with environment variable override support.
     * 
     * @return Registry name
     */
    public static String getRegistryName() {
        String envValue = System.getenv("GLUE_REGISTRY_NAME");
        if (envValue != null && !envValue.isEmpty()) {
            return envValue;
        }
        String propValue = System.getProperty("glue.registry.name");
        if (propValue != null && !propValue.isEmpty()) {
            return propValue;
        }
        return properties.getProperty("glue.registry.name", "glue-schema-registry-ansumanroy-6219");
    }
    
    /**
     * Gets the AWS region, with environment variable override support.
     * 
     * @return AWS region
     */
    public static Region getAWSRegion() {
        String envValue = System.getenv("AWS_REGION");
        if (envValue != null && !envValue.isEmpty()) {
            return Region.of(envValue);
        }
        String propValue = System.getProperty("aws.region");
        if (propValue != null && !propValue.isEmpty()) {
            return Region.of(propValue);
        }
        String regionStr = properties.getProperty("aws.region", "us-east-1");
        return Region.of(regionStr);
    }
    
    /**
     * Gets the Avro schema name.
     * 
     * @return Avro schema name
     */
    public static String getAvroSchemaName() {
        String envValue = System.getenv("SCHEMA_NAME_AVRO");
        if (envValue != null && !envValue.isEmpty()) {
            return envValue;
        }
        return properties.getProperty("schema.name.avro", "SalesforceAudit");
    }
    
    /**
     * Gets the JSON schema name.
     * 
     * @return JSON schema name
     */
    public static String getJsonSchemaName() {
        String envValue = System.getenv("SCHEMA_NAME_JSON");
        if (envValue != null && !envValue.isEmpty()) {
            return envValue;
        }
        return properties.getProperty("schema.name.json", "SalesAuditJSON");
    }
}

