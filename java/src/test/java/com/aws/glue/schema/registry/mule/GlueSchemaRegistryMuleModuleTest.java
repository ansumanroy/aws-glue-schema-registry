package com.aws.glue.schema.registry.mule;

import com.aws.glue.schema.registry.client.GlueSchemaRegistryClient;
import com.aws.glue.schema.registry.client.SchemaRegistryException;
import com.aws.glue.schema.registry.config.GlueSchemaRegistryConfig;
import com.aws.glue.schema.registry.implementation.model.SalesforceAudit;
import org.junit.jupiter.api.*;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.glue.model.DataFormat;
import software.amazon.awssdk.services.glue.model.GetSchemaResponse;
import software.amazon.awssdk.services.glue.model.GetSchemaVersionResponse;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * Test class for GlueSchemaRegistryMuleModule.
 * Tests factory methods, serialization/deserialization, and exception handling.
 */
@DisplayName("GlueSchemaRegistryMuleModule Tests")
class GlueSchemaRegistryMuleModuleTest {
    
    private static final String REGISTRY_NAME = "test-registry";
    private static final String SCHEMA_NAME_AVRO = "SalesforceAudit";
    private static final String SCHEMA_NAME_JSON = "SalesAuditJSON";
    private static final String AVRO_SCHEMA_DEFINITION = "{\n" +
            "  \"type\": \"record\",\n" +
            "  \"name\": \"SalesforceAudit\",\n" +
            "  \"namespace\": \"com.aws.glue.schema.registry\",\n" +
            "  \"fields\": [\n" +
            "    {\"name\": \"eventId\", \"type\": \"string\"},\n" +
            "    {\"name\": \"eventName\", \"type\": \"string\"},\n" +
            "    {\"name\": \"timestamp\", \"type\": \"long\"},\n" +
            "    {\"name\": \"eventDetails\", \"type\": \"string\"}\n" +
            "  ]\n" +
            "}";
    
    @Mock
    private GlueSchemaRegistryClient mockClient;
    
    private GlueSchemaRegistryMuleModule module;
    private AutoCloseable mocks;
    
    @BeforeEach
    void setUp() {
        mocks = MockitoAnnotations.openMocks(this);
        setupMockClient();
        module = GlueSchemaRegistryMuleModule.create(mockClient);
    }
    
    @AfterEach
    void tearDown() throws Exception {
        if (mocks != null) {
            mocks.close();
        }
    }
    
    /**
     * Sets up mock responses for the client.
     */
    private void setupMockClient() {
        // Mock GetSchemaResponse for Avro
        GetSchemaResponse avroSchemaResponse = GetSchemaResponse.builder()
                .schemaName(SCHEMA_NAME_AVRO)
                .dataFormat(DataFormat.AVRO)
                .latestSchemaVersion(1L)
                .build();
        
        // Mock GetSchemaVersionResponse for Avro
        GetSchemaVersionResponse avroSchemaVersionResponse = GetSchemaVersionResponse.builder()
                .schemaDefinition(AVRO_SCHEMA_DEFINITION)
                .versionNumber(1L)
                .build();
        
        // Mock GetSchemaResponse for JSON
        GetSchemaResponse jsonSchemaResponse = GetSchemaResponse.builder()
                .schemaName(SCHEMA_NAME_JSON)
                .dataFormat(DataFormat.JSON)
                .latestSchemaVersion(1L)
                .build();
        
        // Mock GetSchemaVersionResponse for JSON (schema definition not used for JSON serialization)
        GetSchemaVersionResponse jsonSchemaVersionResponse = GetSchemaVersionResponse.builder()
                .schemaDefinition("{}")
                .versionNumber(1L)
                .build();
        
        // Configure mock to return appropriate responses
        when(mockClient.getSchema(SCHEMA_NAME_AVRO)).thenReturn(avroSchemaResponse);
        when(mockClient.getSchemaVersion(eq(SCHEMA_NAME_AVRO), anyLong())).thenReturn(avroSchemaVersionResponse);
        when(mockClient.getSchema(SCHEMA_NAME_JSON)).thenReturn(jsonSchemaResponse);
        when(mockClient.getSchemaVersion(eq(SCHEMA_NAME_JSON), anyLong())).thenReturn(jsonSchemaVersionResponse);
    }
    
