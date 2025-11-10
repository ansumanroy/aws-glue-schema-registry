package serializer_test

import (
	"testing"

	"github.com/aws-glue-schema-registry/golang/client"
	"github.com/aws-glue-schema-registry/golang/model"
	"github.com/aws-glue-schema-registry/golang/serializer"
)

func TestJsonSerialization(t *testing.T) {
	c, err := client.NewGlueSchemaRegistryClient(getAWSRegion(), getRegistryName())
	if err != nil {
		t.Fatalf("Failed to create client: %v", err)
	}
	defer c.Close()

	schemaName := "SalesAuditJSON"
	jsonSerializer := &serializer.JsonSerializer{}

	// Create test event
	originalEvent := &model.SalesforceAudit{
		EventID:      "event-12345",
		EventName:    "UserLogin",
		Timestamp:    1704067200000,
		EventDetails: "User logged in successfully",
	}

	// Serialize
	serializedData, err := jsonSerializer.Serialize(c, schemaName, originalEvent)
	if err != nil {
		t.Fatalf("Failed to serialize: %v", err)
	}

	if len(serializedData) == 0 {
		t.Fatal("Serialized data is empty")
	}

	// Deserialize
	deserializedEvent, err := jsonSerializer.Deserialize(c, schemaName, serializedData)
	if err != nil {
		t.Fatalf("Failed to deserialize: %v", err)
	}

	// Verify
	if originalEvent.EventID != deserializedEvent.EventID {
		t.Errorf("EventID mismatch: expected %s, got %s", originalEvent.EventID, deserializedEvent.EventID)
	}
	if originalEvent.EventName != deserializedEvent.EventName {
		t.Errorf("EventName mismatch: expected %s, got %s", originalEvent.EventName, deserializedEvent.EventName)
	}
	if originalEvent.Timestamp != deserializedEvent.Timestamp {
		t.Errorf("Timestamp mismatch: expected %d, got %d", originalEvent.Timestamp, deserializedEvent.Timestamp)
	}
	if originalEvent.EventDetails != deserializedEvent.EventDetails {
		t.Errorf("EventDetails mismatch: expected %s, got %s", originalEvent.EventDetails, deserializedEvent.EventDetails)
	}
}

