.PHONY: help build test clean java-build java-test java-clean java-jar java-jar-fat java-jar-fat-gradle java-jar-fat-maven java-build-maven java-test-maven java-clean-maven java-jar-maven java-javadoc java-javadoc-gradle java-javadoc-maven java-publish-exchange python-venv python-build python-test python-clean python-install python-install-dev python-install-package python-docs golang-build golang-test golang-clean golang-install golang-docs check-gradle check-maven check-java check-python check-go setup info docs

# Default target
.DEFAULT_GOAL := help

# Variables
JAVA_DIR := java
PYTHON_DIR := python
GOLANG_DIR := golang
AWS_REGION ?= us-east-1

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

docs: java-javadoc python-docs golang-docs ## Generate all documentation (Javadoc, pydoc, and godoc)
	@echo "$(COLOR_GREEN)All documentation generated$(COLOR_RESET)"

##@ Java Build

java-build-gradle: check-gradle check-java ## Build Java project using Gradle
	@echo "$(COLOR_BLUE)Building Java project with Gradle...$(COLOR_RESET)"
	@if [ -z "$$JAVA_HOME" ]; then \
		JAVA_HOME=$$(/usr/libexec/java_home -v 17 2>/dev/null || echo ""); \
	fi; \
	if [ -z "$$JAVA_HOME" ]; then \
		echo "$(COLOR_YELLOW)Warning: JAVA_HOME not set. Using system Java.$(COLOR_RESET)"; \
	fi; \
	cd $(JAVA_DIR) && JAVA_HOME=$$JAVA_HOME ./gradlew build --no-daemon

java-test-gradle: check-gradle check-java ## Run Java tests using Gradle
	@echo "$(COLOR_BLUE)Running Java tests with Gradle...$(COLOR_RESET)"
	@if [ -z "$$JAVA_HOME" ]; then \
		JAVA_HOME=$$(/usr/libexec/java_home -v 17 2>/dev/null || echo ""); \
	fi; \
	if [ -z "$$JAVA_HOME" ]; then \
		echo "$(COLOR_YELLOW)Warning: JAVA_HOME not set. Using system Java.$(COLOR_RESET)"; \
	fi; \
	cd $(JAVA_DIR) && JAVA_HOME=$$JAVA_HOME ./gradlew test --no-daemon --rerun-tasks

java-clean-gradle: check-gradle ## Clean Java build artifacts using Gradle
	@echo "$(COLOR_BLUE)Cleaning Java build with Gradle...$(COLOR_RESET)"
	@if [ -z "$$JAVA_HOME" ]; then \
		JAVA_HOME=$$(/usr/libexec/java_home -v 17 2>/dev/null || echo ""); \
	fi; \
	cd $(JAVA_DIR) && JAVA_HOME=$$JAVA_HOME ./gradlew clean --no-daemon

java-jar-gradle: java-build-gradle ## Build Java JAR file using Gradle
	@echo "$(COLOR_BLUE)Building JAR with Gradle...$(COLOR_RESET)"
	@if [ -z "$$JAVA_HOME" ]; then \
		JAVA_HOME=$$(/usr/libexec/java_home -v 17 2>/dev/null || echo ""); \
	fi; \
	cd $(JAVA_DIR) && JAVA_HOME=$$JAVA_HOME ./gradlew jar --no-daemon
	@echo "$(COLOR_GREEN)JAR created: $(JAVA_DIR)/build/libs/schema-registry-client-1.0.0-SNAPSHOT.jar$(COLOR_RESET)"

java-jar-fat-gradle: java-build-gradle ## Build Java fat JAR (with all dependencies) using Gradle
	@echo "$(COLOR_BLUE)Building fat JAR with Gradle...$(COLOR_RESET)"
	@if [ -z "$$JAVA_HOME" ]; then \
		JAVA_HOME=$$(/usr/libexec/java_home -v 17 2>/dev/null || echo ""); \
	fi; \
	cd $(JAVA_DIR) && JAVA_HOME=$$JAVA_HOME ./gradlew shadowJar --no-daemon
	@echo "$(COLOR_GREEN)Fat JAR created: $(JAVA_DIR)/build/libs/schema-registry-client-1.0.0-SNAPSHOT-all.jar$(COLOR_RESET)"

java-build-maven: check-maven check-java ## Build Java project using Maven
	@echo "$(COLOR_BLUE)Building Java project with Maven...$(COLOR_RESET)"
	@if [ -z "$$JAVA_HOME" ]; then \
		JAVA_HOME=$$(/usr/libexec/java_home -v 17 2>/dev/null || echo ""); \
	fi; \
	cd $(JAVA_DIR) && JAVA_HOME=$$JAVA_HOME mvn clean compile

