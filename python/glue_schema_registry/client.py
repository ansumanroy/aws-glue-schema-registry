"""Java wrapper client for AWS Glue Schema Registry.
Provides a simplified interface to interact with Glue Schema Registry.
"""

import boto3
from botocore.exceptions import ClientError
from typing import List, Optional
from enum import Enum


class Compatibility(Enum):
    """Schema compatibility modes"""
    BACKWARD = "BACKWARD"
    BACKWARD_ALL = "BACKWARD_ALL"
    DISABLED = "DISABLED"
    FORWARD = "FORWARD"
    FORWARD_ALL = "FORWARD_ALL"
    FULL = "FULL"
    FULL_ALL = "FULL_ALL"
    NONE = "NONE"


class SchemaRegistryException(Exception):
    """Custom exception for Glue Schema Registry operations."""
    pass


class GlueSchemaRegistryClient:
    """Java wrapper client for AWS Glue Schema Registry."""
    
    def __init__(self, region_name: str, registry_name: str, 
                 aws_access_key_id: Optional[str] = None,
                 aws_secret_access_key: Optional[str] = None,
                 aws_session_token: Optional[str] = None):
        """Constructs a new GlueSchemaRegistryClient.
        
        Args:
            region_name: AWS region where the schema registry is located
            registry_name: Name of the Glue Schema Registry
            aws_access_key_id: Optional AWS access key ID
            aws_secret_access_key: Optional AWS secret access key
            aws_session_token: Optional AWS session token
        """
        self.registry_name = registry_name
        
        # Create Glue client
        session = boto3.Session()
        self.glue_client = session.client(
            'glue',
            region_name=region_name,
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key,
            aws_session_token=aws_session_token
        )
    
    def create_schema(self, schema_name: str, data_format: str, 
                     schema_definition: str, compatibility: Compatibility) -> dict:
        """Creates a new schema in the registry.
        
        Args:
            schema_name: Name of the schema
            data_format: Data format (AVRO, JSON, PROTOBUF)
            schema_definition: Schema definition string
            compatibility: Compatibility mode
            
        Returns:
            Created schema information
        """
        try:
            response = self.glue_client.create_schema(
                RegistryId={'RegistryName': self.registry_name},
                SchemaName=schema_name,
                DataFormat=data_format.upper(),
                SchemaDefinition=schema_definition,
                Compatibility=compatibility.value
            )
            return response
        except ClientError as e:
            raise SchemaRegistryException(f"Failed to create schema: {e}")
    
    def get_schema(self, schema_name: str) -> dict:
        """Gets a schema by name.
        
        Args:
            schema_name: Name of the schema
            
        Returns:
            Schema information
        """
        try:
            response = self.glue_client.get_schema(
                SchemaId={
                    'RegistryName': self.registry_name,
                    'SchemaName': schema_name
                }
            )
            return response
        except ClientError as e:
            raise SchemaRegistryException(f"Failed to get schema: {e}")
    
    def get_schema_version(self, schema_name: str, version_number: int) -> dict:
        """Gets a specific version of a schema.
        
        Args:
            schema_name: Name of the schema
            version_number: Version number of the schema
            
        Returns:
            Schema version information
        """
        try:
            response = self.glue_client.get_schema_version(
                SchemaId={
                    'RegistryName': self.registry_name,
                    'SchemaName': schema_name
                },
                SchemaVersionNumber={'VersionNumber': version_number}
            )
            return response
        except ClientError as e:
            raise SchemaRegistryException(f"Failed to get schema version: {e}")
    
    def list_schemas(self) -> List[dict]:
        """Lists all schemas in the registry.
        
        Returns:
            List of schema summaries
        """
        try:
            response = self.glue_client.list_schemas(
                RegistryId={'RegistryName': self.registry_name}
            )
            return response.get('Schemas', [])
        except ClientError as e:
            raise SchemaRegistryException(f"Failed to list schemas: {e}")
    
    def update_schema_compatibility(self, schema_name: str, 
                                   compatibility: Compatibility) -> dict:
        """Updates schema compatibility mode.
        
        Args:
            schema_name: Name of the schema
            compatibility: New compatibility mode
            
        Returns:
            Update response
        """
        try:
            schema = self.get_schema(schema_name)
            response = self.glue_client.update_schema(
                SchemaId={
                    'RegistryName': self.registry_name,
                    'SchemaName': schema_name
                },
                Compatibility=compatibility.value,
                Description=schema.get('Description', '')
            )
            return response
        except ClientError as e:
            raise SchemaRegistryException(f"Failed to update schema compatibility: {e}")
    
    def register_schema_version(self, schema_name: str, 
                               schema_definition: str) -> dict:
        """Registers a new version of a schema.
        
        Args:
            schema_name: Name of the schema
            schema_definition: New schema definition
            
        Returns:
            Registered schema version
        """
        try:
            response = self.glue_client.register_schema_version(
                SchemaId={
                    'RegistryName': self.registry_name,
                    'SchemaName': schema_name
                },
                SchemaDefinition=schema_definition
            )
            return response
        except ClientError as e:
            raise SchemaRegistryException(f"Failed to register schema version: {e}")
    
    def close(self):
        """Closes the underlying Glue client."""
        # boto3 clients don't need explicit closing, but kept for API consistency
        pass

