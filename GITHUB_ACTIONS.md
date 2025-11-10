# GitHub Actions Workflow Configuration

This document describes the GitHub Actions workflow configuration for building and testing the AWS Glue Schema Registry client implementations.

## Workflow Files

### 1. `.github/workflows/build.yml` (Full Workflow - Using Makefile)

Complete workflow using Makefile targets:
- **Build and Test Job**: Uses `make build` and `make test` to build and test all projects
- **Documentation Job**: Uses `make docs` to generate documentation for all languages
- **Publish Job**: Uses `make java-jar`, `make python-build`, `make golang-build` to build artifacts
- **Benefits**: Simpler workflow, consistent with local development, easier to maintain

### 2. `.github/workflows/build-simple.yml` (Simple Workflow - Using Makefile)

Simplified workflow using Makefile targets:
- Single job with `make build` and `make test`
- Suitable for basic CI/CD requirements
- Faster execution time
- Showcases Makefile integration in CI/CD

### 3. `.github/workflows/build-explicit.yml` (Full Workflow - Explicit Steps)

Complete workflow with explicit build steps (no Makefile):
- **Java Job**: Explicit Gradle commands
- **Python Job**: Explicit Python virtual environment and pytest commands
- **Golang Job**: Explicit Go build and test commands
- **Benefits**: More control, detailed logging, easier to debug individual steps

## Prerequisites

### GitHub Secrets

Set the following secrets in GitHub (Settings → Secrets and variables → Actions):

| Secret | Description | Example | Required |
|--------|-------------|---------|----------|
| `GLUE_REGISTRY_NAME` | Glue Schema Registry name | `my-registry` | Yes (for tests) |
| `AWS_REGION` | AWS region | `us-east-1` | Yes (for tests) |
| `AWS_ACCESS_KEY_ID` | AWS access key | `AKIA...` | Yes (for tests) |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | `***` | Yes (for tests) |

**Note**: All secrets are automatically masked in logs.

### AWS Credentials

The workflows require AWS credentials to run tests against AWS Glue Schema Registry. You can:

1. **Use GitHub Secrets** (recommended for CI/CD):
   - Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as repository secrets
   - Secrets are automatically masked in logs

2. **Use IAM Roles** (if using self-hosted runners on AWS):
   - Configure IAM roles for the runner
   - Credentials will be automatically picked up

## Usage

### Option 1: Use Full Workflow with Makefile (Recommended)

1. The workflow is automatically triggered on push to `main` or `develop` branches
2. Configure GitHub Secrets (see Prerequisites)
3. The workflow will run automatically on every push and pull request

**Benefits**: Uses Makefile targets, consistent with local development, simpler workflow

### Option 2: Use Simple Workflow with Makefile

1. The workflow is automatically triggered on push to `main` or `develop` branches
2. Configure GitHub Secrets (see Prerequisites)
3. The workflow will run automatically

**Benefits**: Quick setup, uses Makefile, minimal configuration

### Option 3: Use Full Workflow with Explicit Steps

1. The workflow is automatically triggered on push to `main` or `develop` branches
2. Configure GitHub Secrets (see Prerequisites)
3. The workflow will run automatically

**Benefits**: More control, detailed logging, easier to debug individual steps

## Workflow Structure

### Makefile-Based Workflows

#### Build and Test Job
- Installs Java 17, Python 3.11, and Go 1.21
- Runs `make build` to build all projects
- Runs `make test` to test all projects
- Publishes test results

#### Documentation Job
- Runs `make docs` to generate all documentation
- Uploads documentation artifacts

#### Publish Job (main branch only)
- Runs `make java-jar` to build Java JAR
- Runs `make python-build` to build Python package
- Runs `make golang-build` to build Golang binary
- Uploads all artifacts

### Explicit Steps Workflow

#### Java Job
- Installs Java 17 with Gradle caching
- Builds with Gradle
- Tests with Gradle
- Publishes test results and artifacts

#### Python Job
- Installs Python 3.11
- Creates virtual environment
- Installs dependencies
- Runs pytest tests
- Builds Python package
- Publishes test results and artifacts

#### Golang Job
- Installs Go 1.21
- Downloads dependencies
- Builds the project
- Runs tests
- Publishes artifacts

## Configuration

