# Publishing to MuleSoft Exchange

This guide explains how to publish the AWS Glue Schema Registry Java Client to MuleSoft Exchange.

## Prerequisites

1. **MuleSoft Anypoint Platform Account**
   - Active Anypoint Platform account
   - Organization ID (found in Anypoint Platform settings)
   - Environment ID (optional, for environment-specific publishing)

2. **Anypoint CLI** (recommended)
   - Install from: https://docs.mulesoft.com/anypoint-platform-cli/
   - Alternative: Use Maven Anypoint Exchange Plugin

3. **Build Tools**
   - Java 17 or higher
   - Maven 3.6+ (for Maven-based publishing)
   - Or Gradle (for Gradle-based publishing)

## Setup

### 1. Install Anypoint CLI

```bash
# macOS
brew install mulesoft/tap/anypoint-cli

# Or download from
# https://docs.mulesoft.com/anypoint-platform-cli/
```

### 2. Configure Environment Variables

Set your Anypoint Platform credentials:

```bash
export ANYPOINT_USERNAME=your-username
export ANYPOINT_PASSWORD=your-password
export ANYPOINT_ORG_ID=your-org-id          # Optional
export ANYPOINT_ENV_ID=your-env-id          # Optional
```

**Security Note**: Never commit credentials to version control. Use environment variables or secure credential storage.

## Publishing Methods

### Method 1: Using Makefile (Linux/macOS - Recommended)

The easiest way to publish on Linux/macOS is using the Makefile target:

```bash
# Publish version 1.0.0
make java-publish-exchange VERSION=1.0.0

# With environment variables set
export ANYPOINT_USERNAME=your-username
export ANYPOINT_PASSWORD=your-password
make java-publish-exchange VERSION=1.0.0
```

### Method 2: Using Bash Script (Linux/macOS)

```bash
# Basic usage
./scripts/publish-mulesoft-exchange.sh --version 1.0.0

# Using Gradle instead of Maven
./scripts/publish-mulesoft-exchange.sh --version 1.0.0 --build-system gradle

# Skip tests (faster, but not recommended)
./scripts/publish-mulesoft-exchange.sh --version 1.0.0 --skip-tests

# Dry run (test without actually publishing)
./scripts/publish-mulesoft-exchange.sh --version 1.0.0 --dry-run
```

### Method 3: Using PowerShell Script (Windows - Recommended)

For Windows users who don't have Make installed, use the PowerShell script:

```powershell
# Basic usage
.\scripts\publish-mulesoft-exchange.ps1 -Version 1.0.0

# Set environment variables
$env:ANYPOINT_USERNAME = "your-username"
$env:ANYPOINT_PASSWORD = "your-password"
$env:ANYPOINT_ORG_ID = "your-org-id"

# Publish version 1.0.0
.\scripts\publish-mulesoft-exchange.ps1 -Version 1.0.0

# Using Gradle instead of Maven
.\scripts\publish-mulesoft-exchange.ps1 -Version 1.0.0 -BuildSystem gradle

# Skip tests (faster, but not recommended)
.\scripts\publish-mulesoft-exchange.ps1 -Version 1.0.0 -SkipTests

# Dry run (test without actually publishing)
.\scripts\publish-mulesoft-exchange.ps1 -Version 1.0.0 -DryRun
```

**Note**: If you get an execution policy error, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Method 3: Using Anypoint CLI Directly

```bash
# Login to Anypoint Platform
anypoint-cli login --username your-username --password your-password

# Build the project first
cd java
mvn clean package

# Publish to Exchange
anypoint-cli exchange publish target/schema-registry-client-1.0.0.jar \
    --org-id your-org-id \
    --env-id your-env-id
```

### Method 4: Using Maven Anypoint Exchange Plugin

Add the plugin to `pom.xml`:

```xml
<plugin>
    <groupId>org.mule.tools.maven</groupId>
    <artifactId>anypoint-exchange-maven-plugin</artifactId>
    <version>1.3.0</version>
    <configuration>
        <username>${anypoint.username}</username>
        <password>${anypoint.password}</password>
        <orgId>${anypoint.orgId}</orgId>
        <envId>${anypoint.envId}</envId>
    </configuration>
</plugin>
```

Then publish:

```bash
mvn anypoint-exchange:deploy \
    -Danypoint.username=your-username \
    -Danypoint.password=your-password \
    -Danypoint.orgId=your-org-id
```

## Script Options

### Bash Script (Linux/macOS)

The `publish-mulesoft-exchange.sh` script supports the following options:

| Option | Description | Default |
|--------|-------------|---------|
| `-b, --build-system` | Build system to use (maven\|gradle) | maven |
| `-v, --version` | Version to publish (required) | - |
| `-s, --skip-build` | Skip building the project | false |
| `-t, --skip-tests` | Skip running tests before building | false |
| `-d, --dry-run` | Perform a dry run without publishing | false |
| `-h, --help` | Show help message | - |

### PowerShell Script (Windows)

The `publish-mulesoft-exchange.ps1` script supports the following options:

| Option | Description | Default |
|--------|-------------|---------|
| `-BuildSystem` | Build system to use (maven\|gradle) | maven |
| `-Version` | Version to publish (required) | - |
| `-SkipBuild` | Skip building the project | false |
| `-SkipTests` | Skip running tests before building | false |
| `-DryRun` | Perform a dry run without publishing | false |
| `-Help` | Show help message | - |

