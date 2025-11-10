# AWS Glue Schema Registry - Golang Client

Golang wrapper client for AWS Glue Schema Registry with Avro and JSON serialization support.

## Overview

This Go package provides:
- **Client**: A wrapper library for interacting with AWS Glue Schema Registry
- **Avro Serialization**: Serialize/deserialize objects using Avro schemas
- **JSON Serialization**: Serialize/deserialize objects using JSON schemas
- **Model Classes**: Data models for schema objects

## Installation

```bash
go mod download
```

## Quick Start

```go
package main

import (
    "github.com/aws-glue-schema-registry/golang/client"
    "github.com/aws-glue-schema-registry/golang/model"
    "github.com/aws-glue-schema-registry/golang/serializer"
)

func main() {
    // Initialize client
    c, err := client.NewGlueSchemaRegistryClient("us-east-1", "my-registry")
    if err != nil {
        panic(err)
    }
    defer c.Close()

    // Create an audit event
    auditEvent := &model.SalesforceAudit{
        EventID:      "event-123",
        EventName:    "UserLogin",
        Timestamp:    1704067200000,
        EventDetails: "User logged in",
    }

    // Serialize
    avroSerializer := &serializer.AvroSerializer{}
    serialized, err := avroSerializer.Serialize(c, "SalesforceAudit", auditEvent)
    if err != nil {
        panic(err)
    }

    // Deserialize
    deserialized, err := avroSerializer.Deserialize(c, "SalesforceAudit", serialized)
    if err != nil {
        panic(err)
    }
}
```

## Running Tests

```bash
go test ./...
```

With verbose output:

```bash
go test -v ./...
```

## Project Structure

```
golang/
├── client/
│   ├── client.go           # Glue Schema Registry client
│   └── client_test.go      # Client tests
├── model/
│   └── salesforce_audit.go # Data models
├── serializer/
│   ├── avro_serializer.go  # Avro serialization
│   ├── json_serializer.go   # JSON serialization
│   ├── avro_serializer_test.go
│   └── json_serializer_test.go
├── go.mod
├── go.sum
└── README.md
```

## Environment Variables

- `GLUE_REGISTRY_NAME`: Name of the Glue Schema Registry (default: "glue-schema-registry-ansumanroy-6219")
- `AWS_REGION`: AWS region (default: "us-east-1")
- AWS credentials should be configured via AWS CLI or environment variables

## License

See [LICENSE](../LICENSE) file for details.