### Customizing Java Version

Edit the workflow file and change:
```yaml
env:
  JAVA_VERSION: '17'  # Change to desired version
```

### Customizing Python Version

Edit the workflow file and change:
```yaml
env:
  PYTHON_VERSION: '3.11'  # Change to desired version
```

### Customizing Go Version

Edit the workflow file and change:
```yaml
env:
  GO_VERSION: '1.21'  # Change to desired version
```

### Disabling Caching

To disable caching (e.g., for debugging), comment out or remove the `cache` parameters in the setup actions.

## Makefile vs Explicit Steps

### Using Makefile (Recommended)

**Pros**:
- Simpler workflow YAML
- Consistent with local development commands
- Single source of truth for build logic
- Easier to maintain (changes in Makefile apply everywhere)
- Can test workflow commands locally

**Cons**:
- Less granular control over individual steps
- Harder to see exact commands in workflow UI
- Requires Makefile to be cross-platform compatible

**When to use**: Most projects, especially when you want consistency between local and CI/CD

### Using Explicit Steps

**Pros**:
- More control over each step
- Detailed logging for each command
- Easier to debug individual steps
- Can customize each step independently
- Better visibility in workflow UI

**Cons**:
- More verbose workflow YAML
- Duplication of build logic (Makefile + workflow)
- Changes need to be made in multiple places
- Harder to test locally

**When to use**: When you need fine-grained control, debugging, or showcasing explicit commands

## Best Practices

1. **Use GitHub Secrets**: Store sensitive information (AWS credentials) as repository secrets
2. **Use Makefile for Consistency**: Prefer Makefile-based workflows for consistency with local development
3. **Enable Caching**: Use caching in setup actions to speed up builds
4. **Publish Test Results**: Always publish test results for visibility
5. **Conditional Publishing**: Only publish artifacts on main branch
6. **Fail Fast**: Configure workflow to fail fast on critical errors
7. **Parallel Execution**: Run Java, Python, and Golang jobs in parallel for faster execution (explicit workflows)
8. **Test Locally**: Test Makefile targets locally before committing workflow changes

## Example: Setting Up GitHub Secrets

1. Go to your GitHub repository
2. Click "Settings" → "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Add each secret:
   - Name: `GLUE_REGISTRY_NAME`, Value: `your-registry-name`
   - Name: `AWS_REGION`, Value: `us-east-1`
   - Name: `AWS_ACCESS_KEY_ID`, Value: `your-access-key`
   - Name: `AWS_SECRET_ACCESS_KEY`, Value: `your-secret-key` (click "Add secret")

## Troubleshooting

### Workflow fails with "JAVA_HOME not set"

The Makefile checks for `JAVA_HOME` and falls back to system Java. Ensure the Java setup action runs before the build step.

### Tests fail with "AWS credentials not found"

Ensure all required GitHub Secrets are configured:
- `GLUE_REGISTRY_NAME`
- `AWS_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### Python tests fail with "ModuleNotFoundError"

The workflow creates a virtual environment and installs dependencies. Ensure the `python-install-dev` Makefile target installs all required dependencies.

### Golang build fails with "missing go.sum entry"

The workflow runs `go mod download` before building. If issues persist, ensure `go.mod` and `go.sum` are committed to the repository.

## Workflow Triggers

Workflows are triggered on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Push to `feature/**` branches (full workflow only)
- Manual trigger (via GitHub Actions UI)

Workflows ignore changes to:
- Markdown files (`*.md`)
- `.gitignore`
- `README.md`

## Artifact Retention

- **Test Results**: Published as workflow checks (no retention limit)
- **Documentation**: Retained for 7 days
- **Build Artifacts**: Retained for 30 days (main branch only)

## Comparison with Azure DevOps

| Feature | GitHub Actions | Azure DevOps |
|---------|----------------|--------------|
| Setup | GitHub Secrets | Pipeline Variables |
| Caching | Built-in (Java, Python, Go) | Cache@2 tasks |
| Test Results | publish-unit-test-result-action | PublishTestResults@2 |
| Artifacts | upload-artifact@v4 | PublishBuildArtifacts@1 |
| Parallel Jobs | Free tier: 20 concurrent | Depends on license |
| Cost | Free for public repos | Requires Azure subscription |

