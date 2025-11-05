# ============================================================================
# Glue Schema Registry - Root Configuration
# ============================================================================
# This configuration uses the reusable schema-registry module located in
# modules/schema-registry/ to create and manage AWS Glue Schema Registry.
#
# The module automatically discovers schemas from the schemas/ directory
# and supports both file-based and manual schema definitions.
# ============================================================================

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

# Glue Schema Registry Module
# This module creates the registry and automatically discovers schemas from
# the schemas/ directory structure. See modules/schema-registry/README.md
# for detailed module documentation.
module "glue_schema_registry" {
  source = "./modules/schema-registry"

  registry_name         = var.registry_name
  registry_description  = var.registry_description
  schemas_base_path     = var.schemas_base_path
  default_compatibility = var.default_compatibility
  schemas               = var.schemas
  tags                  = var.tags
}
