package testconfig

import (
	"bufio"
	"os"
	"path/filepath"
	"strings"
)

// TestConfig holds test configuration values
type TestConfig struct {
	RegistryName  string
	AWSRegion     string
	AvroSchemaName string
	JsonSchemaName string
}

var config *TestConfig

// LoadConfig loads configuration from file and environment variables
func LoadConfig() *TestConfig {
	if config != nil {
		return config
	}

	config = &TestConfig{
		RegistryName:    "glue-schema-registry-ansumanroy-6219",
		AWSRegion:       "us-east-1",
		AvroSchemaName:  "SalesforceAudit",
		JsonSchemaName:  "SalesAuditJSON",
	}

	// Load from file
	loadFromFile(config)

	// Override with environment variables
	if envValue := os.Getenv("GLUE_REGISTRY_NAME"); envValue != "" {
		config.RegistryName = envValue
	}
	if envValue := os.Getenv("AWS_REGION"); envValue != "" {
		config.AWSRegion = envValue
	}
	if envValue := os.Getenv("SCHEMA_NAME_AVRO"); envValue != "" {
		config.AvroSchemaName = envValue
	}
	if envValue := os.Getenv("SCHEMA_NAME_JSON"); envValue != "" {
		config.JsonSchemaName = envValue
	}

	return config
}

// loadFromFile loads configuration from test-config.properties file
func loadFromFile(cfg *TestConfig) {
	// Try multiple paths to find the config file
	possiblePaths := []string{
		"testdata/test-config.properties",
		"golang/testdata/test-config.properties",
		filepath.Join(filepath.Dir(os.Args[0]), "testdata", "test-config.properties"),
	}
	
	var file *os.File
	var err error
	for _, configFile := range possiblePaths {
		file, err = os.Open(configFile)
		if err == nil {
			break
		}
	}
	
	if err != nil {
		// File not found, use defaults
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		// Skip comments and empty lines
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}

		key := strings.TrimSpace(parts[0])
		value := strings.TrimSpace(parts[1])

		switch key {
		case "glue.registry.name":
			cfg.RegistryName = value
		case "aws.region":
			cfg.AWSRegion = value
		case "schema.name.avro":
			cfg.AvroSchemaName = value
		case "schema.name.json":
			cfg.JsonSchemaName = value
		}
	}
}

// GetRegistryName returns the registry name
func GetRegistryName() string {
	return LoadConfig().RegistryName
}

// GetAWSRegion returns the AWS region
func GetAWSRegion() string {
	return LoadConfig().AWSRegion
}

// GetAvroSchemaName returns the Avro schema name
func GetAvroSchemaName() string {
	return LoadConfig().AvroSchemaName
}

// GetJsonSchemaName returns the JSON schema name
func GetJsonSchemaName() string {
	return LoadConfig().JsonSchemaName
}

