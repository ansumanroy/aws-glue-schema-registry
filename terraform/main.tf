terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Glue Schema Registry
# Glue Schema Registry
resource "aws_glue_registry" "schema_registry" {
  registry_name = var.registry_name
  description   = var.registry_description
  tags          = var.tags
}


# Glue Schemas from var.schemas
resource "aws_glue_schema" "dynamic_schemas" {
  for_each = var.schemas

  registry_arn     = aws_glue_registry.schema_registry.arn
  schema_name       = each.key
  description       = each.value.description
  data_format       = each.value.data_format
  schema_definition = each.value.schema_definition

  compatibility = lookup(each.value, "compatibility", "BACKWARD")  # default if not provided
  tags          = merge(var.tags, lookup(each.value, "tags", {}))
}

# SalesforceAudit Schema - static schema
resource "aws_glue_schema" "salesforce_audit" {
  registry_arn     = aws_glue_registry.schema_registry.arn
  schema_name              = "SalesforceAudit"
  description       = "Schema for Salesforce audit events with Event ID, Event Name, Timestamp, and Event Details"
  data_format       = "AVRO"
  schema_definition = file("${path.module}/../java/src/main/resources/salesforce-audit.avsc")

  compatibility = var.salesforce_audit_compatibility

  tags = merge(var.tags, {
    Source = "Java Resources"
    Schema = "SalesforceAudit"
  })
}