    @Test
    @DisplayName("Test create() factory method with MuleSoft properties")
    void testCreateWithMuleSoftProperties() {
        // This test verifies the factory method can be called
        // In a real MuleSoft environment, it would read from MuleSoft properties
        // For unit testing, we test with explicit config
        GlueSchemaRegistryConfig config = GlueSchemaRegistryConfig.builder()
                .registryName(REGISTRY_NAME)
                .region(Region.US_EAST_1)
                .build();
        
        GlueSchemaRegistryMuleModule module = GlueSchemaRegistryMuleModule.create(config);
        assertNotNull(module);
        assertNotNull(module.getClient());
    }
    
    @Test
    @DisplayName("Test create(GlueSchemaRegistryConfig) factory method")
    void testCreateWithConfig() {
        GlueSchemaRegistryConfig config = GlueSchemaRegistryConfig.builder()
                .registryName(REGISTRY_NAME)
                .region(Region.US_EAST_1)
                .build();
        
        GlueSchemaRegistryMuleModule module = GlueSchemaRegistryMuleModule.create(config);
        
        assertNotNull(module);
        assertNotNull(module.getClient());
    }
    
    @Test
    @DisplayName("Test create(GlueSchemaRegistryClient) factory method")
    void testCreateWithClient() {
        GlueSchemaRegistryMuleModule module = GlueSchemaRegistryMuleModule.create(mockClient);
        
        assertNotNull(module);
        assertEquals(mockClient, module.getClient());
    }
    
    @Test
    @DisplayName("Test serializeAvro() with valid data")
    void testSerializeAvroSuccess() {
        SalesforceAudit auditEvent = new SalesforceAudit(
                "event-12345",
                "UserLogin",
                System.currentTimeMillis(),
                "User logged in successfully"
        );
        
        byte[] serialized = module.serializeAvro(SCHEMA_NAME_AVRO, auditEvent);
        
        assertNotNull(serialized);
        assertTrue(serialized.length > 0, "Serialized data should not be empty");
        
        verify(mockClient, atLeastOnce()).getSchema(SCHEMA_NAME_AVRO);
        verify(mockClient, atLeastOnce()).getSchemaVersion(eq(SCHEMA_NAME_AVRO), anyLong());
    }
    
    @Test
    @DisplayName("Test deserializeAvro() with valid data")
    void testDeserializeAvroSuccess() {
        // First serialize to get valid Avro bytes
        SalesforceAudit originalEvent = new SalesforceAudit(
                "event-67890",
                "DataAccess",
                1704067200000L,
                "User accessed customer data"
        );
        
        byte[] serialized = module.serializeAvro(SCHEMA_NAME_AVRO, originalEvent);
        assertNotNull(serialized);
        
        // Reset mock to allow deserialization calls
        setupMockClient();
        
        // Deserialize
        SalesforceAudit deserialized = module.deserializeAvro(SCHEMA_NAME_AVRO, serialized);
        
        assertNotNull(deserialized);
        assertEquals(originalEvent.getEventId(), deserialized.getEventId());
        assertEquals(originalEvent.getEventName(), deserialized.getEventName());
        assertEquals(originalEvent.getTimestamp(), deserialized.getTimestamp());
        assertEquals(originalEvent.getEventDetails(), deserialized.getEventDetails());
    }
    
    @Test
    @DisplayName("Test round-trip Avro serialization and deserialization")
    void testRoundTripAvro() {
        SalesforceAudit originalEvent = new SalesforceAudit(
                "evt-roundtrip-001",
                "RoundTripTest",
                1609459200000L,
                "Testing round-trip serialization"
        );
        
        // Serialize
        byte[] serialized = module.serializeAvro(SCHEMA_NAME_AVRO, originalEvent);
        assertNotNull(serialized);
        
        // Reset mock for deserialization
        setupMockClient();
        
        // Deserialize
        SalesforceAudit deserialized = module.deserializeAvro(SCHEMA_NAME_AVRO, serialized);
        
        // Verify all fields match
        assertEquals(originalEvent, deserialized);
        assertEquals(originalEvent.hashCode(), deserialized.hashCode());
    }
    
