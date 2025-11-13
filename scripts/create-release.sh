#!/bin/bash
# Script to create a GitHub release with artifacts and documentation
# This script builds all artifacts, generates documentation, creates a tag,
# creates a GitHub release, and uploads all artifacts

set -e  # Exit on error

# Colors for output
COLOR_RESET='\033[0m'
COLOR_BOLD='\033[1m'
COLOR_GREEN='\033[32m'
COLOR_YELLOW='\033[33m'
COLOR_BLUE='\033[34m'
COLOR_RED='\033[31m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
VERSION=""
RELEASE_NOTES=""
DRAFT=false
PRERELEASE=false
SKIP_BUILD=false
SKIP_DOCS=false
SKIP_TAG=false
SKIP_PUSH=false
DRY_RUN=false

# Function to print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Create a GitHub release with artifacts and documentation.

OPTIONS:
    -v, --version VERSION        Version to release (e.g., 1.0.0) [required]
    -n, --notes NOTES           Release notes (file path or text) [optional]
    -d, --draft                 Create as draft release
    -p, --prerelease            Mark as prerelease
    -s, --skip-build            Skip building artifacts
    -x, --skip-docs             Skip generating documentation
    -t, --skip-tag              Skip creating Git tag
    -u, --skip-push             Skip pushing to GitHub
    --dry-run                   Perform a dry run without actually creating release
    -h, --help                  Show this help message

ENVIRONMENT VARIABLES:
    GITHUB_TOKEN                GitHub personal access token (required for publishing)
    GITHUB_REPO                 GitHub repository (format: owner/repo) [optional, auto-detected]

EXAMPLES:
    # Create release version 1.0.0
    $0 --version 1.0.0

    # Create draft release with release notes
    $0 --version 1.0.0 --notes "Release notes here" --draft

    # Create release from release notes file
    $0 --version 1.0.0 --notes RELEASE_NOTES.md

    # Dry run (test without creating release)
    $0 --version 1.0.0 --dry-run

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -n|--notes)
            RELEASE_NOTES="$2"
            shift 2
            ;;
        -d|--draft)
            DRAFT=true
            shift
            ;;
        -p|--prerelease)
            PRERELEASE=true
            shift
            ;;
        -s|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -x|--skip-docs)
            SKIP_DOCS=true
            shift
            ;;
        -t|--skip-tag)
            SKIP_TAG=true
            shift
            ;;
        -u|--skip-push)
            SKIP_PUSH=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${COLOR_RED}Error: Unknown option: $1${COLOR_RESET}"
            usage
            exit 1
            ;;
    esac
done

# Validate version
if [ -z "$VERSION" ]; then
    echo -e "${COLOR_RED}Error: Version is required. Use -v or --version option.${COLOR_RESET}"
    usage
    exit 1
fi

# Validate version format (semantic versioning)
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
    echo -e "${COLOR_YELLOW}Warning: Version '$VERSION' doesn't follow semantic versioning (X.Y.Z)${COLOR_RESET}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${COLOR_RED}Error: GitHub CLI (gh) is not installed${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Install it from: https://cli.github.com/${COLOR_RESET}"
    exit 1
fi

# Check if authenticated with GitHub
if [ "$DRY_RUN" = false ] && [ "$SKIP_PUSH" = false ]; then
    # Test if we can actually use GitHub CLI by trying a simple command
    if ! gh api user &> /dev/null; then
        echo -e "${COLOR_RED}Error: Not authenticated with GitHub${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Run: gh auth login${COLOR_RESET}"
        exit 1
    fi
fi

# Get repository name
if [ -z "$GITHUB_REPO" ]; then
    GITHUB_REPO=$(git remote get-url origin 2>/dev/null | sed -E 's/.*github.com[:/]([^/]+\/[^/]+)(\.git)?$/\1/' || echo "")
    if [ -z "$GITHUB_REPO" ]; then
        echo -e "${COLOR_RED}Error: Could not determine GitHub repository${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Set GITHUB_REPO environment variable (format: owner/repo)${COLOR_RESET}"
        exit 1
    fi
fi

