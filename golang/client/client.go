package client

import (
	"fmt"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/glue"
)

// Compatibility represents schema compatibility modes
type Compatibility string

const (
	CompatibilityBackward     Compatibility = "BACKWARD"
	CompatibilityBackwardAll Compatibility = "BACKWARD_ALL"
	CompatibilityDisabled    Compatibility = "DISABLED"
	CompatibilityForward      Compatibility = "FORWARD"
	CompatibilityForwardAll   Compatibility = "FORWARD_ALL"
	CompatibilityFull        Compatibility = "FULL"
	CompatibilityFullAll    Compatibility = "FULL_ALL"
	CompatibilityNone         Compatibility = "NONE"
)

// SchemaRegistryException is a custom exception for Glue Schema Registry operations
type SchemaRegistryException struct {
	Message string
	Err     error
}

func (e *SchemaRegistryException) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %v", e.Message, e.Err)
	}
	return e.Message
}

// GlueSchemaRegistryClient is a wrapper client for AWS Glue Schema Registry
type GlueSchemaRegistryClient struct {
	glueClient   *glue.Glue
	registryName string
}

// NewGlueSchemaRegistryClient creates a new GlueSchemaRegistryClient with default AWS credentials
func NewGlueSchemaRegistryClient(region, registryName string) (*GlueSchemaRegistryClient, error) {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create AWS session: %w", err)
	}

	return &GlueSchemaRegistryClient{
		glueClient:   glue.New(sess),
		registryName: registryName,
	}, nil
}

// CreateSchema creates a new schema in the registry
func (c *GlueSchemaRegistryClient) CreateSchema(schemaName, dataFormat, schemaDefinition string, compatibility Compatibility) (*glue.CreateSchemaOutput, error) {
	input := &glue.CreateSchemaInput{
		RegistryId: &glue.RegistryId{
			RegistryName: aws.String(c.registryName),
		},
		SchemaName:      aws.String(schemaName),
		DataFormat:      aws.String(dataFormat),
		SchemaDefinition: aws.String(schemaDefinition),
		Compatibility:   aws.String(string(compatibility)),
	}

	result, err := c.glueClient.CreateSchema(input)
	if err != nil {
		return nil, &SchemaRegistryException{
			Message: fmt.Sprintf("Failed to create schema: %s", schemaName),
			Err:     err,
		}
	}

	return result, nil
}

// GetSchema gets a schema by name
func (c *GlueSchemaRegistryClient) GetSchema(schemaName string) (*glue.GetSchemaOutput, error) {
	input := &glue.GetSchemaInput{
		SchemaId: &glue.SchemaId{
			RegistryName: aws.String(c.registryName),
			SchemaName:   aws.String(schemaName),
		},
	}

	result, err := c.glueClient.GetSchema(input)
	if err != nil {
		return nil, &SchemaRegistryException{
			Message: fmt.Sprintf("Failed to get schema: %s", schemaName),
			Err:     err,
		}
	}

	return result, nil
}

// GetSchemaVersion gets a specific version of a schema
func (c *GlueSchemaRegistryClient) GetSchemaVersion(schemaName string, versionNumber int64) (*glue.GetSchemaVersionOutput, error) {
	input := &glue.GetSchemaVersionInput{
		SchemaId: &glue.SchemaId{
			RegistryName: aws.String(c.registryName),
			SchemaName:   aws.String(schemaName),
		},
		SchemaVersionNumber: &glue.SchemaVersionNumber{
			VersionNumber: aws.Int64(versionNumber),
		},
	}

	result, err := c.glueClient.GetSchemaVersion(input)
	if err != nil {
		return nil, &SchemaRegistryException{
			Message: fmt.Sprintf("Failed to get schema version: %s (version %d)", schemaName, versionNumber),
			Err:     err,
		}
	}

	return result, nil
}

// ListSchemas lists all schemas in the registry
func (c *GlueSchemaRegistryClient) ListSchemas() ([]*glue.SchemaListItem, error) {
	input := &glue.ListSchemasInput{
		RegistryId: &glue.RegistryId{
			RegistryName: aws.String(c.registryName),
		},
	}

	result, err := c.glueClient.ListSchemas(input)
	if err != nil {
		return nil, &SchemaRegistryException{
			Message: "Failed to list schemas",
			Err:     err,
		}
	}

	return result.Schemas, nil
}

// UpdateSchemaCompatibility updates schema compatibility mode
func (c *GlueSchemaRegistryClient) UpdateSchemaCompatibility(schemaName string, compatibility Compatibility) (*glue.UpdateSchemaOutput, error) {
	// First get the schema to preserve description
	schema, err := c.GetSchema(schemaName)
	if err != nil {
		return nil, err
	}

	input := &glue.UpdateSchemaInput{
		SchemaId: &glue.SchemaId{
			RegistryName: aws.String(c.registryName),
			SchemaName:   aws.String(schemaName),
		},
		Compatibility: aws.String(string(compatibility)),
	}

	if schema.Description != nil {
		input.Description = schema.Description
	}

	result, err := c.glueClient.UpdateSchema(input)
	if err != nil {
		return nil, &SchemaRegistryException{
			Message: fmt.Sprintf("Failed to update schema compatibility: %s", schemaName),
			Err:     err,
		}
	}

	return result, nil
}

// RegisterSchemaVersion registers a new version of a schema
func (c *GlueSchemaRegistryClient) RegisterSchemaVersion(schemaName, schemaDefinition string) (*glue.RegisterSchemaVersionOutput, error) {
	input := &glue.RegisterSchemaVersionInput{
		SchemaId: &glue.SchemaId{
			RegistryName: aws.String(c.registryName),
			SchemaName:   aws.String(schemaName),
		},
		SchemaDefinition: aws.String(schemaDefinition),
	}

	result, err := c.glueClient.RegisterSchemaVersion(input)
	if err != nil {
		return nil, &SchemaRegistryException{
			Message: fmt.Sprintf("Failed to register schema version: %s", schemaName),
			Err:     err,
		}
	}

	return result, nil
}

// Close closes the underlying Glue client (no-op for AWS SDK)
func (c *GlueSchemaRegistryClient) Close() {
	// AWS SDK doesn't require explicit closing
}