java-test-maven: check-maven check-java ## Run Java tests using Maven
	@echo "$(COLOR_BLUE)Running Java tests with Maven...$(COLOR_RESET)"
	@if [ -z "$$JAVA_HOME" ]; then \
		JAVA_HOME=$$(/usr/libexec/java_home -v 17 2>/dev/null || echo ""); \
	fi; \
	cd $(JAVA_DIR) && JAVA_HOME=$$JAVA_HOME mvn test

java-clean-maven: check-maven ## Clean Java build artifacts using Maven
	@echo "$(COLOR_BLUE)Cleaning Java build with Maven...$(COLOR_RESET)"
	@if [ -z "$$JAVA_HOME" ]; then \
		JAVA_HOME=$$(/usr/libexec/java_home -v 17 2>/dev/null || echo ""); \
	fi; \
	cd $(JAVA_DIR) && JAVA_HOME=$$JAVA_HOME mvn clean

java-jar-maven: java-build-maven ## Build Java JAR file using Maven
	@echo "$(COLOR_BLUE)Building JAR with Maven...$(COLOR_RESET)"
	@if [ -z "$$JAVA_HOME" ]; then \
		JAVA_HOME=$$(/usr/libexec/java_home -v 17 2>/dev/null || echo ""); \
	fi; \
	cd $(JAVA_DIR) && JAVA_HOME=$$JAVA_HOME mvn package -DskipTests
	@echo "$(COLOR_GREEN)JAR created: $(JAVA_DIR)/target/schema-registry-client-1.0.0-SNAPSHOT.jar$(COLOR_RESET)"

java-jar-fat-maven: java-build-maven ## Build Java fat JAR (with all dependencies) using Maven
	@echo "$(COLOR_BLUE)Building fat JAR with Maven...$(COLOR_RESET)"
	@if [ -z "$$JAVA_HOME" ]; then \
		JAVA_HOME=$$(/usr/libexec/java_home -v 17 2>/dev/null || echo ""); \
	fi; \
	cd $(JAVA_DIR) && JAVA_HOME=$$JAVA_HOME mvn package -DskipTests
	@echo "$(COLOR_GREEN)Fat JAR created: $(JAVA_DIR)/target/schema-registry-client-1.0.0-SNAPSHOT-all.jar$(COLOR_RESET)"

java-build: java-build-gradle ## Build Java project (default: Gradle)
java-test: java-test-gradle ## Run Java tests (default: Gradle)
java-clean: java-clean-gradle ## Clean Java build artifacts (default: Gradle)
java-jar: java-jar-gradle ## Build Java JAR file (default: Gradle)
java-jar-fat: java-jar-fat-gradle ## Build Java fat JAR with all dependencies (default: Gradle)

java-javadoc-gradle: check-gradle check-java ## Generate Java Javadoc using Gradle
	@echo "$(COLOR_BLUE)Generating Javadoc with Gradle...$(COLOR_RESET)"
	@if [ -z "$$JAVA_HOME" ]; then \
		JAVA_HOME=$$(/usr/libexec/java_home -v 17 2>/dev/null || echo ""); \
	fi; \
	cd $(JAVA_DIR) && JAVA_HOME=$$JAVA_HOME ./gradlew javadoc --no-daemon
	@echo "$(COLOR_GREEN)Javadoc generated: $(JAVA_DIR)/build/docs/javadoc/index.html$(COLOR_RESET)"

java-javadoc-maven: check-maven check-java ## Generate Java Javadoc using Maven
	@echo "$(COLOR_BLUE)Generating Javadoc with Maven...$(COLOR_RESET)"
	@if [ -z "$$JAVA_HOME" ]; then \
		JAVA_HOME=$$(/usr/libexec/java_home -v 17 2>/dev/null || echo ""); \
	fi; \
	cd $(JAVA_DIR) && JAVA_HOME=$$JAVA_HOME mvn javadoc:javadoc
	@echo "$(COLOR_GREEN)Javadoc generated: $(JAVA_DIR)/target/docs/javadoc/index.html$(COLOR_RESET)"

java-javadoc: java-javadoc-gradle ## Generate Java Javadoc (default: Gradle)

