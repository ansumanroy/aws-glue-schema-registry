#!/bin/bash
# Script to scan Go dependencies for CVEs using govulncheck

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
GOLANG_DIR="$PROJECT_ROOT/golang"
REPORTS_DIR="$PROJECT_ROOT/reports"

# Create reports directory
mkdir -p "$REPORTS_DIR"

echo -e "${COLOR_BOLD}${COLOR_BLUE}=== Scanning Go Dependencies for CVEs ===${COLOR_RESET}"
echo ""

# Check if Go is available
if ! command -v go &> /dev/null; then
    echo -e "${COLOR_RED}Error: Go is not installed${COLOR_RESET}"
    exit 1
fi

# Check Go version (govulncheck requires Go 1.18+)
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
GO_MAJOR=$(echo "$GO_VERSION" | cut -d. -f1)
GO_MINOR=$(echo "$GO_VERSION" | cut -d. -f2)

if [ "$GO_MAJOR" -lt 1 ] || ([ "$GO_MAJOR" -eq 1 ] && [ "$GO_MINOR" -lt 18 ]); then
    echo -e "${COLOR_RED}Error: Go 1.18 or higher is required for govulncheck. Current version: $GO_VERSION${COLOR_RESET}"
    exit 1
fi

cd "$GOLANG_DIR"

# Check if govulncheck is installed
if ! command -v govulncheck &> /dev/null; then
    echo -e "${COLOR_BLUE}Installing govulncheck...${COLOR_RESET}"
    go install golang.org/x/vuln/cmd/govulncheck@latest || {
        echo -e "${COLOR_RED}Error: Failed to install govulncheck${COLOR_RESET}"
        exit 1
    }
    
    # Add GOPATH/bin to PATH if needed
    if [ -n "$GOPATH" ]; then
        export PATH="$GOPATH/bin:$PATH"
    elif [ -d "$HOME/go/bin" ]; then
        export PATH="$HOME/go/bin:$PATH"
    fi
fi

echo -e "${COLOR_BLUE}Scanning Go dependencies with govulncheck...${COLOR_RESET}"
echo -e "${COLOR_YELLOW}Note: First run will download vulnerability database${COLOR_RESET}"
echo ""

# Download dependencies first
echo -e "${COLOR_BLUE}Downloading dependencies...${COLOR_RESET}"
go mod download

# Run govulncheck
echo -e "${COLOR_BLUE}Running vulnerability scan...${COLOR_RESET}"
govulncheck ./... > "$REPORTS_DIR/golang-cves.txt" 2>&1 || {
    VULN_FOUND=$?
    if [ $VULN_FOUND -eq 0 ]; then
        echo -e "${COLOR_GREEN}✓ No vulnerabilities found${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}Warning: Vulnerabilities found. Check report for details.${COLOR_RESET}"
    fi
}

# Also create JSON output if possible (govulncheck doesn't support JSON directly, but we can parse)
echo -e "${COLOR_GREEN}✓ Go vulnerability scan complete. Report saved to: $REPORTS_DIR/golang-cves.txt${COLOR_RESET}"

echo ""
echo -e "${COLOR_GREEN}${COLOR_BOLD}=== Go CVE Scan Complete ===${COLOR_RESET}"
echo -e "${COLOR_BLUE}View report in: $REPORTS_DIR/golang-cves.txt${COLOR_RESET}"

