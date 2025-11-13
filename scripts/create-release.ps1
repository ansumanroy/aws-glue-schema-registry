# PowerShell Script to create a GitHub release with artifacts and documentation
# This script builds all artifacts, generates documentation, creates a tag,
# creates a GitHub release, and uploads all artifacts

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Notes,
    
    [Parameter(Mandatory=$false)]
    [switch]$Draft,
    
    [Parameter(Mandatory=$false)]
    [switch]$Prerelease,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipDocs,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTag,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipPush,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Show-Usage {
    Write-ColorOutput "Usage: .\create-release.ps1 [OPTIONS]" "Cyan"
    Write-Host ""
    Write-Host "Create a GitHub release with artifacts and documentation."
    Write-Host ""
    Write-Host "OPTIONS:"
    Write-Host "    -Version VERSION       Version to release (e.g., 1.0.0) [required]"
    Write-Host "    -Notes NOTES           Release notes (file path or text) [optional]"
    Write-Host "    -Draft                 Create as draft release"
    Write-Host "    -Prerelease            Mark as prerelease"
    Write-Host "    -SkipBuild             Skip building artifacts"
    Write-Host "    -SkipDocs              Skip generating documentation"
    Write-Host "    -SkipTag               Skip creating Git tag"
    Write-Host "    -SkipPush              Skip pushing to GitHub"
    Write-Host "    -DryRun                Perform a dry run without actually creating release"
    Write-Host "    -Help                  Show this help message"
    Write-Host ""
    Write-Host "ENVIRONMENT VARIABLES:"
    Write-Host "    GITHUB_TOKEN           GitHub personal access token (required for publishing)"
    Write-Host "    GITHUB_REPO            GitHub repository (format: owner/repo) [optional, auto-detected]"
    Write-Host ""
    Write-Host "EXAMPLES:"
    Write-Host "    # Create release version 1.0.0"
    Write-Host "    .\create-release.ps1 -Version 1.0.0"
    Write-Host ""
    Write-Host "    # Create draft release with release notes"
    Write-Host "    .\create-release.ps1 -Version 1.0.0 -Notes 'Release notes here' -Draft"
    Write-Host ""
    Write-Host "    # Create release from release notes file"
    Write-Host "    .\create-release.ps1 -Version 1.0.0 -Notes RELEASE_NOTES.md"
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

# Validate version format (semantic versioning)
if ($Version -notmatch '^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$') {
    Write-ColorOutput "Warning: Version '$Version' doesn't follow semantic versioning (X.Y.Z)" "Yellow"
    $response = Read-Host "Continue anyway? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        exit 1
    }
}

# Check if GitHub CLI is installed
try {
    $null = Get-Command gh -ErrorAction Stop
} catch {
    Write-ColorOutput "Error: GitHub CLI (gh) is not installed" "Red"
    Write-ColorOutput "Install it from: https://cli.github.com/" "Yellow"
    exit 1
}

# Check if authenticated with GitHub
if (-not $DryRun -and -not $SkipPush) {
    try {
        gh auth status | Out-Null
    } catch {
        Write-ColorOutput "Error: Not authenticated with GitHub" "Red"
        Write-ColorOutput "Run: gh auth login" "Yellow"
        exit 1
    }
}

# Get repository name
if (-not $env:GITHUB_REPO) {
    try {
        $remoteUrl = git remote get-url origin 2>$null
        if ($remoteUrl -match 'github\.com[:/]([^/]+/[^/]+)') {
            $env:GITHUB_REPO = $matches[1] -replace '\.git$', ''
        }
    } catch {}
    
    if (-not $env:GITHUB_REPO) {
        Write-ColorOutput "Error: Could not determine GitHub repository" "Red"
        Write-ColorOutput "Set GITHUB_REPO environment variable (format: owner/repo)" "Yellow"
        exit 1
    }
}

Write-ColorOutput "=== Creating GitHub Release ===" "Cyan"
Write-ColorOutput "Version: $Version" "Cyan"
Write-ColorOutput "Repository: $env:GITHUB_REPO" "Cyan"
Write-ColorOutput "Draft: $Draft" "Cyan"
Write-ColorOutput "Prerelease: $Prerelease" "Cyan"
Write-ColorOutput "Dry Run: $DryRun" "Cyan"
Write-Host ""

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Change to project root
Push-Location $ProjectRoot