java-publish-exchange: check-java ## Publish Java library to MuleSoft Exchange (requires VERSION variable)
	@if [ -z "$(VERSION)" ]; then \
		echo "$(COLOR_RED)Error: VERSION is required. Usage: make java-publish-exchange VERSION=1.0.0$(COLOR_RESET)"; \
		exit 1; \
	fi
	@echo "$(COLOR_BLUE)Publishing to MuleSoft Exchange...$(COLOR_RESET)"
	@if [ -z "$$ANYPOINT_USERNAME" ] || [ -z "$$ANYPOINT_PASSWORD" ]; then \
		echo "$(COLOR_YELLOW)Warning: ANYPOINT_USERNAME and ANYPOINT_PASSWORD environment variables are required$(COLOR_RESET)"; \
		echo "$(COLOR_YELLOW)Set them before running: export ANYPOINT_USERNAME=your-username && export ANYPOINT_PASSWORD=your-password$(COLOR_RESET)"; \
	fi
	@$(SCRIPT_DIR)/publish-mulesoft-exchange.sh --version $(VERSION) --build-system maven

##@ Python Build

python-venv: check-python ## Create Python virtual environment
	@echo "$(COLOR_BLUE)Creating Python virtual environment...$(COLOR_RESET)"
	@if [ ! -d "$(PYTHON_DIR)/venv" ]; then \
		cd $(PYTHON_DIR) && python3 -m venv venv || python -m venv venv; \
		echo "$(COLOR_GREEN)Virtual environment created at $(PYTHON_DIR)/venv$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)Virtual environment already exists$(COLOR_RESET)"; \
	fi

python-install: python-venv ## Install Python dependencies in virtual environment
	@echo "$(COLOR_BLUE)Installing Python dependencies in virtual environment...$(COLOR_RESET)"
	@cd $(PYTHON_DIR) && \
		. venv/bin/activate && \
		pip install --upgrade pip && \
		pip install -r requirements.txt

python-install-dev: python-venv ## Install Python development dependencies in virtual environment
	@echo "$(COLOR_BLUE)Installing Python development dependencies in virtual environment...$(COLOR_RESET)"
	@cd $(PYTHON_DIR) && \
		. venv/bin/activate && \
		pip install --upgrade pip && \
		pip install -r requirements-dev.txt

python-test: python-install-dev ## Run Python tests in virtual environment
	@echo "$(COLOR_BLUE)Running Python tests in virtual environment...$(COLOR_RESET)"
	@cd $(PYTHON_DIR) && \
		. venv/bin/activate && \
		pytest tests/ -v

python-build: python-venv ## Build Python package (wheel and source distribution)
	@echo "$(COLOR_BLUE)Building Python package...$(COLOR_RESET)"
	@cd $(PYTHON_DIR) && \
		. venv/bin/activate && \
		pip install --upgrade pip build && \
		python -m build
	@echo "$(COLOR_GREEN)Package built: $(PYTHON_DIR)/dist/$(COLOR_RESET)"

