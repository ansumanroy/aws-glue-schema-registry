#!/bin/bash
# Script to publish AWS Glue Schema Registry Java Client to MuleSoft Exchange
# This script builds the project and publishes it to MuleSoft Exchange

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
JAVA_DIR="$PROJECT_ROOT/java"

# Default values
BUILD_SYSTEM="maven"
VERSION=""
SKIP_BUILD=false
SKIP_TESTS=false
DRY_RUN=false

# Function to print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Publish AWS Glue Schema Registry Java Client to MuleSoft Exchange.

OPTIONS:
    -b, --build-system SYSTEM    Build system to use (maven|gradle) [default: maven]
    -v, --version VERSION        Version to publish (e.g., 1.0.0) [required]
    -s, --skip-build             Skip building the project
    -t, --skip-tests             Skip running tests before building
    -d, --dry-run                Perform a dry run without actually publishing
    -h, --help                   Show this help message

ENVIRONMENT VARIABLES:
    ANYPOINT_USERNAME            MuleSoft Anypoint Platform username
    ANYPOINT_PASSWORD            MuleSoft Anypoint Platform password
    ANYPOINT_ORG_ID              MuleSoft organization ID
    ANYPOINT_ENV_ID              MuleSoft environment ID (optional)

EXAMPLES:
    # Publish version 1.0.0 using Maven
    $0 --version 1.0.0

    # Publish using Gradle with dry run
    $0 --version 1.0.0 --build-system gradle --dry-run

    # Skip tests and build
    $0 --version 1.0.0 --skip-tests --skip-build

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--build-system)
            BUILD_SYSTEM="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -s|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -t|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -d|--dry-run)
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

# Validate build system
if [[ "$BUILD_SYSTEM" != "maven" && "$BUILD_SYSTEM" != "gradle" ]]; then
    echo -e "${COLOR_RED}Error: Build system must be 'maven' or 'gradle'${COLOR_RESET}"
    exit 1
fi

# Check required environment variables
if [ "$DRY_RUN" = false ]; then
    if [ -z "$ANYPOINT_USERNAME" ] || [ -z "$ANYPOINT_PASSWORD" ]; then
        echo -e "${COLOR_RED}Error: ANYPOINT_USERNAME and ANYPOINT_PASSWORD environment variables are required${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Set them before running the script:${COLOR_RESET}"
        echo "  export ANYPOINT_USERNAME=your-username"
        echo "  export ANYPOINT_PASSWORD=your-password"
        exit 1
    fi
fi

# Check if Java is available
if ! command -v java &> /dev/null; then
    echo -e "${COLOR_RED}Error: Java is not installed or not in PATH${COLOR_RESET}"
    exit 1
fi

# Check Java version
JAVA_VERSION=$(java -version 2>&1 | head -1 | sed -n 's/.*version "\([0-9]*\)\..*/\1/p')
if [ -z "$JAVA_VERSION" ] || [ "$JAVA_VERSION" -lt 17 ]; then
    echo -e "${COLOR_RED}Error: Java 17 or higher is required. Current version: $JAVA_VERSION${COLOR_RESET}"
    exit 1
fi

echo -e "${COLOR_BOLD}${COLOR_BLUE}=== Publishing to MuleSoft Exchange ===${COLOR_RESET}"
echo -e "${COLOR_BLUE}Version: ${COLOR_BOLD}$VERSION${COLOR_RESET}"
echo -e "${COLOR_BLUE}Build System: ${COLOR_BOLD}$BUILD_SYSTEM${COLOR_RESET}"
echo -e "${COLOR_BLUE}Dry Run: ${COLOR_BOLD}$DRY_RUN${COLOR_RESET}"
echo ""

# Change to Java directory
cd "$JAVA_DIR"

# Update version in pom.xml if using Maven
if [ "$BUILD_SYSTEM" = "maven" ]; then
    echo -e "${COLOR_BLUE}Updating version in pom.xml...${COLOR_RESET}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/<version>.*<\/version>/<version>$VERSION<\/version>/" pom.xml
    else
        # Linux
        sed -i "s/<version>.*<\/version>/<version>$VERSION<\/version>/" pom.xml
    fi
fi

# Update version in build.gradle if using Gradle
if [ "$BUILD_SYSTEM" = "gradle" ]; then
    echo -e "${COLOR_BLUE}Updating version in build.gradle...${COLOR_RESET}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/version = '.*'/version = '$VERSION'/" build.gradle
    else
        # Linux
        sed -i "s/version = '.*'/version = '$VERSION'/" build.gradle
    fi
fi

# Build the project
if [ "$SKIP_BUILD" = false ]; then
    echo -e "${COLOR_BLUE}Building project...${COLOR_RESET}"
    
    if [ "$BUILD_SYSTEM" = "maven" ]; then
        if [ "$SKIP_TESTS" = true ]; then
            mvn clean package -DskipTests
        else
            mvn clean package
        fi
        JAR_FILE="target/schema-registry-client-$VERSION.jar"
        FAT_JAR_FILE="target/schema-registry-client-$VERSION-all.jar"
    else
        if [ "$SKIP_TESTS" = true ]; then
            ./gradlew clean build -x test
        else
            ./gradlew clean build
        fi
        JAR_FILE="build/libs/schema-registry-client-$VERSION.jar"
        FAT_JAR_FILE="build/libs/schema-registry-client-$VERSION-all.jar"
    fi
    
    # Check if JAR files exist
    if [ ! -f "$JAR_FILE" ]; then
        echo -e "${COLOR_RED}Error: JAR file not found: $JAR_FILE${COLOR_RESET}"
        exit 1
    fi
    
    echo -e "${COLOR_GREEN}✓ Build successful${COLOR_RESET}"
    echo -e "${COLOR_GREEN}  JAR: $JAR_FILE${COLOR_RESET}"
    if [ -f "$FAT_JAR_FILE" ]; then
        echo -e "${COLOR_GREEN}  Fat JAR: $FAT_JAR_FILE${COLOR_RESET}"
    fi
