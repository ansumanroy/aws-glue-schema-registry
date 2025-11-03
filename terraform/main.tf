terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Glue Schema Registry
resource "aws_glue_registry" "schema_registry" {
  registry_name = var.registry_name
  description    = var.registry_description
  tags           = var.tags
}

# Glue Schema Registry Schema
resource "aws_glue_schema" "schema" {
  for_each = var.schemas

  schema_id {
    registry_name = aws_glue_registry.schema_registry.registry_name
    schema_name   = each.key
  }
  description       = each.value.description
  data_format       = each.value.data_format
  schema_definition = each.value.schema_definition
  
  compatibility = each.value.compatibility
  tags          = merge(var.tags, each.value.tags)
}

# SalesforceAudit Schema - reads from Java resources
resource "aws_glue_schema" "salesforce_audit" {
  schema_id {
    registry_name = aws_glue_registry.schema_registry.registry_name
    schema_name   = "SalesforceAudit"
  }
  description       = "Schema for Salesforce audit events with Event ID, Event Name, Timestamp, and Event Details"
  data_format       = "AVRO"
  schema_definition = file("${path.module}/../java/src/main/resources/salesforce-audit.avsc")
  
  compatibility = var.salesforce_audit_compatibility
  tags          = merge(var.tags, {
    Source = "Java Resources"
    Schema = "SalesforceAudit"
  })
}