    @Test
    @DisplayName("Test serializeJson() with valid data")
    void testSerializeJsonSuccess() {
        SalesforceAudit auditEvent = new SalesforceAudit(
                "event-json-001",
                "JsonTest",
                System.currentTimeMillis(),
                "Testing JSON serialization"
        );
        
        byte[] serialized = module.serializeJson(SCHEMA_NAME_JSON, auditEvent);
        
        assertNotNull(serialized);
        assertTrue(serialized.length > 0, "Serialized data should not be empty");
        
        // Verify it's valid JSON
        String jsonString = new String(serialized);
        assertTrue(jsonString.contains("eventId"));
        assertTrue(jsonString.contains("eventName"));
        
        verify(mockClient, atLeastOnce()).getSchema(SCHEMA_NAME_JSON);
    }
    
    @Test
    @DisplayName("Test deserializeJson() with valid data")
    void testDeserializeJsonSuccess() {
        // First serialize to get valid JSON bytes
        SalesforceAudit originalEvent = new SalesforceAudit(
                "event-json-002",
                "JsonDeserializeTest",
                1704067200000L,
                "Testing JSON deserialization"
        );
        
        byte[] serialized = module.serializeJson(SCHEMA_NAME_JSON, originalEvent);
        assertNotNull(serialized);
        
        // Reset mock to allow deserialization calls
        setupMockClient();
        
        // Deserialize
        SalesforceAudit deserialized = module.deserializeJson(SCHEMA_NAME_JSON, serialized);
        
        assertNotNull(deserialized);
        assertEquals(originalEvent.getEventId(), deserialized.getEventId());
        assertEquals(originalEvent.getEventName(), deserialized.getEventName());
        assertEquals(originalEvent.getTimestamp(), deserialized.getTimestamp());
        assertEquals(originalEvent.getEventDetails(), deserialized.getEventDetails());
    }
    
    @Test
    @DisplayName("Test round-trip JSON serialization and deserialization")
    void testRoundTripJson() {
        SalesforceAudit originalEvent = new SalesforceAudit(
                "evt-json-roundtrip-001",
                "JsonRoundTripTest",
                1609459200000L,
                "Testing JSON round-trip serialization"
        );
        
        // Serialize
        byte[] serialized = module.serializeJson(SCHEMA_NAME_JSON, originalEvent);
        assertNotNull(serialized);
        
        // Reset mock for deserialization
        setupMockClient();
        
        // Deserialize
        SalesforceAudit deserialized = module.deserializeJson(SCHEMA_NAME_JSON, serialized);
        
        // Verify all fields match
        assertEquals(originalEvent, deserialized);
        assertEquals(originalEvent.hashCode(), deserialized.hashCode());
    }
    
    @Test
    @DisplayName("Test serializeAvro() throws RuntimeException on SchemaRegistryException")
    void testSerializeAvroExceptionHandling() {
        // Configure mock to throw exception
        when(mockClient.getSchema(anyString())).thenThrow(
                new SchemaRegistryException(SchemaRegistryException.ErrorCode.SCHEMA_NOT_FOUND, "Schema not found")
        );
        
        SalesforceAudit auditEvent = new SalesforceAudit(
                "event-error",
                "ErrorTest",
                System.currentTimeMillis(),
                "Testing error handling"
        );
        
        // Should throw RuntimeException (MuleSoft-compatible)
        assertThrows(RuntimeException.class, () -> {
            module.serializeAvro("NonExistentSchema", auditEvent);
        }, "Should throw RuntimeException when serialization fails");
    }
    
    @Test
    @DisplayName("Test deserializeAvro() throws RuntimeException on SchemaRegistryException")
    void testDeserializeAvroExceptionHandling() {
        // Configure mock to throw exception
        when(mockClient.getSchema(anyString())).thenThrow(
                new SchemaRegistryException(SchemaRegistryException.ErrorCode.SCHEMA_NOT_FOUND, "Schema not found")
        );
        
        byte[] invalidData = new byte[]{1, 2, 3, 4, 5};
        
        // Should throw RuntimeException (MuleSoft-compatible)
        assertThrows(RuntimeException.class, () -> {
            module.deserializeAvro("NonExistentSchema", invalidData);
        }, "Should throw RuntimeException when deserialization fails");
    }
    
    @Test
    @DisplayName("Test serializeJson() throws RuntimeException on SchemaRegistryException")
    void testSerializeJsonExceptionHandling() {
        // Configure mock to throw exception
        when(mockClient.getSchema(anyString())).thenThrow(
                new SchemaRegistryException(SchemaRegistryException.ErrorCode.SCHEMA_NOT_FOUND, "Schema not found")
        );
        
        SalesforceAudit auditEvent = new SalesforceAudit(
                "event-error",
                "ErrorTest",
                System.currentTimeMillis(),
                "Testing error handling"
        );
        
        // Should throw RuntimeException (MuleSoft-compatible)
        assertThrows(RuntimeException.class, () -> {
            module.serializeJson("NonExistentSchema", auditEvent);
        }, "Should throw RuntimeException when serialization fails");
    }
    
