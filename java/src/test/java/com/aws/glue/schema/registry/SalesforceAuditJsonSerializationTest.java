package com.aws.glue.schema.registry;

import com.aws.glue.schema.registry.client.GlueSchemaRegistryClient;
import com.aws.glue.schema.registry.client.SchemaRegistryException;
import com.aws.glue.schema.registry.config.TestConfig;
import com.aws.glue.schema.registry.implementation.JsonSerializer;
import com.aws.glue.schema.registry.implementation.model.SalesforceAudit;
import org.junit.jupiter.api.*;
import software.amazon.awssdk.awscore.exception.AwsServiceException;

import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * Test class for serializing and deserializing SalesforceAudit objects using JSON format
 * with GlueSchemaRegistryClient.
 * 
 * These are integration tests that require:
 * - AWS credentials configured
 * - Glue Schema Registry with JSON schema already created
 * 
 * Tests will be skipped if schema doesn't exist or AWS credentials are not available.
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class SalesforceAuditJsonSerializationTest {
    
    private static GlueSchemaRegistryClient client;
    private static final String REGISTRY_NAME = TestConfig.getRegistryName();
    private static final String SCHEMA_NAME = TestConfig.getJsonSchemaName();
    private static boolean schemaExists = false;
    
    @BeforeAll
    static void setUp() {
        // Check if we should skip integration tests
        String skipTests = System.getenv("SKIP_INTEGRATION_TESTS");
        if ("true".equalsIgnoreCase(skipTests)) {
            System.out.println("Skipping integration tests (SKIP_INTEGRATION_TESTS=true)");
            return;
        }
        
        try {
            // Initialize the client - assumes AWS credentials are configured
            client = new GlueSchemaRegistryClient(TestConfig.getAWSRegion(), REGISTRY_NAME);
            
            // Verify the schema exists in the registry
            try {
                var schemaResponse = client.getSchema(SCHEMA_NAME);
                schemaExists = schemaResponse != null && schemaResponse.latestSchemaVersion() != null;
                if (schemaExists) {
                    System.out.println("Schema '" + SCHEMA_NAME + "' found in registry '" + REGISTRY_NAME + "'");
                }
            } catch (AwsServiceException e) {
                // EntityNotFoundException is a subclass of AwsServiceException
                System.out.println("Schema '" + SCHEMA_NAME + "' not found in registry '" + REGISTRY_NAME + 
                    "'. Skipping integration tests. Error: " + e.getMessage());
                schemaExists = false;
            }
        } catch (Exception e) {
            System.out.println("Failed to initialize client or check schema. Skipping integration tests. Error: " + e.getMessage());
            schemaExists = false;
        }
    }
    
    @AfterAll
    static void tearDown() {
        if (client != null) {
            client.close();
        }
    }
    
    @Test
    @Order(1)
    @DisplayName("Test that salesforce-event-schema exists in registry")
    void testSchemaExists() {
        assumeTrue(schemaExists, "Schema '" + SCHEMA_NAME + "' must exist in registry '" + REGISTRY_NAME + 
            "' for integration tests to run. Set SKIP_INTEGRATION_TESTS=true to skip these tests.");
        
        // Verify the schema exists in the registry
        assertDoesNotThrow(() -> {
            var schemaResponse = client.getSchema(SCHEMA_NAME);
            assertNotNull(schemaResponse);
            assertNotNull(schemaResponse.latestSchemaVersion());
            assertEquals("JSON", schemaResponse.dataFormat().toString());
        }, "Schema should exist in the registry");
    }
    
    @Test
    @Order(2)
    @DisplayName("Test serialization of SalesforceAudit object to JSON")
    void testSerialization() {
        assumeTrue(schemaExists, "Schema must exist for this test to run");
        // Create a test SalesforceAudit object
        SalesforceAudit auditEvent = new SalesforceAudit(
            "event-12345",
            "UserLogin",
            System.currentTimeMillis(),
            "User logged in successfully from IP 192.168.1.1"
        );
        
        // Serialize the object
        assertDoesNotThrow(() -> {
            byte[] serializedData = JsonSerializer.serialize(client, SCHEMA_NAME, auditEvent);
            
            assertNotNull(serializedData);
            assertTrue(serializedData.length > 0, "Serialized data should not be empty");
            
            // Verify it's valid JSON by checking it contains expected fields
            String jsonString = new String(serializedData);
            assertTrue(jsonString.contains("eventId"), "JSON should contain eventId");
            assertTrue(jsonString.contains("eventName"), "JSON should contain eventName");
            assertTrue(jsonString.contains("timestamp"), "JSON should contain timestamp");
            assertTrue(jsonString.contains("eventDetails"), "JSON should contain eventDetails");
            
            System.out.println("Serialized " + serializedData.length + " bytes");
            System.out.println("JSON: " + jsonString);
        }, "Serialization should succeed");
    }
    
    @Test
    @Order(3)
    @DisplayName("Test deserialization of JSON bytes to SalesforceAudit object")
    void testDeserialization() {
        assumeTrue(schemaExists, "Schema must exist for this test to run");
        // Create a test SalesforceAudit object
        SalesforceAudit originalEvent = new SalesforceAudit(
            "event-67890",
            "DataAccess",
            1704067200000L, // Fixed timestamp for testing
            "User accessed customer data record ID: 98765"
        );
        
        // Serialize first
        byte[] serializedData = JsonSerializer.serialize(client, SCHEMA_NAME, originalEvent);
        assertNotNull(serializedData);
        
        // Deserialize
        SalesforceAudit deserializedEvent = JsonSerializer.deserialize(client, SCHEMA_NAME, serializedData);
        
        // Verify the deserialized object matches the original
        assertNotNull(deserializedEvent);
        assertEquals(originalEvent.getEventId(), deserializedEvent.getEventId());
        assertEquals(originalEvent.getEventName(), deserializedEvent.getEventName());
        assertEquals(originalEvent.getTimestamp(), deserializedEvent.getTimestamp());
        assertEquals(originalEvent.getEventDetails(), deserializedEvent.getEventDetails());
    }
    
    @Test
    @Order(4)
    @DisplayName("Test round-trip serialization and deserialization")
    void testRoundTripSerialization() {
        assumeTrue(schemaExists, "Schema must exist for this test to run");
        // Create test objects with different values
        SalesforceAudit[] testEvents = {
            new SalesforceAudit("evt-001", "Create", 1609459200000L, "Created new account"),
            new SalesforceAudit("evt-002", "Update", 1609545600000L, "Updated contact information"),
            new SalesforceAudit("evt-003", "Delete", 1609632000000L, "Deleted record ID: 456"),
            new SalesforceAudit("evt-004", "Export", 1609718400000L, "Exported report: MonthlySales")
        };
        
        for (SalesforceAudit originalEvent : testEvents) {
            // Serialize
            byte[] serializedData = JsonSerializer.serialize(client, SCHEMA_NAME, originalEvent);
            assertNotNull(serializedData);
            
            // Deserialize
            SalesforceAudit deserializedEvent = JsonSerializer.deserialize(client, SCHEMA_NAME, serializedData);
            assertNotNull(deserializedEvent);
            
            // Verify all fields match
            assertEquals(originalEvent.getEventId(), deserializedEvent.getEventId(), 
                "Event ID should match");
            assertEquals(originalEvent.getEventName(), deserializedEvent.getEventName(), 
                "Event Name should match");
            assertEquals(originalEvent.getTimestamp(), deserializedEvent.getTimestamp(), 
                "Timestamp should match");
            assertEquals(originalEvent.getEventDetails(), deserializedEvent.getEventDetails(), 
                "Event Details should match");
            
            // Verify equals and hashCode
            assertEquals(originalEvent, deserializedEvent, "Objects should be equal");
            assertEquals(originalEvent.hashCode(), deserializedEvent.hashCode(), 
                "Hash codes should match");
            
            System.out.println("✓ Round-trip successful for: " + originalEvent.getEventId());
        }
    }
    
    @Test
    @Order(5)
    @DisplayName("Test serialization with empty strings")
    void testSerializationWithEmptyStrings() {
        assumeTrue(schemaExists, "Schema must exist for this test to run");
        SalesforceAudit auditEvent = new SalesforceAudit(
            "",
            "",
            0L,
            ""
        );
        
        byte[] serializedData = JsonSerializer.serialize(client, SCHEMA_NAME, auditEvent);
        assertNotNull(serializedData);
        
        SalesforceAudit deserializedEvent = JsonSerializer.deserialize(client, SCHEMA_NAME, serializedData);
        assertNotNull(deserializedEvent);
        assertEquals("", deserializedEvent.getEventId());
        assertEquals("", deserializedEvent.getEventName());
        assertEquals(0L, deserializedEvent.getTimestamp());
        assertEquals("", deserializedEvent.getEventDetails());
    }
    
    @Test
    @Order(6)
    @DisplayName("Test serialization with long event details")
    void testSerializationWithLongDetails() {
        assumeTrue(schemaExists, "Schema must exist for this test to run");
        String longDetails = "This is a very long event details string. ".repeat(100);
        SalesforceAudit auditEvent = new SalesforceAudit(
            "evt-long-001",
            "BulkOperation",
            System.currentTimeMillis(),
            longDetails
        );
        
        byte[] serializedData = JsonSerializer.serialize(client, SCHEMA_NAME, auditEvent);
        assertNotNull(serializedData);
        
        SalesforceAudit deserializedEvent = JsonSerializer.deserialize(client, SCHEMA_NAME, serializedData);
        assertNotNull(deserializedEvent);
        assertEquals(longDetails, deserializedEvent.getEventDetails());
    }
    
    @Test
    @DisplayName("Test deserialization with invalid JSON data throws exception")
    void testDeserializationWithInvalidData() {
        assumeTrue(schemaExists, "Schema must exist for this test to run");
        byte[] invalidData = "{invalid json}".getBytes();
        
        assertThrows(SchemaRegistryException.class, () -> {
            JsonSerializer.deserialize(client, SCHEMA_NAME, invalidData);
        }, "Deserialization should fail for invalid JSON data");
    }
    
    @Test
    @DisplayName("Test deserialization with malformed JSON throws exception")
    void testDeserializationWithMalformedJson() {
        assumeTrue(schemaExists, "Schema must exist for this test to run");
        byte[] malformedData = "{\"eventId\":\"test\"".getBytes(); // Missing closing brace
        
        assertThrows(SchemaRegistryException.class, () -> {
            JsonSerializer.deserialize(client, SCHEMA_NAME, malformedData);
        }, "Deserialization should fail for malformed JSON");
    }
    
    @Test
    @DisplayName("Test JSON output is human-readable")
    void testJsonIsHumanReadable() {
        assumeTrue(schemaExists, "Schema must exist for this test to run");
        SalesforceAudit auditEvent = new SalesforceAudit(
            "event-readable-001",
            "ReadableTest",
            1704067200000L,
            "Testing readability"
        );
        
        byte[] serializedData = JsonSerializer.serialize(client, SCHEMA_NAME, auditEvent);
        String jsonString = new String(serializedData);
        
        // Verify JSON is properly formatted (contains quotes, braces, etc.)
        assertTrue(jsonString.startsWith("{"), "JSON should start with {");
        assertTrue(jsonString.endsWith("}"), "JSON should end with }");
        assertTrue(jsonString.contains("\"eventId\""), "JSON should contain quoted eventId key");
        assertTrue(jsonString.contains("\"eventName\""), "JSON should contain quoted eventName key");
    }
}

