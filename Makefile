.PHONY: help build test clean java-test java-build java-clean terraform-init terraform-plan terraform-apply terraform-destroy terraform-validate terraform-fmt terraform-output deploy check-aws check-terraform check-gradle

# Default target
.DEFAULT_GOAL := help

# Variables
JAVA_DIR := java
TERRAFORM_DIR := terraform
AWS_REGION ?= us-east-1
TF_VAR_REGISTRY_NAME ?= $(shell echo "glue-schema-registry-$$(whoami)-$$(date +%s | tail -c 5)" | tr '[:upper:]' '[:lower:]')
TF_VAR_AWS_REGION ?= $(AWS_REGION)
TF_VAR_SALESFORCE_AUDIT_COMPATIBILITY ?= BACKWARD

# Colors for output
COLOR_RESET := \033[0m
COLOR_BOLD := \033[1m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE := \033[34m

##@ General

help: ## Display this help message
	@echo "$(COLOR_BOLD)Available targets:$(COLOR_RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_GREEN)%-20s$(COLOR_RESET) %s\n", $$1, $$2}'

##@ Java/Gradle Build

java-build: check-gradle ## Build Java project using Gradle
	@echo "$(COLOR_BLUE)Building Java project...$(COLOR_RESET)"
	cd $(JAVA_DIR) && ./gradlew build --no-daemon

java-test: check-gradle ## Run Java tests
	@echo "$(COLOR_BLUE)Running Java tests...$(COLOR_RESET)"
	cd $(JAVA_DIR) && ./gradlew test --no-daemon

java-clean: check-gradle ## Clean Java build artifacts
	@echo "$(COLOR_BLUE)Cleaning Java build...$(COLOR_RESET)"
	cd $(JAVA_DIR) && ./gradlew clean --no-daemon

java-jar: java-build ## Build Java JAR file
	@echo "$(COLOR_BLUE)Building JAR...$(COLOR_RESET)"
	cd $(JAVA_DIR) && ./gradlew jar --no-daemon
	@echo "$(COLOR_GREEN)JAR created: $(JAVA_DIR)/build/libs/schema-registry-client-1.0.0-SNAPSHOT.jar$(COLOR_RESET)"

java-avro: check-gradle ## Generate Avro classes from schema
	@echo "$(COLOR_BLUE)Generating Avro classes...$(COLOR_RESET)"
	cd $(JAVA_DIR) && ./gradlew generateAvroJava --no-daemon

##@ Terraform

terraform-init: check-terraform check-aws ## Initialize Terraform with S3 backend
	@echo "$(COLOR_BLUE)Initializing Terraform with S3 backend...$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)S3 Backend: aws-glue-assets-651914028873-us-east-1$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)State Key: terraform/glue-schema-registry/terraform.tfstate$(COLOR_RESET)"
	cd $(TERRAFORM_DIR) && terraform init

terraform-validate: check-terraform terraform-init ## Validate Terraform configuration
	@echo "$(COLOR_BLUE)Validating Terraform configuration...$(COLOR_RESET)"
	cd $(TERRAFORM_DIR) && terraform validate

terraform-fmt: check-terraform ## Format Terraform files
	@echo "$(COLOR_BLUE)Formatting Terraform files...$(COLOR_RESET)"
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

terraform-plan: check-terraform terraform-init check-aws ## Generate Terraform execution plan
	@echo "$(COLOR_BLUE)Generating Terraform plan...$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Registry Name: $(TF_VAR_REGISTRY_NAME)$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)AWS Region: $(TF_VAR_AWS_REGION)$(COLOR_RESET)"
	cd $(TERRAFORM_DIR) && terraform plan \
		-var="aws_region=$(TF_VAR_AWS_REGION)" \
		-var="registry_name=$(TF_VAR_REGISTRY_NAME)" \
		-var="salesforce_audit_compatibility=$(TF_VAR_SALESFORCE_AUDIT_COMPATIBILITY)"

terraform-apply: check-terraform terraform-init check-aws ## Apply Terraform configuration (deploy to AWS)
	@echo "$(COLOR_BLUE)Deploying Terraform configuration to AWS...$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Registry Name: $(TF_VAR_REGISTRY_NAME)$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)AWS Region: $(TF_VAR_AWS_REGION)$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)This will create resources in AWS. Continue? [y/N]$(COLOR_RESET)" && read ans && [ $${ans:-N} = y ]
	cd $(TERRAFORM_DIR) && terraform apply \
		-var="aws_region=$(TF_VAR_AWS_REGION)" \
		-var="registry_name=$(TF_VAR_REGISTRY_NAME)" \
		-var="salesforce_audit_compatibility=$(TF_VAR_SALESFORCE_AUDIT_COMPATIBILITY)" \
		-auto-approve
	@echo "$(COLOR_GREEN)Deployment completed!$(COLOR_RESET)"

terraform-destroy: check-terraform check-aws ## Destroy Terraform infrastructure
	@echo "$(COLOR_YELLOW)WARNING: This will destroy all Terraform-managed infrastructure!$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Continue? [y/N]$(COLOR_RESET)" && read ans && [ $${ans:-N} = y ]
	cd $(TERRAFORM_DIR) && terraform destroy \
		-var="aws_region=$(TF_VAR_AWS_REGION)" \
		-var="registry_name=$(TF_VAR_REGISTRY_NAME)" \
		-var="salesforce_audit_compatibility=$(TF_VAR_SALESFORCE_AUDIT_COMPATIBILITY)" \
		-auto-approve
	@echo "$(COLOR_GREEN)Infrastructure destroyed!$(COLOR_RESET)"

terraform-output: check-terraform ## Show Terraform outputs
	@echo "$(COLOR_BLUE)Terraform outputs:$(COLOR_RESET)"
	cd $(TERRAFORM_DIR) && terraform output

terraform-plan-apply: terraform-plan terraform-apply ## Plan and apply Terraform (with confirmation)

terraform-refresh: check-terraform terraform-init ## Refresh Terraform state
	@echo "$(COLOR_BLUE)Refreshing Terraform state...$(COLOR_RESET)"
	cd $(TERRAFORM_DIR) && terraform refresh \
		-var="aws_region=$(TF_VAR_AWS_REGION)" \
		-var="registry_name=$(TF_VAR_REGISTRY_NAME)" \
		-var="salesforce_audit_compatibility=$(TF_VAR_SALESFORCE_AUDIT_COMPATIBILITY)"

##@ Combined Operations

deploy: check-aws terraform-validate terraform-plan-apply ## Full deployment: validate, plan, and apply Terraform
	@echo "$(COLOR_GREEN)Deployment completed successfully!$(COLOR_RESET)"

build: java-build ## Build everything (Java)

test: java-test ## Run all tests

clean: java-clean ## Clean all build artifacts

all: java-build terraform-validate ## Build and validate everything

##@ Prerequisites

check-gradle: ## Check if Gradle is available
	@command -v gradle >/dev/null 2>&1 || { \
		echo "$(COLOR_YELLOW)Gradle not found. Checking for Gradle wrapper...$(COLOR_RESET)"; \
		if [ ! -f "$(JAVA_DIR)/gradlew" ]; then \
			echo "$(COLOR_YELLOW)Gradle wrapper not found. Installing...$(COLOR_RESET)"; \
			cd $(JAVA_DIR) && gradle wrapper --gradle-version 8.5; \
		fi; \
	}

check-terraform: ## Check if Terraform is installed
	@command -v terraform >/dev/null 2>&1 || { \
		echo "$(COLOR_YELLOW)Error: Terraform is not installed.$(COLOR_RESET)"; \
		echo "Please install Terraform: https://www.terraform.io/downloads"; \
		exit 1; \
	}

check-aws: ## Check if AWS CLI is configured
	@command -v aws >/dev/null 2>&1 || { \
		echo "$(COLOR_YELLOW)Error: AWS CLI is not installed.$(COLOR_RESET)"; \
		echo "Please install AWS CLI: https://aws.amazon.com/cli/"; \
		exit 1; \
	}
	@aws sts get-caller-identity >/dev/null 2>&1 || { \
		echo "$(COLOR_YELLOW)Error: AWS credentials not configured.$(COLOR_RESET)"; \
		echo "Please configure AWS credentials using 'aws configure'"; \
		exit 1; \
	}

##@ Utilities

setup: check-gradle ## Initial project setup
	@echo "$(COLOR_BLUE)Setting up project...$(COLOR_RESET)"
	@if [ ! -f "$(JAVA_DIR)/gradlew" ]; then \
		echo "Creating Gradle wrapper..."; \
		cd $(JAVA_DIR) && gradle wrapper --gradle-version 8.5; \
	fi
	@if [ ! -f "$(TERRAFORM_DIR)/terraform.tfvars" ]; then \
		echo "Creating terraform.tfvars from example..."; \
		cp $(TERRAFORM_DIR)/terraform.tfvars.example $(TERRAFORM_DIR)/terraform.tfvars; \
		echo "$(COLOR_YELLOW)Please edit $(TERRAFORM_DIR)/terraform.tfvars with your configuration$(COLOR_RESET)"; \
	fi
	@echo "$(COLOR_GREEN)Setup complete!$(COLOR_RESET)"

info: ## Display project information
	@echo "$(COLOR_BOLD)Project Information:$(COLOR_RESET)"
	@echo "  Java Directory: $(JAVA_DIR)"
	@echo "  Terraform Directory: $(TERRAFORM_DIR)"
	@echo "  AWS Region: $(AWS_REGION)"
	@echo "  Registry Name: $(TF_VAR_REGISTRY_NAME)"
	@echo ""
	@echo "$(COLOR_BOLD)AWS Account:$(COLOR_RESET)"
	@aws sts get-caller-identity 2>/dev/null || echo "  Not configured"
