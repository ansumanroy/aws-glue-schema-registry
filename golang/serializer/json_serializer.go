package serializer

import (
	"encoding/json"
	"fmt"

	"github.com/aws-glue-schema-registry/golang/client"
	"github.com/aws-glue-schema-registry/golang/model"
)

// JsonSerializer provides JSON serialization/deserialization
type JsonSerializer struct{}

// Serialize serializes a SalesforceAudit object to JSON format
func (s *JsonSerializer) Serialize(c *client.GlueSchemaRegistryClient, schemaName string, auditEvent *model.SalesforceAudit) ([]byte, error) {
	// Get schema definition from Glue Schema Registry
	schemaResponse, err := c.GetSchema(schemaName)
	if err != nil {
		return nil, fmt.Errorf("failed to get schema: %w", err)
	}

	latestVersion := *schemaResponse.LatestSchemaVersion
	_, err = c.GetSchemaVersion(schemaName, latestVersion)
	if err != nil {
		return nil, fmt.Errorf("failed to get schema version: %w", err)
	}

	// Note: In production, you might want to validate the JSON
	// against the schema definition before serialization using a JSON Schema validator

	// Serialize to JSON bytes
	jsonBytes, err := json.Marshal(auditEvent)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal JSON: %w", err)
	}

	return jsonBytes, nil
}

// Deserialize deserializes JSON data to a SalesforceAudit object
func (s *JsonSerializer) Deserialize(c *client.GlueSchemaRegistryClient, schemaName string, data []byte) (*model.SalesforceAudit, error) {
	// Get schema definition from Glue Schema Registry
	schemaResponse, err := c.GetSchema(schemaName)
	if err != nil {
		return nil, fmt.Errorf("failed to get schema: %w", err)
	}

	latestVersion := *schemaResponse.LatestSchemaVersion
	_, err = c.GetSchemaVersion(schemaName, latestVersion)
	if err != nil {
		return nil, fmt.Errorf("failed to get schema version: %w", err)
	}

	// Note: In production, you might want to validate the JSON
	// against the schema definition after deserialization using a JSON Schema validator

	// Deserialize from JSON bytes
	var auditEvent model.SalesforceAudit
	if err := json.Unmarshal(data, &auditEvent); err != nil {
		return nil, fmt.Errorf("failed to unmarshal JSON: %w", err)
	}

	return &auditEvent, nil
}