# Function to update version in build files
function Update-Version {
    param([string]$Version)
    
    Write-ColorOutput "Updating version to $Version in build files..." "Cyan"
    
    # Update Java build.gradle
    $gradleFile = Join-Path $ProjectRoot "java\build.gradle"
    if (Test-Path $gradleFile) {
        $content = Get-Content $gradleFile -Raw
        $content = $content -replace "(?m)^version = ['`"].*['`"]", "version = '$Version'"
        Set-Content -Path $gradleFile -Value $content -NoNewline
        Write-ColorOutput "  ✓ Updated java/build.gradle" "Green"
    }
    
    # Update Java pom.xml - update only the project version
    $pomFile = Join-Path $ProjectRoot "java\pom.xml"
    if (Test-Path $pomFile) {
        $content = Get-Content $pomFile -Raw
        # Match version tag after schema-registry-client artifactId
        $content = $content -replace "(<artifactId>schema-registry-client</artifactId>\s*<version>)[^<]+(</version>)", "`${1}$Version`${2}"
        Set-Content -Path $pomFile -Value $content -NoNewline
        Write-ColorOutput "  ✓ Updated java/pom.xml" "Green"
    }
    
    # Update Python setup.py
    $setupFile = Join-Path $ProjectRoot "python\setup.py"
    if (Test-Path $setupFile) {
        $content = Get-Content $setupFile -Raw
        $content = $content -replace "(?m)^    version=[`"'][^`"']*[`"']", "    version=`"$Version`""
        Set-Content -Path $setupFile -Value $content -NoNewline
        Write-ColorOutput "  ✓ Updated python/setup.py" "Green"
    }
    
    # Update Python __init__.py
    $initFile = Join-Path $ProjectRoot "python\glue_schema_registry\__init__.py"
    if (Test-Path $initFile) {
        $content = Get-Content $initFile -Raw
        $content = $content -replace "(?m)^__version__ = [`"'][^`"']*[`"']", "__version__ = `"$Version`""
        Set-Content -Path $initFile -Value $content -NoNewline
        Write-ColorOutput "  ✓ Updated python/glue_schema_registry/__init__.py" "Green"
    }
    
    Write-ColorOutput "✓ Version updated in all build files" "Green"
}

# Function to backup build files
function Backup-BuildFiles {
    Write-ColorOutput "Backing up build files..." "Cyan"
    $files = @(
        "java\build.gradle",
        "java\pom.xml",
        "python\setup.py",
        "python\glue_schema_registry\__init__.py"
    )
    
    foreach ($file in $files) {
        $filePath = Join-Path $ProjectRoot $file
        if (Test-Path $filePath) {
            Copy-Item -Path $filePath -Destination "$filePath.bak" -ErrorAction SilentlyContinue
        }
    }
}

# Function to restore build files
function Restore-BuildFiles {
    Write-ColorOutput "Restoring original build files..." "Cyan"
    $files = @(
        "java\build.gradle",
        "java\pom.xml",
        "python\setup.py",
        "python\glue_schema_registry\__init__.py"
    )
    
    foreach ($file in $files) {
        $filePath = Join-Path $ProjectRoot $file
        $backupPath = "$filePath.bak"
        if (Test-Path $backupPath) {
            Move-Item -Path $backupPath -Destination $filePath -Force -ErrorAction SilentlyContinue
        }
    }
}

