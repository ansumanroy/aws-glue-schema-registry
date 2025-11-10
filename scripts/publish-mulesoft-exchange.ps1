# PowerShell Script to publish AWS Glue Schema Registry Java Client to MuleSoft Exchange
# This script builds the project and publishes it to MuleSoft Exchange

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("maven", "gradle")]
    [string]$BuildSystem = "maven",
    
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# Colors for output (PowerShell 5.1+)
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Show-Usage {
    Write-ColorOutput "Usage: .\publish-mulesoft-exchange.ps1 [OPTIONS]" "Cyan"
    Write-Host ""
    Write-Host "Publish AWS Glue Schema Registry Java Client to MuleSoft Exchange."
    Write-Host ""
    Write-Host "OPTIONS:"
    Write-Host "    -BuildSystem SYSTEM    Build system to use (maven|gradle) [default: maven]"
    Write-Host "    -Version VERSION       Version to publish (e.g., 1.0.0) [required]"
    Write-Host "    -SkipBuild             Skip building the project"
    Write-Host "    -SkipTests             Skip running tests before building"
    Write-Host "    -DryRun                Perform a dry run without actually publishing"
    Write-Host "    -Help                  Show this help message"
    Write-Host ""
    Write-Host "ENVIRONMENT VARIABLES:"
    Write-Host "    ANYPOINT_USERNAME      MuleSoft Anypoint Platform username"
    Write-Host "    ANYPOINT_PASSWORD      MuleSoft Anypoint Platform password"
    Write-Host "    ANYPOINT_ORG_ID        MuleSoft organization ID"
    Write-Host "    ANYPOINT_ENV_ID        MuleSoft environment ID (optional)"
    Write-Host ""
    Write-Host "EXAMPLES:"
    Write-Host "    # Publish version 1.0.0 using Maven"
    Write-Host "    .\publish-mulesoft-exchange.ps1 -Version 1.0.0"
    Write-Host ""
    Write-Host "    # Publish using Gradle with dry run"
    Write-Host "    .\publish-mulesoft-exchange.ps1 -Version 1.0.0 -BuildSystem gradle -DryRun"
    Write-Host ""
    Write-Host "    # Skip tests and build"
    Write-Host "    .\publish-mulesoft-exchange.ps1 -Version 1.0.0 -SkipTests -SkipBuild"
    Write-Host ""
}

# Show help if requested
if ($Help) {
    Show-Usage
    exit 0
}

# Validate version
if (-not $Version) {
    Write-ColorOutput "Error: Version is required. Use -Version parameter." "Red"
    Show-Usage
    exit 1
}

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$JavaDir = Join-Path $ProjectRoot "java"

# Check required environment variables
if (-not $DryRun) {
    if (-not $env:ANYPOINT_USERNAME -or -not $env:ANYPOINT_PASSWORD) {
        Write-ColorOutput "Error: ANYPOINT_USERNAME and ANYPOINT_PASSWORD environment variables are required" "Red"
        Write-ColorOutput "Set them before running the script:" "Yellow"
        Write-Host "  `$env:ANYPOINT_USERNAME = 'your-username'"
        Write-Host "  `$env:ANYPOINT_PASSWORD = 'your-password'"
        exit 1
    }
}

# Check if Java is available
try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    if (-not $javaVersion) {
        throw "Java not found"
    }
} catch {
    Write-ColorOutput "Error: Java is not installed or not in PATH" "Red"
    exit 1
}

# Check Java version
$javaVersionOutput = java -version 2>&1 | Select-Object -First 1
$javaVersionMatch = $javaVersionOutput -match 'version "(\d+)'
if ($javaVersionMatch) {
    $javaVersionNumber = [int]$matches[1]
    if ($javaVersionNumber -lt 17) {
        Write-ColorOutput "Error: Java 17 or higher is required. Current version: $javaVersionNumber" "Red"
        exit 1
    }
} else {
    Write-ColorOutput "Warning: Could not determine Java version. Proceeding anyway..." "Yellow"
}

