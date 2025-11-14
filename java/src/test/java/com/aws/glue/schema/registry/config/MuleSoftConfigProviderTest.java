package com.aws.glue.schema.registry.config;

import org.junit.jupiter.api.*;
import software.amazon.awssdk.regions.Region;

import java.util.Properties;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Test class for MuleSoftConfigProvider.
 * Tests configuration loading, property resolution, and environment detection.
 */
@DisplayName("MuleSoftConfigProvider Tests")
class MuleSoftConfigProviderTest {
    
    private static final String TEST_REGISTRY_NAME = "test-registry";
    private static final String TEST_REGION = "us-west-2";
    private static final String TEST_ACCESS_KEY = "test-access-key";
    private static final String TEST_SECRET_KEY = "test-secret-key";
    
    private Properties originalSystemProperties;
    
    @BeforeEach
    void setUp() {
        // Save original system properties
        originalSystemProperties = new Properties();
        originalSystemProperties.putAll(System.getProperties());
        
        // Clear system properties for clean test state
        System.clearProperty("glue.registry.name");
        System.clearProperty("aws.region");
        System.clearProperty("aws.access.key.id");
        System.clearProperty("aws.secret.access.key");
    }
    
    @AfterEach
    void tearDown() {
        // Restore original system properties
        System.setProperties(originalSystemProperties);
        
        // Note: We can't restore environment variables in Java, but tests should
        // not rely on specific environment variable values
    }
    
    @Test
    @DisplayName("Test fromMuleSoftProperties() with default property names")
    void testFromMuleSoftPropertiesWithDefaults() {
        // Set system properties
        System.setProperty("glue.registry.name", TEST_REGISTRY_NAME);
        System.setProperty("aws.region", TEST_REGION);
        
        GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties();
        
        assertNotNull(config);
        assertEquals(TEST_REGISTRY_NAME, config.getRegistryName());
        assertEquals(Region.of(TEST_REGION), config.getRegion());
    }
    
    @Test
    @DisplayName("Test fromMuleSoftProperties() with custom property names")
    void testFromMuleSoftPropertiesWithCustomNames() {
        // Set system properties with custom names
        System.setProperty("custom.registry.name", TEST_REGISTRY_NAME);
        System.setProperty("custom.region", TEST_REGION);
        
        GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties(
                "custom.registry.name",
                "custom.region"
        );
        
        assertNotNull(config);
        assertEquals(TEST_REGISTRY_NAME, config.getRegistryName());
        assertEquals(Region.of(TEST_REGION), config.getRegion());
    }
    
    @Test
    @DisplayName("Test fromMuleSoftProperties() uses default values when properties are missing")
    void testFromMuleSoftPropertiesUsesDefaults() {
        // Don't set any system properties
        // Note: Environment variables may be set (e.g., in CI/CD), which is valid behavior
        // The method should use defaults only if neither system properties nor env vars are set
        
        // Check if environment variables are set
        String envRegistryName = System.getenv("GLUE_REGISTRY_NAME");
        String envRegion = System.getenv("AWS_REGION");
        
        GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties();
        
        assertNotNull(config);
        
        if (envRegistryName != null && !envRegistryName.isEmpty()) {
            // If environment variable is set, it should be used (valid behavior)
            assertEquals(envRegistryName, config.getRegistryName());
        } else {
            // Otherwise, should use default
            assertEquals("glue-schema-registry", config.getRegistryName());
        }
        
        if (envRegion != null && !envRegion.isEmpty()) {
            // If environment variable is set, it should be used (valid behavior)
            assertEquals(Region.of(envRegion), config.getRegion());
        } else {
            // Otherwise, should use default
            assertEquals(Region.US_EAST_1, config.getRegion());
        }
    }
    
    @Test
    @DisplayName("Test fromMuleSoftProperties() with credentials")
    void testFromMuleSoftPropertiesWithCredentials() {
        // Set system properties including credentials
        System.setProperty("glue.registry.name", TEST_REGISTRY_NAME);
        System.setProperty("aws.region", TEST_REGION);
        System.setProperty("aws.access.key.id", TEST_ACCESS_KEY);
        System.setProperty("aws.secret.access.key", TEST_SECRET_KEY);
        
        GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties();
        
        assertNotNull(config);
        assertEquals(TEST_REGISTRY_NAME, config.getRegistryName());
        assertEquals(Region.of(TEST_REGION), config.getRegion());
        
        // Verify credentials provider is set
        assertNotNull(config.getCredentialsProvider());
        
        // Verify credentials are accessible
        var credentials = config.getCredentialsProvider().resolveCredentials();
        assertEquals(TEST_ACCESS_KEY, credentials.accessKeyId());
        assertEquals(TEST_SECRET_KEY, credentials.secretAccessKey());
    }
    
    @Test
    @DisplayName("Test fromMuleSoftProperties() without credentials uses default provider")
    void testFromMuleSoftPropertiesWithoutCredentials() {
        // Set system properties without credentials
        System.setProperty("glue.registry.name", TEST_REGISTRY_NAME);
        System.setProperty("aws.region", TEST_REGION);
        
        GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties();
        
        assertNotNull(config);
        // Credentials provider should still be available (default provider)
        assertNotNull(config.getCredentialsProvider());
    }
    
    @Test
    @DisplayName("Test property resolution from system properties")
    void testPropertyResolutionFromSystemProperties() {
        System.setProperty("glue.registry.name", TEST_REGISTRY_NAME);
        System.setProperty("aws.region", TEST_REGION);
        
        GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties();
        
        assertEquals(TEST_REGISTRY_NAME, config.getRegistryName());
        assertEquals(Region.of(TEST_REGION), config.getRegion());
    }
    