try {
    # Create release directory
    $ReleaseDir = Join-Path $ProjectRoot "release-artifacts"
    New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null
    
    # Update versions before building
    if (-not $SkipBuild) {
        Backup-BuildFiles
        Update-Version -Version $Version
    }
    
    # Build artifacts
    if (-not $SkipBuild) {
        Write-ColorOutput "Building artifacts..." "Cyan"
        
        # Build Java JARs
        Write-ColorOutput "Building Java artifacts..." "Cyan"
        & make java-jar 2>&1 | Out-Null
        & make java-jar-fat 2>&1 | Out-Null
        
        # Copy Java artifacts
        $JavaDir = Join-Path $ReleaseDir "java"
        New-Item -ItemType Directory -Force -Path $JavaDir | Out-Null
        Copy-Item -Path "java\build\libs\*.jar" -Destination $JavaDir -ErrorAction SilentlyContinue
        Copy-Item -Path "java\target\*.jar" -Destination $JavaDir -ErrorAction SilentlyContinue
        
        # Build Python package
        Write-ColorOutput "Building Python package..." "Cyan"
        & make python-build 2>&1 | Out-Null
        
        # Copy Python artifacts
        $PythonDir = Join-Path $ReleaseDir "python"
        New-Item -ItemType Directory -Force -Path $PythonDir | Out-Null
        Copy-Item -Path "python\dist\*" -Destination $PythonDir -ErrorAction SilentlyContinue
        
        # Build Golang binaries
        Write-ColorOutput "Building Golang binaries..." "Cyan"
        & make golang-build 2>&1 | Out-Null
        
        # Copy Golang artifacts
        $GolangDir = Join-Path $ReleaseDir "golang"
        New-Item -ItemType Directory -Force -Path $GolangDir | Out-Null
        Get-ChildItem -Path "golang" -File -Exclude "*.go" | Copy-Item -Destination $GolangDir -ErrorAction SilentlyContinue
        
        Write-ColorOutput "✓ Artifacts built" "Green"
    } else {
        Write-ColorOutput "⚠ Skipping build" "Yellow"
    }
    
    # Generate documentation
    if (-not $SkipDocs) {
        Write-ColorOutput "Generating documentation..." "Cyan"
        & make docs 2>&1 | Out-Null
        
        # Copy documentation
        $DocsDir = Join-Path $ReleaseDir "docs"
        New-Item -ItemType Directory -Force -Path $DocsDir | Out-Null
        
        # Java Javadoc
        if (Test-Path "java\build\docs\javadoc") {
            Copy-Item -Path "java\build\docs\javadoc" -Destination "$DocsDir\java-javadoc" -Recurse -ErrorAction SilentlyContinue
        }
        if (Test-Path "java\target\docs\javadoc") {
            Copy-Item -Path "java\target\docs\javadoc" -Destination "$DocsDir\java-javadoc" -Recurse -ErrorAction SilentlyContinue
        }
        
        # Python docs
        if (Test-Path "python\docs\html") {
            Copy-Item -Path "python\docs\html" -Destination "$DocsDir\python-docs" -Recurse -ErrorAction SilentlyContinue
        }
        
        # Golang docs
        if (Test-Path "golang\docs\html") {
            Copy-Item -Path "golang\docs\html" -Destination "$DocsDir\golang-docs" -Recurse -ErrorAction SilentlyContinue
        }
        
        # Create documentation archive
        if (Test-Path $DocsDir) {
            Push-Location $ReleaseDir
            Compress-Archive -Path "docs" -DestinationPath "docs-$Version.zip" -Force -ErrorAction SilentlyContinue
            Pop-Location
            Write-ColorOutput "✓ Documentation generated" "Green"
        }
    } else {
        Write-ColorOutput "⚠ Skipping documentation generation" "Yellow"
    }
    
    # Create Git tag
    if (-not $SkipTag) {
        Write-ColorOutput "Creating Git tag..." "Cyan"
        
        $tagName = "v$Version"
        
        # Check if tag already exists
        $existingTag = git tag -l $tagName
        if ($existingTag) {
            Write-ColorOutput "Tag $tagName already exists" "Yellow"
            $response = Read-Host "Delete and recreate? (y/N)"
            if ($response -eq 'y' -or $response -eq 'Y') {
                git tag -d $tagName 2>$null
                git push origin ":refs/tags/$tagName" 2>$null
            } else {
                $SkipTag = $true
            }
        }
        
        if (-not $SkipTag) {
            if (-not $DryRun) {
                git tag -a $tagName -m "Release version $Version"
                Write-ColorOutput "✓ Tag $tagName created" "Green"
            } else {
                Write-ColorOutput "Would create tag: $tagName" "Yellow"
            }
        }
    } else {
        Write-ColorOutput "⚠ Skipping tag creation" "Yellow"
    }
    
    # Prepare release notes
    $ReleaseNotesText = ""
    if ($Notes) {
        if (Test-Path $Notes) {
            $ReleaseNotesText = Get-Content $Notes -Raw
        } else {
            $ReleaseNotesText = $Notes
        }
    } else {
        # Generate default release notes
        $ReleaseNotesText = @"
## Release v$Version

### Changes
- See commit history for details

### Artifacts
- Java JAR files (standard and fat JAR)
- Python wheel and source distribution
- Golang binaries (if applicable)
- Documentation (Javadoc, pydoc, godoc)

### Installation
See README.md for installation instructions.
"@
    }
    
    # Create GitHub release
    if (-not $DryRun) {
        Write-ColorOutput "Creating GitHub release..." "Cyan"
        
        # Push tag first if not skipped
        if (-not $SkipTag -and -not $SkipPush) {
            Write-ColorOutput "Pushing tag to GitHub..." "Cyan"
            git push origin "v$Version"
        }
        
        # Create release
        $releaseArgs = @(
            "release", "create", "v$Version",
            "--title", "Release v$Version",
            "--notes", $ReleaseNotesText
        )
        
        if ($Draft) {
            $releaseArgs += "--draft"
        }
        
        if ($Prerelease) {
            $releaseArgs += "--prerelease"
        }
        
        & gh $releaseArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✓ GitHub release created" "Green"
        } else {
            Write-ColorOutput "Error: Failed to create GitHub release" "Red"
            exit 1
        }
        
        # Upload artifacts
        Write-ColorOutput "Uploading artifacts..." "Cyan"
        
        # Upload Java artifacts
        if (Test-Path "$ReleaseDir\java") {
            Get-ChildItem "$ReleaseDir\java\*.jar" | ForEach-Object {
                Write-ColorOutput "  Uploading $($_.Name)..." "Cyan"
                & gh release upload "v$Version" $_.FullName --clobber
            }
        }
        
        # Upload Python artifacts
        if (Test-Path "$ReleaseDir\python") {
            Get-ChildItem "$ReleaseDir\python\*" | ForEach-Object {
                Write-ColorOutput "  Uploading $($_.Name)..." "Cyan"
                & gh release upload "v$Version" $_.FullName --clobber
            }
        }
        
        # Upload Golang artifacts
        if (Test-Path "$ReleaseDir\golang") {
            Get-ChildItem "$ReleaseDir\golang\*" | ForEach-Object {
                Write-ColorOutput "  Uploading $($_.Name)..." "Cyan"
                & gh release upload "v$Version" $_.FullName --clobber
            }
        }
        
        # Upload documentation archives
        if (Test-Path "$ReleaseDir\docs-$Version.zip") {
            Write-ColorOutput "  Uploading documentation (zip)..." "Cyan"
            & gh release upload "v$Version" "$ReleaseDir\docs-$Version.zip" --clobber
        }
        
        Write-ColorOutput "✓ Artifacts uploaded" "Green"
        
        # Get release URL
        $releaseUrl = gh release view "v$Version" --json url -q .url 2>$null
        if ($releaseUrl) {
            Write-Host ""
            Write-ColorOutput "=== Release Created Successfully ===" "Green"
            Write-ColorOutput "Release URL: $releaseUrl" "Green"
        }
    } else {
        Write-ColorOutput "=== DRY RUN MODE ===" "Yellow"
        Write-ColorOutput "Would create release with:" "Yellow"
        Write-Host "  Version: v$Version"
        Write-Host "  Draft: $Draft"
        Write-Host "  Prerelease: $Prerelease"
        Write-Host "  Artifacts:"
        Get-ChildItem -Path $ReleaseDir -Recurse -File | ForEach-Object {
            Write-Host "    $($_.FullName)"
        }
        Write-Host ""
        Write-ColorOutput "To actually create the release, run without -DryRun flag" "Yellow"
    }
    
    # Optionally restore original versions (uncomment to restore after release)
    # Note: By default, versions are left updated. Uncomment the line below to restore.
    # if (-not $SkipBuild -and -not $DryRun) {
    #     Restore-BuildFiles
    #     Write-ColorOutput "✓ Original versions restored" "Green"
    # }
    
    # Cleanup backup files
    if (-not $DryRun) {
        $backupFiles = @(
            "java\build.gradle.bak",
            "java\pom.xml.bak",
            "python\setup.py.bak",
            "python\glue_schema_registry\__init__.py.bak"
        )
        foreach ($file in $backupFiles) {
            $filePath = Join-Path $ProjectRoot $file
            if (Test-Path $filePath) {
                Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Write-Host ""
    Write-ColorOutput "=== Release Process Complete ===" "Green"
    if (-not $SkipBuild -and -not $DryRun) {
        Write-ColorOutput "Note: Build file versions have been updated to $Version" "Yellow"
        Write-ColorOutput "To restore original versions, uncomment Restore-BuildFiles call in the script" "Yellow"
    }
    
} catch {
    Write-ColorOutput "Error: $_" "Red"
    exit 1
} finally {
    Pop-Location
}

