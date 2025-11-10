"""Utility class for serializing and deserializing SalesforceAudit objects
using Avro schemas retrieved from Glue Schema Registry.
"""

import io
import json
from typing import ByteString
from fastavro import parse_schema, schemaless_writer, schemaless_reader
from glue_schema_registry.client import GlueSchemaRegistryClient, SchemaRegistryException
from glue_schema_registry.model import SalesforceAudit


class AvroSerializer:
    """Utility class for Avro serialization/deserialization."""
    
    @staticmethod
    def serialize(client: GlueSchemaRegistryClient, schema_name: str, 
                  audit_event: SalesforceAudit) -> bytes:
        """Serializes a SalesforceAudit object to Avro binary format.
        
        Args:
            client: GlueSchemaRegistryClient instance
            schema_name: Name of the schema in the registry
            audit_event: SalesforceAudit object to serialize
            
        Returns:
            Serialized byte array
            
        Raises:
            SchemaRegistryException: if serialization fails
        """
        try:
            # Get schema definition from Glue Schema Registry
            schema_response = client.get_schema(schema_name)
            latest_version = schema_response['LatestSchemaVersion']
            schema_version_response = client.get_schema_version(schema_name, latest_version)
            schema_definition = schema_version_response['SchemaDefinition']
            
            # Parse Avro schema
            schema_dict = json.loads(schema_definition)
            avro_schema = parse_schema(schema_dict)
            
            # Create a record
            record = {
                'eventId': audit_event.event_id,
                'eventName': audit_event.event_name,
                'timestamp': audit_event.timestamp,
                'eventDetails': audit_event.event_details
            }
            
            # Serialize to bytes
            bytes_writer = io.BytesIO()
            schemaless_writer(bytes_writer, avro_schema, record)
            return bytes_writer.getvalue()
            
        except Exception as e:
            raise SchemaRegistryException(f"Failed to serialize SalesforceAudit: {e}")
    
    @staticmethod
    def deserialize(client: GlueSchemaRegistryClient, schema_name: str, 
                   data: ByteString) -> SalesforceAudit:
        """Deserializes Avro binary data to a SalesforceAudit object.
        
        Args:
            client: GlueSchemaRegistryClient instance
            schema_name: Name of the schema in the registry
            data: Serialized byte array
            
        Returns:
            Deserialized SalesforceAudit object
            
        Raises:
            SchemaRegistryException: if deserialization fails
        """
        try:
            # Get schema definition from Glue Schema Registry
            schema_response = client.get_schema(schema_name)
            latest_version = schema_response['LatestSchemaVersion']
            schema_version_response = client.get_schema_version(schema_name, latest_version)
            schema_definition = schema_version_response['SchemaDefinition']
            
            # Parse Avro schema
            schema_dict = json.loads(schema_definition)
            avro_schema = parse_schema(schema_dict)
            
            # Deserialize from bytes
            bytes_reader = io.BytesIO(data)
            record = schemaless_reader(bytes_reader, avro_schema)
            
            # Create SalesforceAudit object from record
            return SalesforceAudit(
                event_id=record['eventId'],
                event_name=record['eventName'],
                timestamp=record['timestamp'],
                event_details=record['eventDetails']
            )
            
        except Exception as e:
            raise SchemaRegistryException(f"Failed to deserialize SalesforceAudit: {e}")