    @Test
    @DisplayName("Test deserializeJson() throws RuntimeException on SchemaRegistryException")
    void testDeserializeJsonExceptionHandling() {
        // Configure mock to throw exception
        when(mockClient.getSchema(anyString())).thenThrow(
                new SchemaRegistryException(SchemaRegistryException.ErrorCode.SCHEMA_NOT_FOUND, "Schema not found")
        );
        
        byte[] invalidData = "{invalid json}".getBytes();
        
        // Should throw RuntimeException (MuleSoft-compatible)
        assertThrows(RuntimeException.class, () -> {
            module.deserializeJson("NonExistentSchema", invalidData);
        }, "Should throw RuntimeException when deserialization fails");
    }
    
    @Test
    @DisplayName("Test getClient() returns the underlying client")
    void testGetClient() {
        GlueSchemaRegistryClient client = module.getClient();
        
        assertNotNull(client);
        assertEquals(mockClient, client);
    }
    
    @Test
    @DisplayName("Test close() method completes without error")
    void testClose() {
        // close() should not throw an exception
        assertDoesNotThrow(() -> {
            module.close();
        }, "close() should complete without error");
    }
    
    @Test
    @DisplayName("Test serialization with empty strings")
    void testSerializationWithEmptyStrings() {
        SalesforceAudit auditEvent = new SalesforceAudit("", "", 0L, "");
        
        // Test Avro
        byte[] avroSerialized = module.serializeAvro(SCHEMA_NAME_AVRO, auditEvent);
        assertNotNull(avroSerialized);
        setupMockClient();
        SalesforceAudit avroDeserialized = module.deserializeAvro(SCHEMA_NAME_AVRO, avroSerialized);
        assertEquals("", avroDeserialized.getEventId());
        assertEquals("", avroDeserialized.getEventName());
        
        // Test JSON
        setupMockClient();
        byte[] jsonSerialized = module.serializeJson(SCHEMA_NAME_JSON, auditEvent);
        assertNotNull(jsonSerialized);
        setupMockClient();
        SalesforceAudit jsonDeserialized = module.deserializeJson(SCHEMA_NAME_JSON, jsonSerialized);
        assertEquals("", jsonDeserialized.getEventId());
        assertEquals("", jsonDeserialized.getEventName());
    }
    
    @Test
    @DisplayName("Test serialization with long event details")
    void testSerializationWithLongDetails() {
        String longDetails = "This is a very long event details string. ".repeat(100);
        SalesforceAudit auditEvent = new SalesforceAudit(
                "evt-long-001",
                "BulkOperation",
                System.currentTimeMillis(),
                longDetails
        );
        
        // Test Avro
        byte[] avroSerialized = module.serializeAvro(SCHEMA_NAME_AVRO, auditEvent);
        assertNotNull(avroSerialized);
        setupMockClient();
        SalesforceAudit avroDeserialized = module.deserializeAvro(SCHEMA_NAME_AVRO, avroSerialized);
        assertEquals(longDetails, avroDeserialized.getEventDetails());
        
        // Test JSON
        setupMockClient();
        byte[] jsonSerialized = module.serializeJson(SCHEMA_NAME_JSON, auditEvent);
        assertNotNull(jsonSerialized);
        setupMockClient();
        SalesforceAudit jsonDeserialized = module.deserializeJson(SCHEMA_NAME_JSON, jsonSerialized);
        assertEquals(longDetails, jsonDeserialized.getEventDetails());
    }
    
    @Test
    @DisplayName("Test deserializeAvro() with invalid data throws exception")
    void testDeserializeAvroWithInvalidData() {
        byte[] invalidData = new byte[]{1, 2, 3, 4, 5};
        
        assertThrows(RuntimeException.class, () -> {
            module.deserializeAvro(SCHEMA_NAME_AVRO, invalidData);
        }, "Deserialization should fail for invalid Avro data");
    }
    
