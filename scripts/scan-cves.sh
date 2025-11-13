#!/bin/bash
# Main script to scan all dependencies (Java, Python, Go) for CVEs

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
REPORTS_DIR="$PROJECT_ROOT/reports"

# Default values
SCAN_JAVA=true
SCAN_PYTHON=true
SCAN_GOLANG=true
SKIP_JAVA=false
SKIP_PYTHON=false
SKIP_GOLANG=false

# Function to print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Scan all project dependencies for CVEs.

OPTIONS:
    --java-only          Scan only Java dependencies
    --python-only        Scan only Python dependencies
    --golang-only        Scan only Go dependencies
    --skip-java          Skip Java scanning
    --skip-python        Skip Python scanning
    --skip-golang        Skip Go scanning
    -h, --help           Show this help message

EXAMPLES:
    # Scan all dependencies
    $0

    # Scan only Java dependencies
    $0 --java-only

    # Scan all except Go
    $0 --skip-golang

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --java-only)
            SCAN_JAVA=true
            SCAN_PYTHON=false
            SCAN_GOLANG=false
            shift
            ;;
        --python-only)
            SCAN_JAVA=false
            SCAN_PYTHON=true
            SCAN_GOLANG=false
            shift
            ;;
        --golang-only)
            SCAN_JAVA=false
            SCAN_PYTHON=false
            SCAN_GOLANG=true
            shift
            ;;
        --skip-java)
            SKIP_JAVA=true
            shift
            ;;
        --skip-python)
            SKIP_PYTHON=true
            shift
            ;;
        --skip-golang)
            SKIP_GOLANG=true
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

# Create reports directory
mkdir -p "$REPORTS_DIR"

echo -e "${COLOR_BOLD}${COLOR_BLUE}=== CVE Vulnerability Scan ===${COLOR_RESET}"
echo -e "${COLOR_BLUE}Project: ${COLOR_BOLD}$PROJECT_ROOT${COLOR_RESET}"
echo -e "${COLOR_BLUE}Reports: ${COLOR_BOLD}$REPORTS_DIR${COLOR_RESET}"
echo ""

# Change to project root
cd "$PROJECT_ROOT"

# Scan Java
if [ "$SCAN_JAVA" = true ] && [ "$SKIP_JAVA" = false ]; then
    echo -e "${COLOR_BOLD}${COLOR_BLUE}[1/3] Scanning Java Dependencies${COLOR_RESET}"
    bash "$SCRIPT_DIR/scan-java-cves.sh"
    echo ""
fi

# Scan Python
if [ "$SCAN_PYTHON" = true ] && [ "$SKIP_PYTHON" = false ]; then
    echo -e "${COLOR_BOLD}${COLOR_BLUE}[2/3] Scanning Python Dependencies${COLOR_RESET}"
    bash "$SCRIPT_DIR/scan-python-cves.sh"
    echo ""
fi

# Scan Go
if [ "$SCAN_GOLANG" = true ] && [ "$SKIP_GOLANG" = false ]; then
    echo -e "${COLOR_BOLD}${COLOR_BLUE}[3/3] Scanning Go Dependencies${COLOR_RESET}"
    bash "$SCRIPT_DIR/scan-golang-cves.sh"
    echo ""
fi

echo ""
echo -e "${COLOR_GREEN}${COLOR_BOLD}=== All CVE Scans Complete ===${COLOR_RESET}"
echo -e "${COLOR_BLUE}Reports are available in: ${COLOR_BOLD}$REPORTS_DIR${COLOR_RESET}"
echo ""
echo -e "${COLOR_YELLOW}Next steps:${COLOR_RESET}"
echo "  1. Review the reports in $REPORTS_DIR"
echo "  2. Update vulnerable dependencies to secure versions"
echo "  3. Re-run scans to verify fixes"
echo ""

