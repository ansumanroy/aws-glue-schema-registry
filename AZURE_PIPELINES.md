# Azure DevOps Pipeline Configuration

This document describes the Azure DevOps pipeline configuration for building and testing the AWS Glue Schema Registry client implementations.

## Pipeline Files

### 1. `azure-pipelines.yml` (Full Pipeline - Using Makefile)

Complete pipeline using Makefile targets:
- **Build and Test Stage**: Uses `make build` and `make test` to build and test all projects
- **Documentation Stage**: Uses `make docs` to generate documentation for all languages
- **Publish Stage**: Uses `make java-jar`, `make python-build`, `make golang-build` to build artifacts
- **Benefits**: Simpler pipeline, consistent with local development, easier to maintain

### 2. `.azure-pipelines/azure-pipelines-simple.yml` (Simple Pipeline - Using Makefile)

Simplified pipeline using Makefile targets:
- Single stage with `make build` and `make test`
- Suitable for basic CI/CD requirements
- Faster execution time
- Showcases Makefile integration in CI/CD

### 3. `azure-pipelines-explicit.yml` (Full Pipeline - Explicit Steps)

Complete pipeline with explicit build steps (no Makefile):
- **Build and Test Stage**: Explicit Gradle/Maven, Python, and Golang commands
- **Documentation Stage**: Explicit documentation generation commands
- **Publish Stage**: Explicit artifact building commands
- **Benefits**: More control, detailed logging, easier to debug individual steps

### 4. `.azure-pipelines/azure-pipelines-simple-explicit.yml` (Simple Pipeline - Explicit Steps)

Simplified pipeline with explicit build steps:
- Single stage with explicit commands for each language
- More verbose but easier to understand
- Good for learning and debugging

## Prerequisites

### Azure DevOps Variables

Set the following variables in Azure DevOps (Pipeline → Variables):

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `GLUE_REGISTRY_NAME` | Glue Schema Registry name | `my-registry` | Yes (for tests) |
| `AWS_REGION` | AWS region | `us-east-1` | Yes (for tests) |
| `AWS_ACCESS_KEY_ID` | AWS access key | `AKIA...` | Yes (for tests) |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | `***` | Yes (for tests) |

**Note**: Mark `AWS_SECRET_ACCESS_KEY` as a secret variable.

### AWS Credentials

The pipeline requires AWS credentials to run tests against AWS Glue Schema Registry. You can:

1. **Use Azure DevOps Variables** (recommended for CI/CD):
   - Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as pipeline variables
   - Mark secret variables as sensitive

2. **Use Service Connections**:
   - Create an AWS service connection in Azure DevOps
   - Use it to inject AWS credentials

3. **Use IAM Roles** (if running on AWS-hosted agents):
   - Configure IAM roles for the agent
   - Credentials will be automatically picked up

## Pipeline Structure

### Build and Test Stage

#### Java Job
- Installs Java 17
- Caches Gradle and Maven dependencies
- Builds with Gradle
- Tests with Gradle
- Optionally builds and tests with Maven
- Publishes test results and code coverage

#### Python Job
- Installs Python 3.11
- Creates virtual environment
- Installs dependencies
- Runs pytest tests
- Publishes test results and code coverage

#### Golang Job
- Installs Go 1.21
- Downloads dependencies
- Builds the project
- Runs tests
- Publishes test results

### Documentation Stage

- Generates Javadoc for Java
- Generates pydoc for Python
- Generates godoc for Golang
- Publishes documentation artifacts

### Publish Stage (Main Branch Only)

- Builds Java JAR artifacts
- Builds Python wheel/distribution
- Builds Golang binaries
- Publishes all artifacts

## Usage

### Option 1: Use Full Pipeline with Makefile (Recommended)

1. Create a new pipeline in Azure DevOps
2. Select "Existing Azure Pipelines YAML file"
3. Choose `azure-pipelines.yml` from the repository
4. Configure pipeline variables (see Prerequisites)
5. Run the pipeline

**Benefits**: Uses Makefile targets, consistent with local development, simpler pipeline

### Option 2: Use Simple Pipeline with Makefile

1. Create a new pipeline in Azure DevOps
2. Select "Existing Azure Pipelines YAML file"
3. Choose `.azure-pipelines/azure-pipelines-simple.yml` from the repository
4. Configure pipeline variables (see Prerequisites)
5. Run the pipeline

**Benefits**: Quick setup, uses Makefile, minimal configuration

### Option 3: Use Full Pipeline with Explicit Steps

1. Create a new pipeline in Azure DevOps
2. Select "Existing Azure Pipelines YAML file"
3. Choose `azure-pipelines-explicit.yml` from the repository
4. Configure pipeline variables (see Prerequisites)
5. Run the pipeline

**Benefits**: More control, detailed logging, easier to debug individual steps

### Option 4: Use Simple Pipeline with Explicit Steps

1. Create a new pipeline in Azure DevOps
2. Select "Existing Azure Pipelines YAML file"
3. Choose `.azure-pipelines/azure-pipelines-simple-explicit.yml` from the repository
4. Configure pipeline variables (see Prerequisites)
5. Run the pipeline

**Benefits**: Explicit commands, easier to understand, good for learning