    @Test
    @DisplayName("Test deserializeJson() with invalid JSON throws exception")
    void testDeserializeJsonWithInvalidData() {
        byte[] invalidData = "{invalid json}".getBytes();
        
        assertThrows(RuntimeException.class, () -> {
            module.deserializeJson(SCHEMA_NAME_JSON, invalidData);
        }, "Deserialization should fail for invalid JSON data");
    }
    
    @Test
    @DisplayName("Test fromJsonString() with valid JSON string")
    void testFromJsonStringSuccess() {
        String jsonString = "{\"eventId\":\"event-json-util-001\",\"eventName\":\"JsonUtilTest\",\"timestamp\":1704067200000,\"eventDetails\":\"Testing JSON string conversion\"}";
        
        SalesforceAudit result = module.fromJsonString(jsonString);
        
        assertNotNull(result);
        assertEquals("event-json-util-001", result.getEventId());
        assertEquals("JsonUtilTest", result.getEventName());
        assertEquals(1704067200000L, result.getTimestamp());
        assertEquals("Testing JSON string conversion", result.getEventDetails());
    }
    
    @Test
    @DisplayName("Test fromJsonString() with null string throws exception")
    void testFromJsonStringWithNull() {
        assertThrows(RuntimeException.class, () -> {
            module.fromJsonString(null);
        }, "Should throw exception when JSON string is null");
    }
    
    @Test
    @DisplayName("Test fromJsonString() with empty string throws exception")
    void testFromJsonStringWithEmptyString() {
        assertThrows(RuntimeException.class, () -> {
            module.fromJsonString("");
        }, "Should throw exception when JSON string is empty");
    }
    
    @Test
    @DisplayName("Test fromJsonString() with whitespace-only string throws exception")
    void testFromJsonStringWithWhitespace() {
        assertThrows(RuntimeException.class, () -> {
            module.fromJsonString("   ");
        }, "Should throw exception when JSON string is only whitespace");
    }
    
    @Test
    @DisplayName("Test fromJsonString() with invalid JSON throws exception")
    void testFromJsonStringWithInvalidJson() {
        String invalidJson = "{invalid json}";
        
        assertThrows(RuntimeException.class, () -> {
            module.fromJsonString(invalidJson);
        }, "Should throw exception when JSON string is invalid");
    }
    
    @Test
    @DisplayName("Test fromJsonString() with missing fields")
    void testFromJsonStringWithMissingFields() {
        String jsonString = "{\"eventId\":\"event-partial-001\",\"eventName\":\"PartialTest\"}";
        
        SalesforceAudit result = module.fromJsonString(jsonString);
        
        assertNotNull(result);
        assertEquals("event-partial-001", result.getEventId());
        assertEquals("PartialTest", result.getEventName());
        // Missing fields should be null or default values
        assertEquals(0L, result.getTimestamp());
        assertNull(result.getEventDetails());
    }
    
    @Test
    @DisplayName("Test fromJsonBytes() with valid JSON bytes")
    void testFromJsonBytesSuccess() {
        String jsonString = "{\"eventId\":\"event-json-bytes-001\",\"eventName\":\"JsonBytesTest\",\"timestamp\":1704067200000,\"eventDetails\":\"Testing JSON bytes conversion\"}";
        byte[] jsonBytes = jsonString.getBytes();
        
        SalesforceAudit result = module.fromJsonBytes(jsonBytes);
        
        assertNotNull(result);
        assertEquals("event-json-bytes-001", result.getEventId());
        assertEquals("JsonBytesTest", result.getEventName());
        assertEquals(1704067200000L, result.getTimestamp());
        assertEquals("Testing JSON bytes conversion", result.getEventDetails());
    }
    
    @Test
    @DisplayName("Test fromJsonBytes() with null bytes throws exception")
    void testFromJsonBytesWithNull() {
        assertThrows(RuntimeException.class, () -> {
            module.fromJsonBytes(null);
        }, "Should throw exception when JSON bytes are null");
    }
    
    @Test
    @DisplayName("Test fromJsonBytes() with empty bytes throws exception")
    void testFromJsonBytesWithEmptyBytes() {
        assertThrows(RuntimeException.class, () -> {
            module.fromJsonBytes(new byte[0]);
        }, "Should throw exception when JSON bytes are empty");
    }
    