python-install-package: python-build ## Install the built package in virtual environment
	@echo "$(COLOR_BLUE)Installing built package in virtual environment...$(COLOR_RESET)"
	@cd $(PYTHON_DIR) && \
		. venv/bin/activate && \
		pip install --upgrade dist/*.whl || pip install --upgrade dist/*.tar.gz

python-docs: python-install-dev ## Generate Python documentation using pydoc
	@echo "$(COLOR_BLUE)Generating Python documentation...$(COLOR_RESET)"
	@mkdir -p $(PYTHON_DIR)/docs/html
	@cd $(PYTHON_DIR) && \
		. venv/bin/activate && \
		python -m pydoc -w glue_schema_registry.client glue_schema_registry.avro_serializer glue_schema_registry.json_serializer glue_schema_registry.model 2>/dev/null || true
	@cd $(PYTHON_DIR) && \
	if ls *.html 1> /dev/null 2>&1; then \
		mv *.html docs/html/ 2>/dev/null || true; \
	fi
	@echo "$(COLOR_GREEN)Python documentation generated in $(PYTHON_DIR)/docs/html/$(COLOR_RESET)"
	@echo "$(COLOR_BLUE)Note: For better documentation, consider using Sphinx. Install with: pip install sphinx$(COLOR_RESET)"

python-clean: ## Clean Python build artifacts and virtual environment
	@echo "$(COLOR_BLUE)Cleaning Python build artifacts...$(COLOR_RESET)"
	@cd $(PYTHON_DIR) && rm -rf build/ dist/ *.egg-info/ .pytest_cache/ __pycache__/ .coverage htmlcov/ venv/
	@find $(PYTHON_DIR) -type d -name __pycache__ -exec rm -r {} + 2>/dev/null || true
	@find $(PYTHON_DIR) -type f -name "*.pyc" -delete 2>/dev/null || true

##@ Golang Build

golang-install: check-go ## Install Golang dependencies
	@echo "$(COLOR_BLUE)Installing Golang dependencies...$(COLOR_RESET)"
	cd $(GOLANG_DIR) && go mod tidy && go mod download

golang-build: check-go golang-install ## Build Golang project
	@echo "$(COLOR_BLUE)Building Golang project...$(COLOR_RESET)"
	cd $(GOLANG_DIR) && go build ./...

golang-test: check-go golang-install ## Run Golang tests
	@echo "$(COLOR_BLUE)Running Golang tests...$(COLOR_RESET)"
	cd $(GOLANG_DIR) && go test ./... -v

golang-docs: check-go ## Generate Golang documentation using godoc
	@echo "$(COLOR_BLUE)Generating Golang documentation...$(COLOR_RESET)"
	@mkdir -p $(GOLANG_DIR)/docs/html
	@cd $(GOLANG_DIR) && \
	if command -v godoc >/dev/null 2>&1; then \
		echo "Using godoc to generate documentation..."; \
		godoc -http=:6060 -index -notes="BUG|TODO" > /dev/null 2>&1 & \
		GODOC_PID=$$!; \
		sleep 3; \
		mkdir -p docs/html && \
		curl -s http://localhost:6060/pkg/github.com/aws-glue-schema-registry/golang/ > docs/html/index.html 2>/dev/null || true; \
		kill $$GODOC_PID 2>/dev/null || true; \
		sleep 1; \
	else \
		echo "Using go doc to generate documentation..."; \
		mkdir -p docs/html && \
		{ \
			echo "<!DOCTYPE html>"; \
			echo "<html><head>"; \
			echo "<title>Go Documentation - AWS Glue Schema Registry</title>"; \
			echo "<style>body{font-family:monospace;padding:20px;background:#f5f5f5;}pre{background:#fff;padding:15px;border:1px solid #ddd;border-radius:4px;}</style>"; \
			echo "</head><body><h1>Go Documentation</h1><pre>"; \
			echo "=== Client Package ==="; \
			go doc -all ./client 2>&1 || echo "No documentation for client package"; \
			echo ""; \
			echo "=== Model Package ==="; \
			go doc -all ./model 2>&1 || echo "No documentation for model package"; \
			echo ""; \
			echo "=== Serializer Package ==="; \
			go doc -all ./serializer 2>&1 || echo "No documentation for serializer package"; \
			echo "</pre></body></html>"; \
		} > docs/html/index.html; \
	fi
	@if [ -f $(GOLANG_DIR)/docs/html/index.html ]; then \
		echo "$(COLOR_GREEN)Golang documentation generated in $(GOLANG_DIR)/docs/html/index.html$(COLOR_RESET)"; \
		echo "$(COLOR_BLUE)View documentation: open $(GOLANG_DIR)/docs/html/index.html$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)Warning: Documentation generation may have failed$(COLOR_RESET)"; \
	fi
	@echo "$(COLOR_BLUE)Note: For better documentation, install godoc: go install golang.org/x/tools/cmd/godoc@latest$(COLOR_RESET)"

golang-clean: ## Clean Golang build artifacts
	@echo "$(COLOR_BLUE)Cleaning Golang build artifacts...$(COLOR_RESET)"
	cd $(GOLANG_DIR) && go clean ./...

##@ Combined Operations

build: java-build python-build golang-build ## Build all projects

test: java-test python-test golang-test ## Run all tests

clean: java-clean python-clean golang-clean ## Clean all build artifacts

##@ Prerequisites

check-gradle: ## Check if Gradle wrapper is available
	@if [ ! -f "$(JAVA_DIR)/gradlew" ]; then \
		echo "$(COLOR_YELLOW)Gradle wrapper not found. Checking for Gradle installation...$(COLOR_RESET)"; \
		command -v gradle >/dev/null 2>&1 || { \
			echo "$(COLOR_YELLOW)Error: Gradle is not installed and wrapper not found.$(COLOR_RESET)"; \
			echo "Please install Gradle or ensure gradlew exists in $(JAVA_DIR)/"; \
			exit 1; \
		}; \
		if command -v gradle >/dev/null 2>&1; then \
			echo "Creating Gradle wrapper..."; \
			cd $(JAVA_DIR) && gradle wrapper --gradle-version 8.5; \
		fi; \
	fi

check-java: ## Check if Java 17+ is installed
	@command -v java >/dev/null 2>&1 || { \
		echo "$(COLOR_YELLOW)Error: Java is not installed.$(COLOR_RESET)"; \
		echo "Please install Java 17 or higher: https://adoptium.net/"; \
		exit 1; \
	}
	@JAVA_VERSION=$$(java -version 2>&1 | head -1 | sed -n 's/.*version "\([0-9]*\)\..*/\1/p'); \
	if [ -z "$$JAVA_VERSION" ] || [ $$JAVA_VERSION -lt 17 ]; then \
		echo "$(COLOR_YELLOW)Warning: Java 17 or higher is required.$(COLOR_RESET)"; \
		echo "Current Java version:"; \
		java -version 2>&1 | head -1; \
	fi