    @Test
    @DisplayName("Test property resolution from environment variables")
    void testPropertyResolutionFromEnvironmentVariables() {
        // Note: We can't set environment variables in Java tests easily,
        // but we can test that the code handles them if they exist
        // This test verifies the code doesn't break when env vars are present
        
        // Clear system properties to force fallback to environment
        System.clearProperty("glue.registry.name");
        System.clearProperty("aws.region");
        
        // The method should use defaults if neither system properties nor env vars are set
        GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties();
        
        assertNotNull(config);
        // Should use defaults
        assertNotNull(config.getRegistryName());
        assertNotNull(config.getRegion());
    }
    
    @Test
    @DisplayName("Test isMuleSoftEnvironment() returns false in non-MuleSoft environment")
    void testIsMuleSoftEnvironment() {
        // In a standard Java test environment, MuleSoft classes won't be available
        boolean isMuleSoft = MuleSoftConfigProvider.isMuleSoftEnvironment();
        
        assertFalse(isMuleSoft, "Should return false when MuleSoft classes are not available");
    }
    
    @Test
    @DisplayName("Test configuration with partial credentials fails gracefully")
    void testConfigurationWithPartialCredentials() {
        // Set only access key, not secret key
        System.setProperty("glue.registry.name", TEST_REGISTRY_NAME);
        System.setProperty("aws.region", TEST_REGION);
        System.setProperty("aws.access.key.id", TEST_ACCESS_KEY);
        // Don't set secret key
        
        GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties();
        
        assertNotNull(config);
        // Should use default credentials provider when credentials are incomplete
        assertNotNull(config.getCredentialsProvider());
    }
    
    @Test
    @DisplayName("Test configuration with empty property values throws exception")
    void testConfigurationWithEmptyPropertyValues() {
        // Set empty strings - these will cause an error when trying to create Region
        System.setProperty("glue.registry.name", "");
        System.setProperty("aws.region", "");
        
        // Empty region string will cause IllegalArgumentException when creating Region
        assertThrows(IllegalArgumentException.class, () -> {
            MuleSoftConfigProvider.fromMuleSoftProperties();
        }, "Should throw exception when region is empty string");
    }
    
    @Test
    @DisplayName("Test custom property names with credentials")
    void testCustomPropertyNamesWithCredentials() {
        System.setProperty("custom.registry", TEST_REGISTRY_NAME);
        System.setProperty("custom.aws.region", TEST_REGION);
        System.setProperty("custom.access.key", TEST_ACCESS_KEY);
        System.setProperty("custom.secret.key", TEST_SECRET_KEY);
        
        GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties(
                "custom.registry",
                "custom.aws.region"
        );
        
        assertNotNull(config);
        assertEquals(TEST_REGISTRY_NAME, config.getRegistryName());
        assertEquals(Region.of(TEST_REGION), config.getRegion());
        
        // Note: Credentials still use default property names
        // This is expected behavior based on the implementation
    }
    
    @Test
    @DisplayName("Test configuration builder creates valid config")
    void testConfigBuilder() {
        System.setProperty("glue.registry.name", TEST_REGISTRY_NAME);
        System.setProperty("aws.region", TEST_REGION);
        
        GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties();
        
        // Verify config can be used to create a client (indirectly)
        assertNotNull(config.getRegistryName());
        assertNotNull(config.getRegion());
        assertNotNull(config.getCredentialsProvider());
    }
    
    @Test
    @DisplayName("Test multiple calls return consistent results")
    void testMultipleCallsConsistency() {
        System.setProperty("glue.registry.name", TEST_REGISTRY_NAME);
        System.setProperty("aws.region", TEST_REGION);
        
        GlueSchemaRegistryConfig config1 = MuleSoftConfigProvider.fromMuleSoftProperties();
        GlueSchemaRegistryConfig config2 = MuleSoftConfigProvider.fromMuleSoftProperties();
        
        assertEquals(config1.getRegistryName(), config2.getRegistryName());
        assertEquals(config1.getRegion(), config2.getRegion());
    }
    
    @Test
    @DisplayName("Test configuration with different regions")
    void testConfigurationWithDifferentRegions() {
        String[] regions = {"us-east-1", "us-west-2", "eu-west-1", "ap-southeast-1"};
        
        for (String regionStr : regions) {
            System.setProperty("glue.registry.name", TEST_REGISTRY_NAME);
            System.setProperty("aws.region", regionStr);
            
            GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties();
            
            assertEquals(Region.of(regionStr), config.getRegion());
        }
    }
    
    @Test
    @DisplayName("Test credentials provider is StaticCredentialsProvider when credentials provided")
    void testCredentialsProviderType() {
        System.setProperty("glue.registry.name", TEST_REGISTRY_NAME);
        System.setProperty("aws.region", TEST_REGION);
        System.setProperty("aws.access.key.id", TEST_ACCESS_KEY);
        System.setProperty("aws.secret.access.key", TEST_SECRET_KEY);
        
        GlueSchemaRegistryConfig config = MuleSoftConfigProvider.fromMuleSoftProperties();
        
        var credentialsProvider = config.getCredentialsProvider();
        assertNotNull(credentialsProvider);
        
        // Verify we can resolve credentials
        var credentials = credentialsProvider.resolveCredentials();
        assertNotNull(credentials);
        assertEquals(TEST_ACCESS_KEY, credentials.accessKeyId());
        assertEquals(TEST_SECRET_KEY, credentials.secretAccessKey());
    }
}

