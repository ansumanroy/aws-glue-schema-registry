"""Test class for serializing and deserializing SalesforceAudit objects
using GlueSchemaRegistryClient with JSON.
"""

import os
import pytest
from glue_schema_registry.client import GlueSchemaRegistryClient
from glue_schema_registry.json_serializer import JsonSerializer
from glue_schema_registry.model import SalesforceAudit


@pytest.fixture(scope="module")
def client():
    """Initialize the client - assumes AWS credentials are configured."""
    registry_name = os.getenv("GLUE_REGISTRY_NAME", "glue-schema-registry-ansumanroy-6219")
    aws_region = os.getenv("AWS_REGION", "us-east-1")
    client = GlueSchemaRegistryClient(aws_region, registry_name)
    yield client
    client.close()


SCHEMA_NAME = "SalesAuditJSON"


class TestSalesforceAuditJsonSerialization:
    """Test class for JSON serialization."""
    
    def test_schema_exists(self, client):
        """Test that SalesAuditJSON schema exists in registry."""
        schema_response = client.get_schema(SCHEMA_NAME)
        assert schema_response is not None
        assert schema_response['LatestSchemaVersion'] is not None
        assert schema_response['DataFormat'] == 'JSON'
    
    def test_serialization(self, client):
        """Test serialization of SalesforceAudit object."""
        audit_event = SalesforceAudit(
            event_id="event-12345",
            event_name="UserLogin",
            timestamp=1704067200000,
            event_details="User logged in successfully from IP 192.168.1.1"
        )
        
        serialized_data = JsonSerializer.serialize(client, SCHEMA_NAME, audit_event)
        assert serialized_data is not None
        assert len(serialized_data) > 0
    
    def test_deserialization(self, client):
        """Test deserialization of JSON bytes to SalesforceAudit object."""
        original_event = SalesforceAudit(
            event_id="event-67890",
            event_name="DataAccess",
            timestamp=1704067200000,
            event_details="User accessed customer data record ID: 98765"
        )
        
        # Serialize first
        serialized_data = JsonSerializer.serialize(client, SCHEMA_NAME, original_event)
        assert serialized_data is not None
        
        # Deserialize
        deserialized_event = JsonSerializer.deserialize(client, SCHEMA_NAME, serialized_data)
        
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
            serialized_data = JsonSerializer.serialize(client, SCHEMA_NAME, original_event)
            assert serialized_data is not None
            
            # Deserialize
            deserialized_event = JsonSerializer.deserialize(client, SCHEMA_NAME, serialized_data)
            assert deserialized_event is not None
            
            # Verify all fields match
            assert original_event.event_id == deserialized_event.event_id
            assert original_event.event_name == deserialized_event.event_name
            assert original_event.timestamp == deserialized_event.timestamp
            assert original_event.event_details == deserialized_event.event_details

