#!/bin/bash
# Run all infrastructure tests and linters locally
# Usage: ./tests/run-all-tests.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Infrastructure Tests and Linting"
echo "=========================================="
echo ""

cd "$REPO_ROOT"

# Track failures
FAILURES=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

run_check() {
    local name="$1"
    local cmd="$2"
    
    echo -e "${YELLOW}Running: $name${NC}"
    if eval "$cmd"; then
        echo -e "${GREEN}✓ PASSED: $name${NC}"
        echo ""
    else
        echo -e "${RED}✗ FAILED: $name${NC}"
        echo ""
        FAILURES=$((FAILURES + 1))
    fi
}

# 1. ShellCheck - Bash Scripts
if command -v shellcheck &> /dev/null; then
    run_check "ShellCheck (Bash)" "shellcheck scripts/deploy.sh"
else
    echo -e "${YELLOW}⚠ SKIPPED: ShellCheck not installed${NC}"
    echo ""
fi

# 2. Bicep Linter
if command -v az &> /dev/null; then
    run_check "Bicep Lint (main.bicep)" "az bicep lint --file infra/main.bicep"
    
    for bicep_file in infra/modules/*.bicep; do
        filename=$(basename "$bicep_file")
        run_check "Bicep Lint ($filename)" "az bicep lint --file '$bicep_file'"
    done
else
    echo -e "${YELLOW}⚠ SKIPPED: Azure CLI not installed${NC}"
    echo ""
fi

# 3. PSScriptAnalyzer - PowerShell Scripts
if command -v pwsh &> /dev/null; then
    if pwsh -Command "Get-Module -ListAvailable PSScriptAnalyzer" &> /dev/null; then
        run_check "PSScriptAnalyzer (PowerShell)" \
            "pwsh -File tests/run-psscriptanalyzer.ps1"
    else
        echo -e "${YELLOW}⚠ SKIPPED: PSScriptAnalyzer module not installed${NC}"
        echo "  Install with: pwsh -Command \"Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser\""
        echo ""
    fi
else
    echo -e "${YELLOW}⚠ SKIPPED: PowerShell not installed${NC}"
    echo ""
fi

# 4. BATS Tests
if command -v bats &> /dev/null; then
    run_check "BATS Tests (deploy.bats)" "bats tests/deploy.bats"
    run_check "BATS Tests (bicep.bats)" "bats tests/bicep.bats"
else
    echo -e "${YELLOW}⚠ SKIPPED: BATS not installed${NC}"
    echo "  Install from: https://github.com/bats-core/bats-core"
    echo ""
fi

# 5. Pester Tests
if command -v pwsh &> /dev/null; then
    if pwsh -Command "Get-Module -ListAvailable Pester" &> /dev/null; then
        run_check "Pester Tests (PowerShell)" \
            "pwsh -File tests/run-pester.ps1"
    else
        echo -e "${YELLOW}⚠ SKIPPED: Pester module not installed${NC}"
        echo "  Install with: pwsh -Command \"Install-Module -Name Pester -Force -Scope CurrentUser -MinimumVersion 5.0.0\""
        echo ""
    fi
fi

# Summary
echo "=========================================="
if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}$FAILURES test(s) failed${NC}"
    exit 1
fi
