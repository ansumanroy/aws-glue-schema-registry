"""Utility class for serializing and deserializing SalesforceAudit objects
using JSON schemas retrieved from Glue Schema Registry.
"""

import json
from typing import ByteString
from glue_schema_registry.client import GlueSchemaRegistryClient, SchemaRegistryException
from glue_schema_registry.model import SalesforceAudit


class JsonSerializer:
    """Utility class for JSON serialization/deserialization."""
    
    @staticmethod
    def serialize(client: GlueSchemaRegistryClient, schema_name: str, 
                  audit_event: SalesforceAudit) -> bytes:
        """Serializes a SalesforceAudit object to JSON format.
        
        Args:
            client: GlueSchemaRegistryClient instance
            schema_name: Name of the schema in the registry
            audit_event: SalesforceAudit object to serialize
            
        Returns:
            Serialized byte array (JSON)
            
        Raises:
            SchemaRegistryException: if serialization fails
        """
        try:
            # Get schema definition from Glue Schema Registry
            schema_response = client.get_schema(schema_name)
            latest_version = schema_response['LatestSchemaVersion']
            schema_version_response = client.get_schema_version(schema_name, latest_version)
            # Note: In production, you might want to validate against the schema
            
            # Serialize to JSON bytes
            json_str = json.dumps(audit_event.to_dict())
            return json_str.encode('utf-8')
            
        except Exception as e:
            raise SchemaRegistryException(f"Failed to serialize SalesforceAudit to JSON: {e}")
    
    @staticmethod
    def deserialize(client: GlueSchemaRegistryClient, schema_name: str, 
                   data: ByteString) -> SalesforceAudit:
        """Deserializes JSON data to a SalesforceAudit object.
        
        Args:
            client: GlueSchemaRegistryClient instance
            schema_name: Name of the schema in the registry
            data: Serialized JSON byte array
            
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
            # Note: In production, you might want to validate against the schema
            
            # Deserialize from JSON bytes
            json_str = data.decode('utf-8')
            data_dict = json.loads(json_str)
            return SalesforceAudit.from_dict(data_dict)
            
        except Exception as e:
            raise SchemaRegistryException(f"Failed to deserialize JSON to SalesforceAudit: {e}")

