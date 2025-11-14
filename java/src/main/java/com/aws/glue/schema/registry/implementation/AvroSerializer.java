package com.aws.glue.schema.registry.implementation;

import com.aws.glue.schema.registry.client.GlueSchemaRegistryClient;
import com.aws.glue.schema.registry.client.SchemaRegistryException;
import com.aws.glue.schema.registry.implementation.model.SalesforceAudit;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericDatumReader;
import org.apache.avro.generic.GenericDatumWriter;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.io.*;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;

/**
 * Utility class for serializing and deserializing SalesforceAudit objects
 * using Avro schemas retrieved from Glue Schema Registry.
 * Provides static methods for backward compatibility.
 */
public class AvroSerializer {
    
    private static final Logger logger = LogManager.getLogger(AvroSerializer.class);
    
    /**
     * Serializes a SalesforceAudit object to Avro binary format using the schema from Glue Schema Registry.
     * 
     * @param client GlueSchemaRegistryClient instance
     * @param schemaName Name of the schema in the registry
     * @param auditEvent SalesforceAudit object to serialize
     * @return Serialized byte array
     * @throws SchemaRegistryException if serialization fails
     */
    public static byte[] serialize(GlueSchemaRegistryClient client, String schemaName, SalesforceAudit auditEvent) {
        logger.debug("Starting Avro serialization - schema: {}, eventId: {}", 
                schemaName, auditEvent != null ? auditEvent.getEventId() : "null");
        try {
            // Get schema definition from Glue Schema Registry
            var schemaResponse = client.getSchema(schemaName);
            // Get the latest schema version to get the schema definition
            Long latestVersion = schemaResponse.latestSchemaVersion();
            logger.debug("Retrieved schema version {} for schema {}", latestVersion, schemaName);
            var schemaVersionResponse = client.getSchemaVersion(schemaName, latestVersion);
            String schemaDefinition = schemaVersionResponse.schemaDefinition();
            
            // Parse Avro schema
            Schema.Parser parser = new Schema.Parser();
            Schema schema = parser.parse(schemaDefinition);
            logger.trace("Parsed Avro schema for {}", schemaName);
            
            // Create a generic record
            GenericRecord record = new GenericData.Record(schema);
            record.put("eventId", auditEvent.getEventId());
            record.put("eventName", auditEvent.getEventName());
            record.put("timestamp", auditEvent.getTimestamp());
            record.put("eventDetails", auditEvent.getEventDetails());
            
            // Serialize to bytes
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            BinaryEncoder encoder = EncoderFactory.get().binaryEncoder(outputStream, null);
            GenericDatumWriter<GenericRecord> writer = new GenericDatumWriter<>(schema);
            writer.write(record, encoder);
            encoder.flush();
            outputStream.close();
            
            byte[] result = outputStream.toByteArray();
            logger.debug("Avro serialization completed - schema: {}, size: {} bytes", schemaName, result.length);
            return result;
            
        } catch (Exception e) {
            logger.error("Avro serialization failed - schema: {}, error: {}", schemaName, e.getMessage(), e);
            throw new SchemaRegistryException("Failed to serialize SalesforceAudit", e);
        }
    }
    
    /**
     * Deserializes Avro binary data to a SalesforceAudit object using the schema from Glue Schema Registry.
     * 
     * @param client GlueSchemaRegistryClient instance
     * @param schemaName Name of the schema in the registry
     * @param data Serialized byte array
     * @return Deserialized SalesforceAudit object
     * @throws SchemaRegistryException if deserialization fails
     */
    public static SalesforceAudit deserialize(GlueSchemaRegistryClient client, String schemaName, byte[] data) {
        logger.debug("Starting Avro deserialization - schema: {}, data size: {} bytes", 
                schemaName, data != null ? data.length : 0);
        try {
            // Get schema definition from Glue Schema Registry
            var schemaResponse = client.getSchema(schemaName);
            // Get the latest schema version to get the schema definition
            Long latestVersion = schemaResponse.latestSchemaVersion();
            logger.debug("Retrieved schema version {} for schema {}", latestVersion, schemaName);
            var schemaVersionResponse = client.getSchemaVersion(schemaName, latestVersion);
            String schemaDefinition = schemaVersionResponse.schemaDefinition();
            
            // Parse Avro schema
            Schema.Parser parser = new Schema.Parser();
            Schema schema = parser.parse(schemaDefinition);
            logger.trace("Parsed Avro schema for {}", schemaName);
            
            // Deserialize from bytes
            ByteArrayInputStream inputStream = new ByteArrayInputStream(data);
            BinaryDecoder decoder = DecoderFactory.get().binaryDecoder(inputStream, null);
            GenericDatumReader<GenericRecord> reader = new GenericDatumReader<>(schema);
            GenericRecord record = reader.read(null, decoder);
            
            // Create SalesforceAudit object from record
            SalesforceAudit auditEvent = new SalesforceAudit();
            auditEvent.setEventId(record.get("eventId").toString());
            auditEvent.setEventName(record.get("eventName").toString());
            auditEvent.setTimestamp((Long) record.get("timestamp"));
            auditEvent.setEventDetails(record.get("eventDetails").toString());
            
            logger.debug("Avro deserialization completed - schema: {}, eventId: {}", 
                    schemaName, auditEvent.getEventId());
            return auditEvent;
            
        } catch (Exception e) {
            logger.error("Avro deserialization failed - schema: {}, error: {}", schemaName, e.getMessage(), e);
            throw new SchemaRegistryException("Failed to deserialize SalesforceAudit", e);
        }
    }
}