## Version Management

The script automatically updates the version in:
- `pom.xml` (for Maven builds)
- `build.gradle` (for Gradle builds)

**Important**: After publishing, commit the version changes to your repository.

## Exchange Metadata

The script creates an `exchange.json` file in the `java/` directory if it doesn't exist. This file contains metadata about your connector:

```json
{
  "name": "AWS Glue Schema Registry Connector",
  "description": "Java client for AWS Glue Schema Registry with Avro and JSON serialization support",
  "type": "connector",
  "category": "AWS",
  "version": "1.0.0",
  "vendor": "AWS Glue Schema Registry",
  "tags": [
    "aws",
    "glue",
    "schema-registry",
    "avro",
    "json",
    "serialization"
  ],
  "minMuleVersion": "4.0.0",
  "requiredProduct": "MULE",
  "classifier": "mule-connector"
}
```

You can customize this file before publishing to match your requirements.

## Publishing Checklist

Before publishing, ensure:

- [ ] Version number is updated and follows semantic versioning
- [ ] All tests pass (`make java-test`)
- [ ] Documentation is up to date
- [ ] `exchange.json` metadata is correct
- [ ] Credentials are configured (environment variables)
- [ ] Build succeeds without errors
- [ ] JAR file is created successfully

## Troubleshooting

### Error: "ANYPOINT_USERNAME and ANYPOINT_PASSWORD are required"

**Solution**: Set the environment variables:
```bash
export ANYPOINT_USERNAME=your-username
export ANYPOINT_PASSWORD=your-password
```

### Error: "Anypoint CLI not found"

**Solution**: Install Anypoint CLI:
```bash
# macOS
brew install mulesoft/tap/anypoint-cli

# Or download from MuleSoft documentation
```

### Error: "Java 17 or higher is required"

**Solution**: Ensure Java 17+ is installed and `JAVA_HOME` is set correctly.

### Error: "JAR file not found"

**Solution**: Ensure the build completed successfully. Run `make java-build` first.

### Error: "Authentication failed"

**Solution**: Verify your Anypoint Platform credentials are correct. You can test login manually:
```bash
anypoint-cli login --username your-username --password your-password
```

### Error: "Organization ID not found"

**Solution**: Find your organization ID in Anypoint Platform:
1. Log in to Anypoint Platform
2. Go to Access Management → Organizations
3. Copy the Organization ID
4. Set `ANYPOINT_ORG_ID` environment variable

## Post-Publishing

After successful publishing:

1. **Verify in Exchange**
   - Log in to Anypoint Platform
   - Navigate to Exchange
   - Search for your connector
   - Verify version and metadata

2. **Update Documentation**
   - Update `README.md` with new version
   - Update changelog if applicable

3. **Tag Release**
   - Create a Git tag for the version:
     ```bash
     git tag -a v1.0.0 -m "Release version 1.0.0"
     git push origin v1.0.0
     ```

4. **Notify Users**
   - Announce the new version
   - Share release notes

## Best Practices

1. **Semantic Versioning**: Follow semantic versioning (MAJOR.MINOR.PATCH)
2. **Test Before Publishing**: Always run tests before publishing
3. **Version Control**: Commit version changes after publishing
4. **Documentation**: Keep documentation up to date with each release
5. **Security**: Never commit credentials; use environment variables
6. **Dry Run**: Use `--dry-run` to test the publishing process
7. **Changelog**: Maintain a changelog for version history

## Example Workflows

### Linux/macOS Workflow

```bash
# 1. Set credentials
export ANYPOINT_USERNAME=myuser
export ANYPOINT_PASSWORD=mypassword
export ANYPOINT_ORG_ID=12345678-1234-1234-1234-123456789012

# 2. Test with dry run
make java-publish-exchange VERSION=1.0.0
# Or: ./scripts/publish-mulesoft-exchange.sh --version 1.0.0 --dry-run

# 3. Publish for real
make java-publish-exchange VERSION=1.0.0

# 4. Verify in Exchange
# (Check Anypoint Platform Exchange)

# 5. Commit version changes
git add java/pom.xml java/build.gradle
git commit -m "Bump version to 1.0.0"
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin main --tags
```

### Windows Workflow (PowerShell)

```powershell
# 1. Set credentials
$env:ANYPOINT_USERNAME = "myuser"
$env:ANYPOINT_PASSWORD = "mypassword"
$env:ANYPOINT_ORG_ID = "12345678-1234-1234-1234-123456789012"

# 2. Test with dry run
.\scripts\publish-mulesoft-exchange.ps1 -Version 1.0.0 -DryRun

# 3. Publish for real
.\scripts\publish-mulesoft-exchange.ps1 -Version 1.0.0

# 4. Verify in Exchange
# (Check Anypoint Platform Exchange)

# 5. Commit version changes
git add java/pom.xml java/build.gradle
git commit -m "Bump version to 1.0.0"
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin main --tags
```

## Additional Resources

- [MuleSoft Exchange Documentation](https://docs.mulesoft.com/exchange/)
- [Anypoint Platform CLI Documentation](https://docs.mulesoft.com/anypoint-platform-cli/)
- [Maven Anypoint Exchange Plugin](https://github.com/mulesoft/anypoint-exchange-maven-plugin)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review MuleSoft Exchange documentation
3. Contact MuleSoft support if needed