Write-ColorOutput "=== Publishing to MuleSoft Exchange ===" "Cyan"
Write-ColorOutput "Version: $Version" "Cyan"
Write-ColorOutput "Build System: $BuildSystem" "Cyan"
Write-ColorOutput "Dry Run: $DryRun" "Cyan"
Write-Host ""

# Change to Java directory
Push-Location $JavaDir

try {
    # Update version in pom.xml if using Maven
    if ($BuildSystem -eq "maven") {
        Write-ColorOutput "Updating version in pom.xml..." "Cyan"
        $pomPath = Join-Path $JavaDir "pom.xml"
        if (Test-Path $pomPath) {
            $pomContent = Get-Content $pomPath -Raw
            $pomContent = $pomContent -replace '<version>.*?</version>', "<version>$Version</version>"
            Set-Content -Path $pomPath -Value $pomContent -NoNewline
        }
    }
    
    # Update version in build.gradle if using Gradle
    if ($BuildSystem -eq "gradle") {
        Write-ColorOutput "Updating version in build.gradle..." "Cyan"
        $gradlePath = Join-Path $JavaDir "build.gradle"
        if (Test-Path $gradlePath) {
            $gradleContent = Get-Content $gradlePath -Raw
            $gradleContent = $gradleContent -replace "version = '.*?'", "version = '$Version'"
            Set-Content -Path $gradlePath -Value $gradleContent -NoNewline
        }
    }
    
    # Build the project
    if (-not $SkipBuild) {
        Write-ColorOutput "Building project..." "Cyan"
        
        if ($BuildSystem -eq "maven") {
            if ($SkipTests) {
                mvn clean package -DskipTests
            } else {
                mvn clean package
            }
            $JarFile = Join-Path $JavaDir "target\schema-registry-client-$Version.jar"
            $FatJarFile = Join-Path $JavaDir "target\schema-registry-client-$Version-all.jar"
        } else {
            if ($SkipTests) {
                .\gradlew.bat clean build -x test
            } else {
                .\gradlew.bat clean build
            }
            $JarFile = Join-Path $JavaDir "build\libs\schema-registry-client-$Version.jar"
            $FatJarFile = Join-Path $JavaDir "build\libs\schema-registry-client-$Version-all.jar"
        }
        
        # Check if JAR files exist
        if (-not (Test-Path $JarFile)) {
            Write-ColorOutput "Error: JAR file not found: $JarFile" "Red"
            exit 1
        }
        
        Write-ColorOutput "✓ Build successful" "Green"
        Write-ColorOutput "  JAR: $JarFile" "Green"
        if (Test-Path $FatJarFile) {
            Write-ColorOutput "  Fat JAR: $FatJarFile" "Green"
        }
    } else {
        Write-ColorOutput "⚠ Skipping build" "Yellow"
    }
    
    # Create exchange.json if it doesn't exist
    $ExchangeJson = Join-Path $JavaDir "exchange.json"
    if (-not (Test-Path $ExchangeJson)) {
        Write-ColorOutput "Creating exchange.json..." "Cyan"
        $exchangeContent = @{
            name = "AWS Glue Schema Registry Connector"
            description = "Java client for AWS Glue Schema Registry with Avro and JSON serialization support"
            type = "connector"
            category = "AWS"
            version = $Version
            vendor = "AWS Glue Schema Registry"
            tags = @("aws", "glue", "schema-registry", "avro", "json", "serialization")
            minMuleVersion = "4.0.0"
            requiredProduct = "MULE"
            classifier = "mule-connector"
        } | ConvertTo-Json -Depth 10
        
        Set-Content -Path $ExchangeJson -Value $exchangeContent
        Write-ColorOutput "✓ Created exchange.json" "Green"
    }
    
    # Publish to MuleSoft Exchange
    if ($DryRun) {
        Write-ColorOutput "=== DRY RUN MODE ===" "Yellow"
        Write-ColorOutput "Would publish to MuleSoft Exchange with:" "Yellow"
        Write-Host "  Version: $Version"
        Write-Host "  Build System: $BuildSystem"
        Write-Host "  JAR: $JarFile"
        if (Test-Path $FatJarFile) {
            Write-Host "  Fat JAR: $FatJarFile"
        }
        Write-Host ""
        Write-ColorOutput "To actually publish, run without -DryRun flag" "Yellow"
    } else {
        Write-ColorOutput "Publishing to MuleSoft Exchange..." "Cyan"
        
        # Check if Anypoint CLI is installed
        $anypointCli = Get-Command anypoint-cli -ErrorAction SilentlyContinue
        $anypoint = Get-Command anypoint -ErrorAction SilentlyContinue
        
        if ($anypointCli -or $anypoint) {
            Write-ColorOutput "Using Anypoint CLI..." "Cyan"
            
            # Login to Anypoint Platform
            if ($anypointCli) {
                & anypoint-cli login --username $env:ANYPOINT_USERNAME --password $env:ANYPOINT_PASSWORD
            } else {
                & anypoint login --username $env:ANYPOINT_USERNAME --password $env:ANYPOINT_PASSWORD
            }
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "Error: Failed to login to Anypoint Platform" "Red"
                exit 1
            }
            
            # Build command arguments
            $publishArgs = @($JarFile)
            if ($env:ANYPOINT_ORG_ID) {
                $publishArgs += "--org-id"
                $publishArgs += $env:ANYPOINT_ORG_ID
            }
            if ($env:ANYPOINT_ENV_ID) {
                $publishArgs += "--env-id"
                $publishArgs += $env:ANYPOINT_ENV_ID
            }
            
            # Publish using Anypoint CLI
            if ($anypointCli) {
                & anypoint-cli exchange publish $publishArgs
            } else {
                & anypoint exchange publish $publishArgs
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✓ Published to MuleSoft Exchange" "Green"
            } else {
                Write-ColorOutput "Error: Failed to publish to MuleSoft Exchange" "Red"
                exit 1
            }
        } elseif ($BuildSystem -eq "maven") {
            # Use Maven Anypoint Exchange Plugin
            Write-ColorOutput "Using Maven Anypoint Exchange Plugin..." "Cyan"
            
            # Check if plugin is configured in pom.xml
            $pomPath = Join-Path $JavaDir "pom.xml"
            $pomContent = Get-Content $pomPath -Raw
            if ($pomContent -match "anypoint-exchange-maven-plugin") {
                $mavenArgs = @(
                    "anypoint-exchange:deploy",
                    "-Danypoint.username=$env:ANYPOINT_USERNAME",
                    "-Danypoint.password=$env:ANYPOINT_PASSWORD"
                )
                if ($env:ANYPOINT_ORG_ID) {
                    $mavenArgs += "-Danypoint.orgId=$env:ANYPOINT_ORG_ID"
                }
                if ($env:ANYPOINT_ENV_ID) {
                    $mavenArgs += "-Danypoint.envId=$env:ANYPOINT_ENV_ID"
                }
                
                mvn $mavenArgs
                
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorOutput "✓ Published to MuleSoft Exchange" "Green"
                } else {
                    Write-ColorOutput "Error: Failed to publish to MuleSoft Exchange" "Red"
                    exit 1
                }
            } else {
                Write-ColorOutput "⚠ Maven Anypoint Exchange Plugin not configured in pom.xml" "Yellow"
                Write-ColorOutput "  Install Anypoint CLI or configure the Maven plugin" "Yellow"
                Write-ColorOutput "  See MULESOFT_EXCHANGE.md for instructions" "Yellow"
                exit 1
            }
        } else {
            Write-ColorOutput "Error: Anypoint CLI not found and not using Maven" "Red"
            Write-ColorOutput "Install Anypoint CLI: https://docs.mulesoft.com/anypoint-platform-cli/" "Yellow"
            exit 1
        }
    }
    
    Write-Host ""
    Write-ColorOutput "=== Publishing Complete ===" "Green"
    Write-ColorOutput "Version $Version has been published to MuleSoft Exchange" "Green"
    
} catch {
    Write-ColorOutput "Error: $_" "Red"
    exit 1
} finally {
    Pop-Location
}