echo -e "${COLOR_BOLD}${COLOR_BLUE}=== Creating GitHub Release ===${COLOR_RESET}"
echo -e "${COLOR_BLUE}Version: ${COLOR_BOLD}$VERSION${COLOR_RESET}"
echo -e "${COLOR_BLUE}Repository: ${COLOR_BOLD}$GITHUB_REPO${COLOR_RESET}"
echo -e "${COLOR_BLUE}Draft: ${COLOR_BOLD}$DRAFT${COLOR_RESET}"
echo -e "${COLOR_BLUE}Prerelease: ${COLOR_BOLD}$PRERELEASE${COLOR_RESET}"
echo -e "${COLOR_BLUE}Dry Run: ${COLOR_BOLD}$DRY_RUN${COLOR_RESET}"
echo ""

# Change to project root
cd "$PROJECT_ROOT"

# Create release directory
RELEASE_DIR="$PROJECT_ROOT/release-artifacts"
mkdir -p "$RELEASE_DIR"

# Function to update version in build files
update_version() {
    local version="$1"
    echo -e "${COLOR_BLUE}Updating version to $version in build files...${COLOR_RESET}"
    
    # Update Java build.gradle - match the version line specifically
    if [ -f "$PROJECT_ROOT/java/build.gradle" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS uses BSD sed - match version line with optional leading whitespace
            sed -i '' "s/^[[:space:]]*version = ['\"].*['\"]/version = '$version'/" "$PROJECT_ROOT/java/build.gradle"
        else
            # Linux uses GNU sed
            sed -i "s/^[[:space:]]*version = ['\"].*['\"]/version = '$version'/" "$PROJECT_ROOT/java/build.gradle"
        fi
        echo -e "${COLOR_GREEN}  ✓ Updated java/build.gradle${COLOR_RESET}"
    fi
    
    # Update Java pom.xml - update only the project version (not dependency versions)
    if [ -f "$PROJECT_ROOT/java/pom.xml" ]; then
        # Use a more precise pattern to match only the project version tag
        # Match: <version>1.0.0-SNAPSHOT</version> that comes after <artifactId>schema-registry-client</artifactId>
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS: Use perl for more reliable in-place editing
            perl -i -pe "s/(<artifactId>schema-registry-client<\/artifactId>\s*<version>)[^<]+(<\/version>)/\${1}$version\${2}/" "$PROJECT_ROOT/java/pom.xml" 2>/dev/null || \
            sed -i '' "/<artifactId>schema-registry-client<\/artifactId>/,/<packaging>/s/<version>[^<]*<\/version>/<version>$version<\/version>/" "$PROJECT_ROOT/java/pom.xml"
        else
            # Linux: Use sed with more specific pattern
            sed -i "/<artifactId>schema-registry-client<\/artifactId>/,/<packaging>/s/<version>[^<]*<\/version>/<version>$version<\/version>/" "$PROJECT_ROOT/java/pom.xml"
        fi
        echo -e "${COLOR_GREEN}  ✓ Updated java/pom.xml${COLOR_RESET}"
    fi
    
    # Update Python setup.py - match version= specifically
    if [ -f "$PROJECT_ROOT/python/setup.py" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/^[[:space:]]*version=[\"'][^\"']*[\"']/    version=\"$version\"/" "$PROJECT_ROOT/python/setup.py"
        else
            sed -i "s/^[[:space:]]*version=[\"'][^\"']*[\"']/    version=\"$version\"/" "$PROJECT_ROOT/python/setup.py"
        fi
        echo -e "${COLOR_GREEN}  ✓ Updated python/setup.py${COLOR_RESET}"
    fi
    
    # Update Python __init__.py - match __version__ specifically
    if [ -f "$PROJECT_ROOT/python/glue_schema_registry/__init__.py" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/^__version__ = [\"'][^\"']*[\"']/__version__ = \"$version\"/" "$PROJECT_ROOT/python/glue_schema_registry/__init__.py"
        else
            sed -i "s/^__version__ = [\"'][^\"']*[\"']/__version__ = \"$version\"/" "$PROJECT_ROOT/python/glue_schema_registry/__init__.py"
        fi
        echo -e "${COLOR_GREEN}  ✓ Updated python/glue_schema_registry/__init__.py${COLOR_RESET}"
    fi
    
    echo -e "${COLOR_GREEN}✓ Version updated in all build files${COLOR_RESET}"
}

# Backup original versions (for potential restore)
backup_build_files() {
    echo -e "${COLOR_BLUE}Backing up build files...${COLOR_RESET}"
    cp "$PROJECT_ROOT/java/build.gradle" "$PROJECT_ROOT/java/build.gradle.bak" 2>/dev/null || true
    cp "$PROJECT_ROOT/java/pom.xml" "$PROJECT_ROOT/java/pom.xml.bak" 2>/dev/null || true
    cp "$PROJECT_ROOT/python/setup.py" "$PROJECT_ROOT/python/setup.py.bak" 2>/dev/null || true
    cp "$PROJECT_ROOT/python/glue_schema_registry/__init__.py" "$PROJECT_ROOT/python/glue_schema_registry/__init__.py.bak" 2>/dev/null || true
}

# Restore original versions
restore_build_files() {
    echo -e "${COLOR_BLUE}Restoring original build files...${COLOR_RESET}"
    mv "$PROJECT_ROOT/java/build.gradle.bak" "$PROJECT_ROOT/java/build.gradle" 2>/dev/null || true
    mv "$PROJECT_ROOT/java/pom.xml.bak" "$PROJECT_ROOT/java/pom.xml" 2>/dev/null || true
    mv "$PROJECT_ROOT/python/setup.py.bak" "$PROJECT_ROOT/python/setup.py" 2>/dev/null || true
    mv "$PROJECT_ROOT/python/glue_schema_registry/__init__.py.bak" "$PROJECT_ROOT/python/glue_schema_registry/__init__.py" 2>/dev/null || true
}

# Update versions before building
if [ "$SKIP_BUILD" = false ]; then
    backup_build_files
    update_version "$VERSION"
fi

# Build artifacts
if [ "$SKIP_BUILD" = false ]; then
    echo -e "${COLOR_BLUE}Building artifacts...${COLOR_RESET}"
    
    # Build Java JARs
    echo -e "${COLOR_BLUE}Building Java artifacts...${COLOR_RESET}"
    make java-jar
    make java-jar-fat
    
    # Copy Java artifacts
    mkdir -p "$RELEASE_DIR/java"
    cp java/build/libs/*.jar "$RELEASE_DIR/java/" 2>/dev/null || true
    cp java/target/*.jar "$RELEASE_DIR/java/" 2>/dev/null || true
    
    # Build Python package
    echo -e "${COLOR_BLUE}Building Python package...${COLOR_RESET}"
    make python-build || echo -e "${COLOR_YELLOW}Warning: Python build failed${COLOR_RESET}"
    
    # Copy Python artifacts
    mkdir -p "$RELEASE_DIR/python"
    cp python/dist/* "$RELEASE_DIR/python/" 2>/dev/null || true
    
    # Build Golang binaries
    echo -e "${COLOR_BLUE}Building Golang binaries...${COLOR_RESET}"
    make golang-build || echo -e "${COLOR_YELLOW}Warning: Golang build failed${COLOR_RESET}"
    
    # Copy Golang artifacts (if any binaries are created)
    mkdir -p "$RELEASE_DIR/golang"
    find golang -maxdepth 1 -type f -executable -not -name "*.go" -exec cp {} "$RELEASE_DIR/golang/" \; 2>/dev/null || true
    
    echo -e "${COLOR_GREEN}✓ Artifacts built${COLOR_RESET}"
else
    echo -e "${COLOR_YELLOW}⚠ Skipping build${COLOR_RESET}"
fi

# Generate documentation
if [ "$SKIP_DOCS" = false ]; then
    echo -e "${COLOR_BLUE}Generating documentation...${COLOR_RESET}"
    make docs || echo -e "${COLOR_YELLOW}Warning: Documentation generation had issues${COLOR_RESET}"
    
    # Copy documentation
    mkdir -p "$RELEASE_DIR/docs"
    
    # Java Javadoc
    if [ -d "java/build/docs/javadoc" ]; then
        cp -r java/build/docs/javadoc "$RELEASE_DIR/docs/java-javadoc" 2>/dev/null || true
    fi
    if [ -d "java/target/docs/javadoc" ]; then
        cp -r java/target/docs/javadoc "$RELEASE_DIR/docs/java-javadoc" 2>/dev/null || true
    fi
    
    # Python docs
    if [ -d "python/docs/html" ]; then
        cp -r python/docs/html "$RELEASE_DIR/docs/python-docs" 2>/dev/null || true
    fi
    
    # Golang docs
    if [ -d "golang/docs/html" ]; then
        cp -r golang/docs/html "$RELEASE_DIR/docs/golang-docs" 2>/dev/null || true
    fi
    
    # Create documentation archive
    if [ -d "$RELEASE_DIR/docs" ] && [ "$(ls -A $RELEASE_DIR/docs)" ]; then
        cd "$RELEASE_DIR"
        tar -czf "docs-$VERSION.tar.gz" docs/ 2>/dev/null || true
        zip -r "docs-$VERSION.zip" docs/ 2>/dev/null || true
        cd "$PROJECT_ROOT"
        echo -e "${COLOR_GREEN}✓ Documentation generated${COLOR_RESET}"
    fi
else
    echo -e "${COLOR_YELLOW}⚠ Skipping documentation generation${COLOR_RESET}"
fi

# Create Git tag
if [ "$SKIP_TAG" = false ]; then
    echo -e "${COLOR_BLUE}Creating Git tag...${COLOR_RESET}"
    
    # Check if tag already exists
    if git rev-parse "v$VERSION" >/dev/null 2>&1; then
        echo -e "${COLOR_YELLOW}Tag v$VERSION already exists${COLOR_RESET}"
        read -p "Delete and recreate? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag -d "v$VERSION" 2>/dev/null || true
            git push origin ":refs/tags/v$VERSION" 2>/dev/null || true
        else
            SKIP_TAG=true
        fi
    fi
    
    if [ "$SKIP_TAG" = false ]; then
        if [ "$DRY_RUN" = false ]; then
            git tag -a "v$VERSION" -m "Release version $VERSION"
            echo -e "${COLOR_GREEN}✓ Tag v$VERSION created${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}Would create tag: v$VERSION${COLOR_RESET}"
        fi
    fi
else
    echo -e "${COLOR_YELLOW}⚠ Skipping tag creation${COLOR_RESET}"
fi

# Prepare release notes
RELEASE_NOTES_TEXT=""
if [ -n "$RELEASE_NOTES" ]; then
    if [ -f "$RELEASE_NOTES" ]; then
        RELEASE_NOTES_TEXT=$(cat "$RELEASE_NOTES")
    else
        RELEASE_NOTES_TEXT="$RELEASE_NOTES"
    fi
else
    # Generate default release notes
    RELEASE_NOTES_TEXT="## Release v$VERSION

### Changes
- See commit history for details

### Artifacts
- Java JAR files (standard and fat JAR)
- Python wheel and source distribution
- Golang binaries (if applicable)
- Documentation (Javadoc, pydoc, godoc)

### Installation
See README.md for installation instructions."
fi

# Create GitHub release
if [ "$DRY_RUN" = false ]; then
    echo -e "${COLOR_BLUE}Creating GitHub release...${COLOR_RESET}"
    
    # Push tag first if not skipped
    if [ "$SKIP_TAG" = false ] && [ "$SKIP_PUSH" = false ]; then
        echo -e "${COLOR_BLUE}Pushing tag to GitHub...${COLOR_RESET}"
        git push origin "v$VERSION"
    fi
    
    # Create release
    RELEASE_ARGS=(
        "release" "create" "v$VERSION"
        "--title" "Release v$VERSION"
        "--notes" "$RELEASE_NOTES_TEXT"
    )
    
    if [ "$DRAFT" = true ]; then
        RELEASE_ARGS+=("--draft")
    fi
    
    if [ "$PRERELEASE" = true ]; then
        RELEASE_ARGS+=("--prerelease")
    fi
    
    gh "${RELEASE_ARGS[@]}"
    
    if [ $? -eq 0 ]; then
        echo -e "${COLOR_GREEN}✓ GitHub release created${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}Error: Failed to create GitHub release${COLOR_RESET}"
        exit 1
    fi
    
    # Upload artifacts
    echo -e "${COLOR_BLUE}Uploading artifacts...${COLOR_RESET}"
    
    # Upload Java artifacts
    if [ -d "$RELEASE_DIR/java" ]; then
        for file in "$RELEASE_DIR/java"/*.jar; do
            if [ -f "$file" ]; then
                echo -e "${COLOR_BLUE}  Uploading $(basename $file)...${COLOR_RESET}"
                gh release upload "v$VERSION" "$file" --clobber
            fi
        done
    fi
    
    # Upload Python artifacts
    if [ -d "$RELEASE_DIR/python" ]; then
        for file in "$RELEASE_DIR/python"/*; do
            if [ -f "$file" ]; then
                echo -e "${COLOR_BLUE}  Uploading $(basename $file)...${COLOR_RESET}"
                gh release upload "v$VERSION" "$file" --clobber
            fi
        done
    fi
    
    # Upload Golang artifacts
    if [ -d "$RELEASE_DIR/golang" ]; then
        for file in "$RELEASE_DIR/golang"/*; do
            if [ -f "$file" ]; then
                echo -e "${COLOR_BLUE}  Uploading $(basename $file)...${COLOR_RESET}"
                gh release upload "v$VERSION" "$file" --clobber
            fi
        done
    fi
    
    # Upload documentation archives
    if [ -f "$RELEASE_DIR/docs-$VERSION.tar.gz" ]; then
        echo -e "${COLOR_BLUE}  Uploading documentation (tar.gz)...${COLOR_RESET}"
        gh release upload "v$VERSION" "$RELEASE_DIR/docs-$VERSION.tar.gz" --clobber
    fi
    if [ -f "$RELEASE_DIR/docs-$VERSION.zip" ]; then
        echo -e "${COLOR_BLUE}  Uploading documentation (zip)...${COLOR_RESET}"
        gh release upload "v$VERSION" "$RELEASE_DIR/docs-$VERSION.zip" --clobber
    fi
    
    echo -e "${COLOR_GREEN}✓ Artifacts uploaded${COLOR_RESET}"
    
    # Get release URL
    RELEASE_URL=$(gh release view "v$VERSION" --json url -q .url 2>/dev/null || echo "")
    if [ -n "$RELEASE_URL" ]; then
        echo ""
        echo -e "${COLOR_GREEN}${COLOR_BOLD}=== Release Created Successfully ===${COLOR_RESET}"
        echo -e "${COLOR_GREEN}Release URL: $RELEASE_URL${COLOR_RESET}"
    fi
else
    echo -e "${COLOR_YELLOW}=== DRY RUN MODE ===${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Would create release with:${COLOR_RESET}"
    echo "  Version: v$VERSION"
    echo "  Draft: $DRAFT"
    echo "  Prerelease: $PRERELEASE"
    echo "  Artifacts:"
    find "$RELEASE_DIR" -type f -exec echo "    {}" \;
    echo ""
    echo -e "${COLOR_YELLOW}To actually create the release, run without --dry-run flag${COLOR_RESET}"
fi

# Optionally restore original versions (uncomment to restore after release)
# Note: By default, versions are left updated. Uncomment the line below to restore.
# if [ "$SKIP_BUILD" = false ] && [ "$DRY_RUN" = false ]; then
#     restore_build_files
#     echo -e "${COLOR_GREEN}✓ Original versions restored${COLOR_RESET}"
# fi

# Cleanup backup files (optional)
if [ "$DRY_RUN" = false ]; then
    rm -f "$PROJECT_ROOT/java/build.gradle.bak" 2>/dev/null || true
    rm -f "$PROJECT_ROOT/java/pom.xml.bak" 2>/dev/null || true
    rm -f "$PROJECT_ROOT/python/setup.py.bak" 2>/dev/null || true
    rm -f "$PROJECT_ROOT/python/glue_schema_registry/__init__.py.bak" 2>/dev/null || true
fi

# Cleanup (optional - comment out if you want to keep artifacts)
# rm -rf "$RELEASE_DIR"

echo ""
echo -e "${COLOR_GREEN}${COLOR_BOLD}=== Release Process Complete ===${COLOR_RESET}"
if [ "$SKIP_BUILD" = false ] && [ "$DRY_RUN" = false ]; then
    echo -e "${COLOR_YELLOW}Note: Build file versions have been updated to $VERSION${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}To restore original versions, uncomment restore_build_files() call in the script${COLOR_RESET}"
fi

