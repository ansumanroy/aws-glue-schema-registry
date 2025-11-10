package serializer

import (
	"encoding/json"
	"fmt"

	"github.com/aws-glue-schema-registry/golang/client"
	"github.com/aws-glue-schema-registry/golang/model"
	"github.com/linkedin/goavro/v2"
)

// AvroSerializer provides Avro serialization/deserialization
type AvroSerializer struct{}

// Serialize serializes a SalesforceAudit object to Avro binary format
func (s *AvroSerializer) Serialize(c *client.GlueSchemaRegistryClient, schemaName string, auditEvent *model.SalesforceAudit) ([]byte, error) {
	// Get schema definition from Glue Schema Registry
	schemaResponse, err := c.GetSchema(schemaName)
	if err != nil {
		return nil, fmt.Errorf("failed to get schema: %w", err)
	}

	latestVersion := *schemaResponse.LatestSchemaVersion
	schemaVersionResponse, err := c.GetSchemaVersion(schemaName, latestVersion)
	if err != nil {
		return nil, fmt.Errorf("failed to get schema version: %w", err)
	}

	schemaDefinition := *schemaVersionResponse.SchemaDefinition

	// Parse Avro schema
	var schemaJSON map[string]interface{}
	if err := json.Unmarshal([]byte(schemaDefinition), &schemaJSON); err != nil {
		return nil, fmt.Errorf("failed to parse schema definition: %w", err)
	}

	codec, err := goavro.NewCodec(schemaDefinition)
	if err != nil {
		return nil, fmt.Errorf("failed to create Avro codec: %w", err)
	}

	// Create a record
	record := auditEvent.ToMap()

	// Serialize to bytes using BinaryFromNative
	binary, err := codec.BinaryFromNative(nil, record)
	if err != nil {
		return nil, fmt.Errorf("failed to encode record: %w", err)
	}

	return binary, nil
}

// Deserialize deserializes Avro binary data to a SalesforceAudit object
func (s *AvroSerializer) Deserialize(c *client.GlueSchemaRegistryClient, schemaName string, data []byte) (*model.SalesforceAudit, error) {
	// Get schema definition from Glue Schema Registry
	schemaResponse, err := c.GetSchema(schemaName)
	if err != nil {
		return nil, fmt.Errorf("failed to get schema: %w", err)
	}

	latestVersion := *schemaResponse.LatestSchemaVersion
	schemaVersionResponse, err := c.GetSchemaVersion(schemaName, latestVersion)
	if err != nil {
		return nil, fmt.Errorf("failed to get schema version: %w", err)
	}

	schemaDefinition := *schemaVersionResponse.SchemaDefinition

	// Parse Avro schema
	codec, err := goavro.NewCodec(schemaDefinition)
	if err != nil {
		return nil, fmt.Errorf("failed to create Avro codec: %w", err)
	}

	// Deserialize from bytes using NativeFromBinary
	datum, _, err := codec.NativeFromBinary(data)
	if err != nil {
		return nil, fmt.Errorf("failed to decode record: %w", err)
	}

	// Convert to map
	record, ok := datum.(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("unexpected datum type: %T", datum)
	}

	// Create SalesforceAudit object from record
	auditEvent := &model.SalesforceAudit{}
	auditEvent.FromMap(record)

	return auditEvent, nil
}