    @Test
    @DisplayName("Test fromJsonBytes() with invalid JSON throws exception")
    void testFromJsonBytesWithInvalidJson() {
        byte[] invalidJson = "{invalid json}".getBytes();
        
        assertThrows(RuntimeException.class, () -> {
            module.fromJsonBytes(invalidJson);
        }, "Should throw exception when JSON bytes are invalid");
    }
    
    @Test
    @DisplayName("Test fromJsonString() round-trip with serializeJson()")
    void testFromJsonStringRoundTrip() {
        SalesforceAudit originalEvent = new SalesforceAudit(
                "event-roundtrip-001",
                "RoundTripTest",
                1704067200000L,
                "Testing round-trip conversion"
        );
        
        // Serialize to JSON using the module
        byte[] serialized = module.serializeJson(SCHEMA_NAME_JSON, originalEvent);
        String jsonString = new String(serialized);
        
        // Convert back using fromJsonString
        SalesforceAudit converted = module.fromJsonString(jsonString);
        
        assertEquals(originalEvent, converted);
        assertEquals(originalEvent.hashCode(), converted.hashCode());
    }
    
    @Test
    @DisplayName("Test fromJsonBytes() round-trip with serializeJson()")
    void testFromJsonBytesRoundTrip() {
        SalesforceAudit originalEvent = new SalesforceAudit(
                "event-roundtrip-002",
                "RoundTripBytesTest",
                1704067200000L,
                "Testing round-trip bytes conversion"
        );
        
        // Serialize to JSON using the module
        byte[] serialized = module.serializeJson(SCHEMA_NAME_JSON, originalEvent);
        
        // Convert back using fromJsonBytes
        SalesforceAudit converted = module.fromJsonBytes(serialized);
        
        assertEquals(originalEvent, converted);
        assertEquals(originalEvent.hashCode(), converted.hashCode());
    }
    
    @Test
    @DisplayName("Test fromJsonString() with all fields populated")
    void testFromJsonStringWithAllFields() {
        String jsonString = "{\"eventId\":\"event-full-001\",\"eventName\":\"FullFieldsTest\",\"timestamp\":1609459200000,\"eventDetails\":\"All fields are populated in this test\"}";
        
        SalesforceAudit result = module.fromJsonString(jsonString);
        
        assertNotNull(result);
        assertEquals("event-full-001", result.getEventId());
        assertEquals("FullFieldsTest", result.getEventName());
        assertEquals(1609459200000L, result.getTimestamp());
        assertEquals("All fields are populated in this test", result.getEventDetails());
    }
    
    @Test
    @DisplayName("Test fromJsonBytes() with UTF-8 encoding")
    void testFromJsonBytesWithUtf8() {
        String jsonString = "{\"eventId\":\"event-utf8-001\",\"eventName\":\"UTF8Test\",\"timestamp\":1704067200000,\"eventDetails\":\"Testing UTF-8 encoding: émojis 🎉\"}";
        byte[] jsonBytes = jsonString.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        
        SalesforceAudit result = module.fromJsonBytes(jsonBytes);
        
        assertNotNull(result);
        assertEquals("event-utf8-001", result.getEventId());
        assertTrue(result.getEventDetails().contains("émojis"));
    }
    
    @Test
    @DisplayName("Test fromJsonString() static method in JsonSerializer")
    void testJsonSerializerFromJsonString() {
        String jsonString = "{\"eventId\":\"event-static-001\",\"eventName\":\"StaticTest\",\"timestamp\":1704067200000,\"eventDetails\":\"Testing static method\"}";
        
        SalesforceAudit result = com.aws.glue.schema.registry.implementation.JsonSerializer.fromJsonString(jsonString);
        
        assertNotNull(result);
        assertEquals("event-static-001", result.getEventId());
        assertEquals("StaticTest", result.getEventName());
    }
    
    @Test
    @DisplayName("Test fromJsonBytes() static method in JsonSerializer")
    void testJsonSerializerFromJsonBytes() {
        String jsonString = "{\"eventId\":\"event-static-bytes-001\",\"eventName\":\"StaticBytesTest\",\"timestamp\":1704067200000,\"eventDetails\":\"Testing static bytes method\"}";
        byte[] jsonBytes = jsonString.getBytes();
        
        SalesforceAudit result = com.aws.glue.schema.registry.implementation.JsonSerializer.fromJsonBytes(jsonBytes);
        
        assertNotNull(result);
        assertEquals("event-static-bytes-001", result.getEventId());
        assertEquals("StaticBytesTest", result.getEventName());
    }
}

