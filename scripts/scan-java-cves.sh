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
    
    # Run dependency check
    ./gradlew dependencyCheckAnalyze --no-daemon || {
        echo -e "${COLOR_YELLOW}Warning: Dependency check completed with issues. Check reports for details.${COLOR_RESET}"
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
        
        # Run dependency check
        mvn dependency-check:check || {
            echo -e "${COLOR_YELLOW}Warning: Dependency check completed with issues. Check reports for details.${COLOR_RESET}"
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

