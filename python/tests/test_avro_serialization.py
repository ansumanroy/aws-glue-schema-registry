"""Test class for serializing and deserializing SalesforceAudit objects
using GlueSchemaRegistryClient with Avro.
"""

import os
import pytest
from glue_schema_registry.client import GlueSchemaRegistryClient
from glue_schema_registry.avro_serializer import AvroSerializer
from glue_schema_registry.model import SalesforceAudit


@pytest.fixture(scope="module")
def client():
    """Initialize the client - assumes AWS credentials are configured."""
    registry_name = os.getenv("GLUE_REGISTRY_NAME", "glue-schema-registry-ansumanroy-6219")
    aws_region = os.getenv("AWS_REGION", "us-east-1")
    client = GlueSchemaRegistryClient(aws_region, registry_name)
    yield client
    client.close()


SCHEMA_NAME = "SalesforceAudit"


class TestSalesforceAuditAvroSerialization:
    """Test class for Avro serialization."""
    
    def test_schema_exists(self, client):
        """Test that SalesforceAudit schema exists in registry."""
        schema_response = client.get_schema(SCHEMA_NAME)
        assert schema_response is not None
        assert schema_response['LatestSchemaVersion'] is not None
        assert schema_response['DataFormat'] == 'AVRO'
    
    def test_serialization(self, client):
        """Test serialization of SalesforceAudit object."""
        audit_event = SalesforceAudit(
            event_id="event-12345",
            event_name="UserLogin",
            timestamp=1704067200000,
            event_details="User logged in successfully from IP 192.168.1.1"
        )
        
        serialized_data = AvroSerializer.serialize(client, SCHEMA_NAME, audit_event)
        assert serialized_data is not None
        assert len(serialized_data) > 0
    
    def test_deserialization(self, client):
        """Test deserialization of Avro bytes to SalesforceAudit object."""
        original_event = SalesforceAudit(
            event_id="event-67890",
            event_name="DataAccess",
            timestamp=1704067200000,
            event_details="User accessed customer data record ID: 98765"
        )
        
        # Serialize first
        serialized_data = AvroSerializer.serialize(client, SCHEMA_NAME, original_event)
        assert serialized_data is not None
        
        # Deserialize
        deserialized_event = AvroSerializer.deserialize(client, SCHEMA_NAME, serialized_data)
        
        # Verify the deserialized object matches the original
        assert deserialized_event is not None
        assert original_event.event_id == deserialized_event.event_id
        assert original_event.event_name == deserialized_event.event_name
        assert original_event.timestamp == deserialized_event.timestamp
        assert original_event.event_details == deserialized_event.event_details
    
    def test_round_trip_serialization(self, client):
        """Test round-trip serialization and deserialization."""
        test_events = [
            SalesforceAudit("evt-001", "Create", 1609459200000, "Created new account"),
            SalesforceAudit("evt-002", "Update", 1609545600000, "Updated contact information"),
            SalesforceAudit("evt-003", "Delete", 1609632000000, "Deleted record ID: 456"),
            SalesforceAudit("evt-004", "Export", 1609718400000, "Exported report: MonthlySales")
        ]
        
        for original_event in test_events:
            # Serialize
            serialized_data = AvroSerializer.serialize(client, SCHEMA_NAME, original_event)
            assert serialized_data is not None
            
            # Deserialize
            deserialized_event = AvroSerializer.deserialize(client, SCHEMA_NAME, serialized_data)
            assert deserialized_event is not None
            
            # Verify all fields match
            assert original_event.event_id == deserialized_event.event_id
            assert original_event.event_name == deserialized_event.event_name
            assert original_event.timestamp == deserialized_event.timestamp
            assert original_event.event_details == deserialized_event.event_details
    
    def test_serialization_with_empty_strings(self, client):
        """Test serialization with empty strings."""
        audit_event = SalesforceAudit("", "", 0, "")
        
        serialized_data = AvroSerializer.serialize(client, SCHEMA_NAME, audit_event)
        assert serialized_data is not None
        
        deserialized_event = AvroSerializer.deserialize(client, SCHEMA_NAME, serialized_data)
        assert deserialized_event is not None
        assert deserialized_event.event_id == ""
        assert deserialized_event.event_name == ""
        assert deserialized_event.timestamp == 0
        assert deserialized_event.event_details == ""
    
    def test_serialization_with_long_details(self, client):
        """Test serialization with long event details."""
        long_details = "This is a very long event details string. " * 100
        audit_event = SalesforceAudit(
            "evt-long-001",
            "BulkOperation",
            1704067200000,
            long_details
        )
        
        serialized_data = AvroSerializer.serialize(client, SCHEMA_NAME, audit_event)
        assert serialized_data is not None
        
        deserialized_event = AvroSerializer.deserialize(client, SCHEMA_NAME, serialized_data)
        assert deserialized_event is not None
        assert deserialized_event.event_details == long_details
    
    def test_deserialization_with_invalid_data(self, client):
        """Test deserialization with invalid data throws exception."""
        invalid_data = bytes([1, 2, 3, 4, 5])
        
        from glue_schema_registry.client import SchemaRegistryException
        with pytest.raises(SchemaRegistryException):
            AvroSerializer.deserialize(client, SCHEMA_NAME, invalid_data)