else
    echo -e "${COLOR_YELLOW}⚠ Skipping build${COLOR_RESET}"
fi

# Create exchange.json if it doesn't exist
EXCHANGE_JSON="$JAVA_DIR/exchange.json"
if [ ! -f "$EXCHANGE_JSON" ]; then
    echo -e "${COLOR_BLUE}Creating exchange.json...${COLOR_RESET}"
    cat > "$EXCHANGE_JSON" << EOF
{
  "name": "AWS Glue Schema Registry Connector",
  "description": "Java client for AWS Glue Schema Registry with Avro and JSON serialization support",
  "type": "connector",
  "category": "AWS",
  "version": "$VERSION",
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
EOF
    echo -e "${COLOR_GREEN}✓ Created exchange.json${COLOR_RESET}"
fi

# Publish to MuleSoft Exchange
if [ "$DRY_RUN" = true ]; then
    echo -e "${COLOR_YELLOW}=== DRY RUN MODE ===${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Would publish to MuleSoft Exchange with:${COLOR_RESET}"
    echo "  Version: $VERSION"
    echo "  Build System: $BUILD_SYSTEM"
    echo "  JAR: $JAR_FILE"
    if [ -f "$FAT_JAR_FILE" ]; then
        echo "  Fat JAR: $FAT_JAR_FILE"
    fi
    echo ""
    echo -e "${COLOR_YELLOW}To actually publish, run without --dry-run flag${COLOR_RESET}"
else
    echo -e "${COLOR_BLUE}Publishing to MuleSoft Exchange...${COLOR_RESET}"
    
    # Check if Anypoint CLI is installed
    if command -v anypoint-cli &> /dev/null || command -v anypoint &> /dev/null; then
        echo -e "${COLOR_BLUE}Using Anypoint CLI...${COLOR_RESET}"
        
        # Login to Anypoint Platform
        if command -v anypoint-cli &> /dev/null; then
            anypoint-cli login --username "$ANYPOINT_USERNAME" --password "$ANYPOINT_PASSWORD"
        else
            anypoint login --username "$ANYPOINT_USERNAME" --password "$ANYPOINT_PASSWORD"
        fi
        
        # Publish using Anypoint CLI
        if [ -n "$ANYPOINT_ORG_ID" ]; then
            ORG_FLAG="--org-id $ANYPOINT_ORG_ID"
        fi
        if [ -n "$ANYPOINT_ENV_ID" ]; then
            ENV_FLAG="--env-id $ANYPOINT_ENV_ID"
        fi
        
        if command -v anypoint-cli &> /dev/null; then
            anypoint-cli exchange publish "$JAR_FILE" $ORG_FLAG $ENV_FLAG
        else
            anypoint exchange publish "$JAR_FILE" $ORG_FLAG $ENV_FLAG
        fi
        
        echo -e "${COLOR_GREEN}✓ Published to MuleSoft Exchange${COLOR_RESET}"
    elif [ "$BUILD_SYSTEM" = "maven" ]; then
        # Use Maven Anypoint Exchange Plugin
        echo -e "${COLOR_BLUE}Using Maven Anypoint Exchange Plugin...${COLOR_RESET}"
        
        # Check if plugin is configured in pom.xml
        if grep -q "anypoint-exchange-maven-plugin" pom.xml; then
            mvn anypoint-exchange:deploy \
                -Danypoint.username="$ANYPOINT_USERNAME" \
                -Danypoint.password="$ANYPOINT_PASSWORD" \
                -Danypoint.orgId="$ANYPOINT_ORG_ID" \
                -Danypoint.envId="$ANYPOINT_ENV_ID"
            
            echo -e "${COLOR_GREEN}✓ Published to MuleSoft Exchange${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}⚠ Maven Anypoint Exchange Plugin not configured in pom.xml${COLOR_RESET}"
            echo -e "${COLOR_YELLOW}  Install Anypoint CLI or configure the Maven plugin${COLOR_RESET}"
            echo -e "${COLOR_YELLOW}  See MULESOFT_EXCHANGE.md for instructions${COLOR_RESET}"
            exit 1
        fi
    else
        echo -e "${COLOR_RED}Error: Anypoint CLI not found and not using Maven${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Install Anypoint CLI: https://docs.mulesoft.com/anypoint-platform-cli/${COLOR_RESET}"
        exit 1
    fi
fi

echo ""
echo -e "${COLOR_GREEN}${COLOR_BOLD}=== Publishing Complete ===${COLOR_RESET}"
echo -e "${COLOR_GREEN}Version $VERSION has been published to MuleSoft Exchange${COLOR_RESET}"

