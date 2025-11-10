package client_test

import (
	"testing"

	"github.com/aws-glue-schema-registry/golang/client"
	"github.com/aws-glue-schema-registry/golang/testconfig"
)

func TestGetSchema(t *testing.T) {
	cfg := testconfig.LoadConfig()
	c, err := client.NewGlueSchemaRegistryClient(cfg.AWSRegion, cfg.RegistryName)
	if err != nil {
		t.Fatalf("Failed to create client: %v", err)
	}
	defer c.Close()

	schemaName := cfg.AvroSchemaName
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