check-maven: ## Check if Maven is installed
	@command -v mvn >/dev/null 2>&1 || { \
		echo "$(COLOR_YELLOW)Error: Maven is not installed.$(COLOR_RESET)"; \
		echo "Please install Maven: https://maven.apache.org/install.html"; \
		echo "Or use: brew install maven"; \
		exit 1; \
	}
	@mvn --version | head -1 || { \
		echo "$(COLOR_YELLOW)Warning: Maven may not be properly configured.$(COLOR_RESET)"; \
		exit 1; \
	}

check-python: ## Check if Python is installed
	@command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1 || { \
		echo "$(COLOR_YELLOW)Error: Python is not installed.$(COLOR_RESET)"; \
		echo "Please install Python 3.8 or higher: https://www.python.org/downloads/"; \
		exit 1; \
	}
	@command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1 || { \
		echo "$(COLOR_YELLOW)Error: pip is not installed.$(COLOR_RESET)"; \
		echo "Please install pip: https://pip.pypa.io/en/stable/installation/"; \
		exit 1; \
	}

check-go: ## Check if Go is installed
	@command -v go >/dev/null 2>&1 || { \
		echo "$(COLOR_YELLOW)Error: Go is not installed.$(COLOR_RESET)"; \
		echo "Please install Go: https://golang.org/dl/"; \
		exit 1; \
	}

##@ Utilities

setup: ## Initial project setup
	@echo "$(COLOR_BLUE)Setting up project...$(COLOR_RESET)"
	@if [ ! -f "$(JAVA_DIR)/gradlew" ] && command -v gradle >/dev/null 2>&1; then \
		echo "Creating Gradle wrapper..."; \
		cd $(JAVA_DIR) && gradle wrapper --gradle-version 8.5; \
	fi
	@echo "$(COLOR_GREEN)Setup complete!$(COLOR_RESET)"

info: ## Display project information
	@echo "$(COLOR_BOLD)Project Information:$(COLOR_RESET)"
	@echo "  Java Directory: $(JAVA_DIR)"
	@echo "  Python Directory: $(PYTHON_DIR)"
	@echo "  Golang Directory: $(GOLANG_DIR)"
	@echo "  AWS Region: $(AWS_REGION)"
	@echo ""
	@echo "$(COLOR_BOLD)Language Versions:$(COLOR_RESET)"
	@java -version 2>&1 | head -1 | sed 's/^/  Java: /' || echo "  Java: Not installed"
	@python3 --version 2>&1 | sed 's/^/  Python: /' || python --version 2>&1 | sed 's/^/  Python: /' || echo "  Python: Not installed"
	@go version 2>&1 | sed 's/^/  Go: /' || echo "  Go: Not installed"
	@echo ""
	@echo "$(COLOR_BOLD)Build Tools:$(COLOR_RESET)"
	@./$(JAVA_DIR)/gradlew --version 2>&1 | grep "Gradle" | head -1 | sed 's/^/  Gradle: /' || echo "  Gradle: Not available"
	@mvn --version 2>&1 | head -1 | sed 's/^/  Maven: /' || echo "  Maven: Not installed"
	@echo ""
	@echo "$(COLOR_BOLD)Java Version Requirement:$(COLOR_RESET)"
	@echo "  Required: Java 17 or higher"
	@JAVA_VERSION=$$(java -version 2>&1 | head -1 | sed -n 's/.*version "\([0-9]*\)\..*/\1/p'); \
	if [ -n "$$JAVA_VERSION" ] && [ $$JAVA_VERSION -ge 17 ]; then \
		echo "  Status: $(COLOR_GREEN)✓ Java $$JAVA_VERSION detected (compatible)$(COLOR_RESET)"; \
	else \
		echo "  Status: $(COLOR_YELLOW)⚠ Java 17+ required$(COLOR_RESET)"; \
	fi
	@echo ""
	@echo "$(COLOR_BOLD)Build System Options:$(COLOR_RESET)"
	@echo "  Gradle: make java-build-gradle, make java-test-gradle, make java-jar-gradle, make java-jar-fat-gradle"
	@echo "  Maven:  make java-build-maven, make java-test-maven, make java-jar-maven, make java-jar-fat-maven"
	@echo "  Default: make java-build (uses Gradle)"
