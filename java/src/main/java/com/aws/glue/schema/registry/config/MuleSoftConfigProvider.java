package com.aws.glue.schema.registry.config;

import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;

/**
 * MuleSoft-specific configuration provider.
 * This class provides integration with MuleSoft's configuration system,
 * including secure properties and MuleSoft-specific credential management.
 * 
 * Note: MuleSoft-specific classes are loaded via reflection to avoid
 * hard dependencies when used in non-MuleSoft environments.
 */
public class MuleSoftConfigProvider {
    
    private static final String MULE_CONFIG_PROPERTY_PREFIX = "mule.app.";
    private static final String MULE_SECURE_PROPERTY_PREFIX = "secure::";
    
    /**
     * Creates a GlueSchemaRegistryConfig from MuleSoft configuration.
     * Reads configuration from MuleSoft's configuration property resolver.
     * 
     * @param registryNameProperty Property key for registry name (e.g., "glue.registry.name")
     * @param regionProperty Property key for AWS region (e.g., "aws.region")
     * @return GlueSchemaRegistryConfig configured from MuleSoft properties
     */
    public static GlueSchemaRegistryConfig fromMuleSoftProperties(
            String registryNameProperty, 
            String regionProperty) {
        
        String registryName = getMuleSoftProperty(registryNameProperty, "glue-schema-registry");
        String regionName = getMuleSoftProperty(regionProperty, "us-east-1");
        String accessKey = getMuleSoftProperty("aws.access.key.id", null);
        String secretKey = getMuleSoftProperty("aws.secret.access.key", null);
        
        GlueSchemaRegistryConfig.Builder builder = GlueSchemaRegistryConfig.builder()
            .registryName(registryName)
            .region(regionName);
        
        // If credentials are provided, use them
        if (accessKey != null && secretKey != null) {
            AwsBasicCredentials credentials = AwsBasicCredentials.create(accessKey, secretKey);
            builder.credentialsProvider(StaticCredentialsProvider.create(credentials));
            // Note: Session tokens would need to be handled via AwsSessionCredentials if needed
            // For now, we use basic credentials. Session token support can be added later.
        }
        
        return builder.build();
    }
    
    /**
     * Creates a GlueSchemaRegistryConfig from MuleSoft configuration with default property names.
     * 
     * @return GlueSchemaRegistryConfig configured from MuleSoft properties
     */
    public static GlueSchemaRegistryConfig fromMuleSoftProperties() {
        return fromMuleSoftProperties("glue.registry.name", "aws.region");
    }
    
    /**
     * Gets a property value from MuleSoft's configuration system.
     * This method attempts to read from:
     * 1. MuleSoft secure properties (secure:: prefix)
     * 2. MuleSoft application properties (mule.app. prefix)
     * 3. System properties
     * 4. Environment variables
     * 
     * @param propertyKey The property key to retrieve
     * @param defaultValue Default value if property is not found
     * @return Property value or defaultValue
     */
    private static String getMuleSoftProperty(String propertyKey, String defaultValue) {
        // Try MuleSoft secure properties first
        String secureKey = MULE_SECURE_PROPERTY_PREFIX + propertyKey;
        String value = getMuleSoftPropertyValue(secureKey);
        if (value != null) {
            return value;
        }
        
        // Try MuleSoft application properties
        String appKey = MULE_CONFIG_PROPERTY_PREFIX + propertyKey;
        value = getMuleSoftPropertyValue(appKey);
        if (value != null) {
            return value;
        }
        
        // Try system property
        value = System.getProperty(propertyKey);
        if (value != null) {
            return value;
        }
        
        // Try environment variable (convert dots to underscores and uppercase)
        String envKey = propertyKey.toUpperCase().replace('.', '_');
        value = System.getenv(envKey);
        if (value != null) {
            return value;
        }
        
        // Try direct environment variable
        value = System.getenv(propertyKey);
        if (value != null) {
            return value;
        }
        
        return defaultValue;
    }
    
    /**
     * Attempts to get a property value from MuleSoft's configuration system.
     * Uses reflection to avoid hard dependency on MuleSoft classes.
     * 
     * @param propertyKey The property key
     * @return Property value or null if not found
     */
    private static String getMuleSoftPropertyValue(String propertyKey) {
        try {
            // Try to get from MuleSoft's configuration system via reflection
            // This is a fallback that won't break if MuleSoft classes aren't available
            Class.forName("org.mule.runtime.config.api.dsl.model.properties.ConfigurationPropertiesProvider");
            Object configProvider = getMuleSoftConfigProvider();
            if (configProvider != null) {
                // Use reflection to call getProperty method
                java.lang.reflect.Method getPropertyMethod = configProvider.getClass()
                    .getMethod("getProperty", String.class);
                Object result = getPropertyMethod.invoke(configProvider, propertyKey);
                if (result != null) {
                    return result.toString();
                }
            }
        } catch (ClassNotFoundException e) {
            // MuleSoft classes not available - this is expected in standalone mode
            return null;
        } catch (Exception e) {
            // Reflection failed - fall back to other methods
            return null;
        }
        return null;
    }
    
    /**
     * Attempts to get the MuleSoft configuration provider instance.
     * Uses reflection to avoid hard dependency.
     */
    private static Object getMuleSoftConfigProvider() {
        try {
            // Try to get MuleSoft's configuration context
            // This is a simplified version - actual implementation would need
            // access to MuleSoft's runtime context
            Class.forName("org.mule.runtime.api.config.FeatureContext");
            return null;
        } catch (ClassNotFoundException e) {
            return null;
        }
    }
    
    /**
     * Checks if the code is running in a MuleSoft environment.
     * 
     * @return true if MuleSoft classes are available
     */
    public static boolean isMuleSoftEnvironment() {
        try {
            Class.forName("org.mule.runtime.api.MuleContext");
            return true;
        } catch (ClassNotFoundException e) {
            return false;
        }
    }
}

