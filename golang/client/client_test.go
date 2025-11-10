package client_test

import (
	"os"
	"testing"

	"github.com/aws-glue-schema-registry/golang/client"
)

func getRegistryName() string {
	if name := os.Getenv("GLUE_REGISTRY_NAME"); name != "" {
		return name
	}
	return "glue-schema-registry-ansumanroy-6219"
}

func getAWSRegion() string {
	if region := os.Getenv("AWS_REGION"); region != "" {
		return region
	}
	return "us-east-1"
}

func TestGetSchema(t *testing.T) {
	c, err := client.NewGlueSchemaRegistryClient(getAWSRegion(), getRegistryName())
	if err != nil {
		t.Fatalf("Failed to create client: %v", err)
	}
	defer c.Close()

	schemaName := "SalesforceAudit"
	schema, err := c.GetSchema(schemaName)
	if err != nil {
		t.Fatalf("Failed to get schema: %v", err)
	}

	if schema == nil {
		t.Fatal("Schema response is nil")
	}

	if schema.LatestSchemaVersion == nil {
		t.Fatal("LatestSchemaVersion is nil")
	}

	if schema.DataFormat == nil || *schema.DataFormat != "AVRO" {
		t.Errorf("Expected DataFormat to be AVRO, got %v", schema.DataFormat)
	}
}

