#!/bin/bash
# Script to scan Python dependencies for CVEs using pip-audit or safety

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
PYTHON_DIR="$PROJECT_ROOT/python"
REPORTS_DIR="$PROJECT_ROOT/reports"

# Create reports directory
mkdir -p "$REPORTS_DIR"

echo -e "${COLOR_BOLD}${COLOR_BLUE}=== Scanning Python Dependencies for CVEs ===${COLOR_RESET}"
echo ""

# Check if Python is available
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo -e "${COLOR_RED}Error: Python is not installed${COLOR_RESET}"
    exit 1
fi

PYTHON_CMD=$(command -v python3 2>/dev/null || command -v python 2>/dev/null)
cd "$PYTHON_DIR"

# Try pip-audit first (preferred)
if command -v pip-audit &> /dev/null; then
    echo -e "${COLOR_BLUE}Scanning with pip-audit...${COLOR_RESET}"
    echo ""
    
    pip-audit -r requirements.txt --format json --output "$REPORTS_DIR/python-cves.json" || {
        echo -e "${COLOR_YELLOW}Warning: pip-audit found vulnerabilities. Check report for details.${COLOR_RESET}"
    }
    
    # Also generate human-readable output
    pip-audit -r requirements.txt --format text --output "$REPORTS_DIR/python-cves.txt" || true
    
    echo -e "${COLOR_GREEN}✓ pip-audit scan complete. Reports saved to: $REPORTS_DIR/python-cves.{json,txt}${COLOR_RESET}"
    
# Try safety as fallback
elif command -v safety &> /dev/null; then
    echo -e "${COLOR_BLUE}Scanning with safety...${COLOR_RESET}"
    echo ""
    
    # Install safety if not available
    if ! $PYTHON_CMD -m safety --version &> /dev/null; then
        echo -e "${COLOR_YELLOW}Installing safety...${COLOR_RESET}"
        $PYTHON_CMD -m pip install --quiet safety
    fi
    
    $PYTHON_CMD -m safety check --json --file requirements.txt > "$REPORTS_DIR/python-cves.json" 2>&1 || {
        echo -e "${COLOR_YELLOW}Warning: safety found vulnerabilities. Check report for details.${COLOR_RESET}"
    }
    
    # Also generate human-readable output
    $PYTHON_CMD -m safety check --file requirements.txt > "$REPORTS_DIR/python-cves.txt" 2>&1 || true
    
    echo -e "${COLOR_GREEN}✓ safety scan complete. Reports saved to: $REPORTS_DIR/python-cves.{json,txt}${COLOR_RESET}"
    
# Install and use pip-audit
else
    echo -e "${COLOR_BLUE}Installing pip-audit...${COLOR_RESET}"
    $PYTHON_CMD -m pip install --quiet pip-audit
    
    echo -e "${COLOR_BLUE}Scanning with pip-audit...${COLOR_RESET}"
    echo ""
    
    pip-audit -r requirements.txt --format json --output "$REPORTS_DIR/python-cves.json" || {
        echo -e "${COLOR_YELLOW}Warning: pip-audit found vulnerabilities. Check report for details.${COLOR_RESET}"
    }
    
    # Also generate human-readable output
    pip-audit -r requirements.txt --format text --output "$REPORTS_DIR/python-cves.txt" || true
    
    echo -e "${COLOR_GREEN}✓ pip-audit scan complete. Reports saved to: $REPORTS_DIR/python-cves.{json,txt}${COLOR_RESET}"
fi

echo ""
echo -e "${COLOR_GREEN}${COLOR_BOLD}=== Python CVE Scan Complete ===${COLOR_RESET}"
echo -e "${COLOR_BLUE}View reports in: $REPORTS_DIR/python-cves.{json,txt}${COLOR_RESET}"

