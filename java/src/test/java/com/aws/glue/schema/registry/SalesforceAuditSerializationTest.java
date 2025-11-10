package com.aws.glue.schema.registry;

import com.aws.glue.schema.registry.client.GlueSchemaRegistryClient;
import com.aws.glue.schema.registry.client.SchemaRegistryException;
import com.aws.glue.schema.registry.config.TestConfig;
import com.aws.glue.schema.registry.implementation.AvroSerializer;
import com.aws.glue.schema.registry.implementation.model.SalesforceAudit;
import org.junit.jupiter.api.*;
import software.amazon.awssdk.regions.Region;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Test class for serializing and deserializing SalesforceAudit objects
 * using GlueSchemaRegistryClient.
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class SalesforceAuditSerializationTest {
    
    private static GlueSchemaRegistryClient client;
    private static final String REGISTRY_NAME = TestConfig.getRegistryName();
    private static final Region AWS_REGION = TestConfig.getAWSRegion();
    private static final String SCHEMA_NAME = TestConfig.getAvroSchemaName();
    
    @BeforeAll
    static void setUp() {
        // Initialize the client - assumes AWS credentials are configured
        client = new GlueSchemaRegistryClient(AWS_REGION, REGISTRY_NAME);
    }
    
    @AfterAll
    static void tearDown() {
        if (client != null) {
            client.close();
        }
    }
    
    @Test
    @Order(1)
    @DisplayName("Test that SalesforceAudit schema exists in registry")
    void testSchemaExists() {
        // Verify the schema exists in the registry
        assertDoesNotThrow(() -> {
            var schemaResponse = client.getSchema(SCHEMA_NAME);
            assertNotNull(schemaResponse);
            assertNotNull(schemaResponse.latestSchemaVersion());
            assertEquals("AVRO", schemaResponse.dataFormat().toString());
        }, "Schema should exist in the registry");
    }
    
    @Test
    @Order(2)
    @DisplayName("Test serialization of SalesforceAudit object")
    void testSerialization() {
        // Create a test SalesforceAudit object
        SalesforceAudit auditEvent = new SalesforceAudit(
            "event-12345",
            "UserLogin",
            System.currentTimeMillis(),
            "User logged in successfully from IP 192.168.1.1"
        );
        
        // Serialize the object
        assertDoesNotThrow(() -> {
            byte[] serializedData = AvroSerializer.serialize(client, SCHEMA_NAME, auditEvent);
            
            assertNotNull(serializedData);
            assertTrue(serializedData.length > 0, "Serialized data should not be empty");
            
            System.out.println("Serialized " + serializedData.length + " bytes");
        }, "Serialization should succeed");
    }
    
    @Test
    @Order(3)
    @DisplayName("Test deserialization of Avro bytes to SalesforceAudit object")
    void testDeserialization() {
        // Create a test SalesforceAudit object
        SalesforceAudit originalEvent = new SalesforceAudit(
            "event-67890",
            "DataAccess",
            1704067200000L, // Fixed timestamp for testing
            "User accessed customer data record ID: 98765"
        );
        
        // Serialize first
        byte[] serializedData = AvroSerializer.serialize(client, SCHEMA_NAME, originalEvent);
        assertNotNull(serializedData);
        
        // Deserialize
        SalesforceAudit deserializedEvent = AvroSerializer.deserialize(client, SCHEMA_NAME, serializedData);
        
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
        // Create test objects with different values
        SalesforceAudit[] testEvents = {
            new SalesforceAudit("evt-001", "Create", 1609459200000L, "Created new account"),
            new SalesforceAudit("evt-002", "Update", 1609545600000L, "Updated contact information"),
            new SalesforceAudit("evt-003", "Delete", 1609632000000L, "Deleted record ID: 456"),
            new SalesforceAudit("evt-004", "Export", 1609718400000L, "Exported report: MonthlySales")
        };
        
        for (SalesforceAudit originalEvent : testEvents) {
            // Serialize
            byte[] serializedData = AvroSerializer.serialize(client, SCHEMA_NAME, originalEvent);
            assertNotNull(serializedData);
            
            // Deserialize
            SalesforceAudit deserializedEvent = AvroSerializer.deserialize(client, SCHEMA_NAME, serializedData);
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
        SalesforceAudit auditEvent = new SalesforceAudit(
            "",
            "",
            0L,
            ""
        );
        
        byte[] serializedData = AvroSerializer.serialize(client, SCHEMA_NAME, auditEvent);
        assertNotNull(serializedData);
        
        SalesforceAudit deserializedEvent = AvroSerializer.deserialize(client, SCHEMA_NAME, serializedData);
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
        String longDetails = "This is a very long event details string. ".repeat(100);
        SalesforceAudit auditEvent = new SalesforceAudit(
            "evt-long-001",
            "BulkOperation",
            System.currentTimeMillis(),
            longDetails
        );
        
        byte[] serializedData = AvroSerializer.serialize(client, SCHEMA_NAME, auditEvent);
        assertNotNull(serializedData);
        
        SalesforceAudit deserializedEvent = AvroSerializer.deserialize(client, SCHEMA_NAME, serializedData);
        assertNotNull(deserializedEvent);
        assertEquals(longDetails, deserializedEvent.getEventDetails());
    }
    
    @Test
    @DisplayName("Test deserialization with invalid data throws exception")
    void testDeserializationWithInvalidData() {
        byte[] invalidData = new byte[]{1, 2, 3, 4, 5};
        
        assertThrows(SchemaRegistryException.class, () -> {
            AvroSerializer.deserialize(client, SCHEMA_NAME, invalidData);
        }, "Deserialization should fail for invalid data");
    }
}
