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

# Cleanup (optional - comment out if you want to keep artifacts)
# rm -rf "$RELEASE_DIR"

echo ""
echo -e "${COLOR_GREEN}${COLOR_BOLD}=== Release Process Complete ===${COLOR_RESET}"

