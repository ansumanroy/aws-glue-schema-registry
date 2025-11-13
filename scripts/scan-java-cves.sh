#!/bin/bash
# Script to scan Java dependencies for CVEs using OWASP Dependency-Check

set -e

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
REPORTS_DIR="$PROJECT_ROOT/reports"

# Create reports directory
mkdir -p "$REPORTS_DIR"

echo -e "${COLOR_BOLD}${COLOR_BLUE}=== Scanning Java Dependencies for CVEs ===${COLOR_RESET}"
echo ""

# Check for NVD API Key
if [ -z "$NVD_API_KEY" ]; then
    echo -e "${COLOR_YELLOW}Warning: NVD_API_KEY environment variable is not set.${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}The NVD API now requires an API key for access.${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Without an API key, the scan may fail or take a very long time.${COLOR_RESET}"
    echo -e "${COLOR_BLUE}To get an API key:${COLOR_RESET}"
    echo -e "${COLOR_BLUE}  1. Visit: https://nvd.nist.gov/developers/request-an-api-key${COLOR_RESET}"
    echo -e "${COLOR_BLUE}  2. Request a free API key${COLOR_RESET}"
    echo -e "${COLOR_BLUE}  3. Set it: export NVD_API_KEY=your-key-here${COLOR_RESET}"
    echo ""
    read -p "Continue without API key? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${COLOR_YELLOW}Scan cancelled. Please set NVD_API_KEY and try again.${COLOR_RESET}"
        exit 0
    fi
    echo ""
else
    echo -e "${COLOR_GREEN}✓ NVD API Key found${COLOR_RESET}"
    echo ""
fi

# Check if Java is available
if ! command -v java &> /dev/null; then
    echo -e "${COLOR_RED}Error: Java is not installed${COLOR_RESET}"
    exit 1
fi

cd "$JAVA_DIR"

# Try Gradle first
if [ -f "gradlew" ]; then
    echo -e "${COLOR_BLUE}Scanning with Gradle (OWASP Dependency-Check)...${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Note: First run will download the NVD database (this may take several minutes)${COLOR_RESET}"
    echo ""
    
    if [ -z "$JAVA_HOME" ]; then
        JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || echo "")
    fi
    
    if [ -n "$JAVA_HOME" ]; then
        export JAVA_HOME
    fi
    
    # Run dependency check (export NVD_API_KEY if set)
    if [ -n "$NVD_API_KEY" ]; then
        export NVD_API_KEY
    fi
    ./gradlew dependencyCheckAnalyze --no-daemon || {
        EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]; then
            echo -e "${COLOR_YELLOW}Warning: Dependency check completed with issues (exit code: $EXIT_CODE)${COLOR_RESET}"
            if [ -z "$NVD_API_KEY" ]; then
                echo -e "${COLOR_YELLOW}This may be due to missing NVD API key. Consider setting NVD_API_KEY environment variable.${COLOR_RESET}"
            fi
            echo -e "${COLOR_YELLOW}Check reports for details.${COLOR_RESET}"
        fi
    }
    
    # Copy reports
    if [ -d "build/reports/dependency-check" ]; then
        cp -r build/reports/dependency-check "$REPORTS_DIR/java-cves" 2>/dev/null || true
        echo -e "${COLOR_GREEN}✓ Gradle scan complete. Reports saved to: $REPORTS_DIR/java-cves${COLOR_RESET}"
    fi
fi

# Try Maven
if [ -f "pom.xml" ]; then
    if command -v mvn &> /dev/null; then
        echo -e "${COLOR_BLUE}Scanning with Maven (OWASP Dependency-Check)...${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}Note: First run will download the NVD database (this may take several minutes)${COLOR_RESET}"
        echo ""
        
        if [ -z "$JAVA_HOME" ]; then
            JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || echo "")
        fi
        
        if [ -n "$JAVA_HOME" ]; then
            export JAVA_HOME
        fi
        
        # Run dependency check (export NVD_API_KEY if set)
        if [ -n "$NVD_API_KEY" ]; then
            export NVD_API_KEY
        fi
        mvn dependency-check:check || {
            EXIT_CODE=$?
            if [ $EXIT_CODE -ne 0 ]; then
                echo -e "${COLOR_YELLOW}Warning: Dependency check completed with issues (exit code: $EXIT_CODE)${COLOR_RESET}"
                if [ -z "$NVD_API_KEY" ]; then
                    echo -e "${COLOR_YELLOW}This may be due to missing NVD API key. Consider setting NVD_API_KEY environment variable.${COLOR_RESET}"
                fi
                echo -e "${COLOR_YELLOW}Check reports for details.${COLOR_RESET}"
            fi
        }
        
        # Copy reports
        if [ -d "target/reports/dependency-check" ]; then
            cp -r target/reports/dependency-check "$REPORTS_DIR/java-cves-maven" 2>/dev/null || true
            echo -e "${COLOR_GREEN}✓ Maven scan complete. Reports saved to: $REPORTS_DIR/java-cves-maven${COLOR_RESET}"
        fi
    else
        echo -e "${COLOR_YELLOW}Maven not found. Skipping Maven scan.${COLOR_RESET}"
    fi
fi

echo ""
echo -e "${COLOR_GREEN}${COLOR_BOLD}=== Java CVE Scan Complete ===${COLOR_RESET}"
echo -e "${COLOR_BLUE}View reports in: $REPORTS_DIR/java-cves${COLOR_RESET}"