### Option 5: Inline YAML

Copy the contents of any pipeline file and paste it directly into the Azure DevOps pipeline editor.

## Configuration

### Customizing Java Version

Edit the `JAVA_VERSION` variable:
```yaml
variables:
  JAVA_VERSION: '17'  # Change to '11', '21', etc.
```

### Customizing Python Version

Edit the `PYTHON_VERSION` variable:
```yaml
variables:
  PYTHON_VERSION: '3.11'  # Change to '3.9', '3.10', etc.
```

### Customizing Go Version

Edit the `GO_VERSION` variable:
```yaml
variables:
  GO_VERSION: '1.21'  # Change to '1.20', '1.22', etc.
```

### Skipping Tests

To skip tests (not recommended), add `-DskipTests` for Maven or modify Gradle tasks:

```yaml
- script: |
    cd java
    ./gradlew build -x test --no-daemon
  displayName: 'Build Java (skip tests)'
```

### Conditional Execution

The pipeline can be configured to run only specific jobs based on conditions:

```yaml
- job: JavaBuild
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  steps:
    # Java build steps
```

## Test Results

Test results are published in JUnit XML format:
- **Java**: `java/build/test-results/**/*.xml`
- **Python**: `python/junit/test-results.xml` (requires pytest-junit plugin)
- **Golang**: `golang/test-results.json` (requires go-junit-report)

## Code Coverage

Code coverage is published when available:
- **Java**: JaCoCo reports from `java/build/reports/jacoco/test/jacocoTestReport.xml`
- **Python**: Cobertura reports from `python/coverage.xml`

## Artifacts

Artifacts are published in the Publish stage:
- **Java**: JAR files from `java/build/libs`
- **Python**: Wheel and source distribution from `python/dist`
- **Golang**: Binary executables from `golang`

## Troubleshooting

### Java Build Fails

1. Check Java version: Ensure Java 17 is installed
2. Check Gradle wrapper: Ensure `gradlew` has execute permissions
3. Check dependencies: Ensure network access for Maven Central

### Python Build Fails

1. Check Python version: Ensure Python 3.11 is available
2. Check virtual environment: Ensure venv is created successfully
3. Check dependencies: Ensure `requirements.txt` exists and is valid

### Golang Build Fails

1. Check Go version: Ensure Go 1.21 is installed
2. Check modules: Ensure `go.mod` is valid
3. Check dependencies: Ensure network access for Go modules

### Tests Fail

1. Check AWS credentials: Ensure `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set
2. Check registry name: Ensure `GLUE_REGISTRY_NAME` matches your registry
3. Check region: Ensure `AWS_REGION` is correct
4. Check permissions: Ensure AWS credentials have Glue Schema Registry permissions

### Cache Issues

If dependency caches cause issues, disable caching:

```yaml
# Comment out or remove Cache@2 tasks
# - task: Cache@2
#   ...
```

## Makefile vs Explicit Steps

### Using Makefile (Recommended)

**Pros**:
- Simpler pipeline YAML
- Consistent with local development commands
- Single source of truth for build logic
- Easier to maintain (changes in Makefile apply everywhere)
- Can test pipeline commands locally

**Cons**:
- Less granular control over individual steps
- Harder to see exact commands in pipeline UI
- Requires Makefile to be cross-platform compatible

**When to use**: Most projects, especially when you want consistency between local and CI/CD

### Using Explicit Steps

**Pros**:
- More control over each step
- Detailed logging for each command
- Easier to debug individual steps
- Can customize each step independently
- Better visibility in pipeline UI

**Cons**:
- More verbose pipeline YAML
- Duplication of build logic (Makefile + pipeline)
- Changes need to be made in multiple places
- Harder to test locally

**When to use**: When you need fine-grained control, debugging, or showcasing explicit commands

## Best Practices

1. **Use Pipeline Variables**: Store sensitive information (AWS credentials) as secret variables
2. **Use Makefile for Consistency**: Prefer Makefile-based pipelines for consistency with local development
3. **Enable Caching**: Use cache tasks to speed up builds (explicit pipelines only)
4. **Publish Test Results**: Always publish test results for visibility
5. **Conditional Publishing**: Only publish artifacts on main branch
6. **Fail Fast**: Configure pipeline to fail fast on critical errors
7. **Parallel Execution**: Run Java, Python, and Golang jobs in parallel for faster execution (explicit pipelines)
8. **Test Locally**: Test Makefile targets locally before committing pipeline changes

## Example: Setting Up Pipeline Variables

1. Go to Azure DevOps → Pipelines → Your Pipeline → Edit
2. Click "Variables" in the top menu
3. Add variables:
   - `GLUE_REGISTRY_NAME`: `my-registry` (New variable)
   - `AWS_REGION`: `us-east-1` (New variable)
   - `AWS_ACCESS_KEY_ID`: `AKIA...` (New variable)
   - `AWS_SECRET_ACCESS_KEY`: `***` (New variable, mark as secret)
4. Save and run the pipeline

## Support

For issues or questions about the pipeline:
1. Check the Azure DevOps pipeline logs
2. Review the troubleshooting section above
3. Check Azure DevOps documentation
4. Contact the development team

