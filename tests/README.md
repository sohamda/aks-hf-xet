# Infrastructure Tests and Linting

This directory contains tests and linting configurations for the infrastructure scripts in this repository.

## Why These Tests?

This project deploys a Hugging Face model to Azure Kubernetes Service (AKS) using Infrastructure-as-Code (Bicep) and deployment scripts (Bash/PowerShell). The tests ensure:

1. **Deployment scripts are syntactically correct** - Catch errors before running in production
2. **Scripts follow best practices** - Consistent error handling, proper variable definitions
3. **Infrastructure templates are valid** - Bicep templates compile and have required resources
4. **Cross-platform compatibility** - Both Bash and PowerShell scripts work correctly

## Test Summary

| Test File | Framework | Purpose |
|-----------|-----------|---------|
| `deploy.bats` | BATS | Validates bash deployment script structure and syntax |
| `bicep.bats` | BATS | Validates Bicep templates compile and have required resources |
| `deploy.Tests.ps1` | Pester | Validates PowerShell deployment script structure and syntax |

## Overview

We use multiple tools to ensure code quality and correctness:

- **ShellCheck**: Linter for bash scripts
- **PSScriptAnalyzer**: Linter for PowerShell scripts
- **Bicep Linter**: Built-in linter for Azure Bicep templates
- **BATS**: Testing framework for bash scripts and Bicep validation
- **Pester**: Testing framework for PowerShell scripts

## What Each Test File Validates

### `deploy.bats` - Bash Deployment Script Tests

Tests the `scripts/deploy.sh` script to ensure:

| Test | Why It Matters |
|------|----------------|
| Script file exists and is readable | Basic sanity check |
| Has bash shebang (`#!/bin/bash`) | Ensures correct interpreter |
| Has `set -e` for error handling | Script exits on first error, preventing partial deployments |
| Defines required variables (`IMAGE_NAME`, `IMAGE_TAG`, etc.) | Configuration is properly structured |
| Has `get_config_value` function | Reads Azure deployment outputs correctly |
| References required Azure resources | Ensures script interacts with all infrastructure components |
| Uses `az`, `kubectl`, `docker` commands | Validates required tooling is invoked |
| Parses `--skip-build` and `--skip-model-wait` flags | Command-line options work correctly |

### `bicep.bats` - Infrastructure Template Tests

Tests the `infra/*.bicep` files to ensure:

| Test | Why It Matters |
|------|----------------|
| `main.bicep` exists and has valid syntax | Template compiles without errors |
| Has `environmentName` and `location` parameters | Required inputs for deployment |
| Defines resource group | Base Azure resource exists |
| Includes all required modules (storage, aks, acr, roles) | All infrastructure components are defined |
| Outputs required values (`AKS_CLUSTER_NAME`, `ACR_NAME`, etc.) | Deployment scripts can read infrastructure outputs |
| Each module file exists and has valid syntax | No broken module references |

### `deploy.Tests.ps1` - PowerShell Deployment Script Tests

Tests the `scripts/deploy.ps1` script to ensure:

| Test | Why It Matters |
|------|----------------|
| Script exists and is valid PowerShell | Parses without syntax errors |
| Defines required parameters (`$ImageName`, `$ImageTag`) | Script accepts necessary inputs |
| Has `$ErrorActionPreference` set | Proper error handling configured |
| Defines `Get-ConfigValue` function | Reads Azure deployment outputs correctly |
| References `az`, `kubectl`, `docker` | Validates required tooling is invoked |
| References required Azure resource variables | Ensures script interacts with all infrastructure |
| Supports `SkipBuild` and `SkipModelWait` switches | Command-line options work correctly |

## Running Tests Locally

### Prerequisites

1. **ShellCheck** (for bash linting)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install shellcheck
   
   # macOS
   brew install shellcheck
   ```

2. **Azure CLI with Bicep** (for bicep linting and validation)
   ```bash
   # Install Azure CLI
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Install Bicep
   az bicep install
   ```

3. **PowerShell** (for PowerShell linting and tests)
   ```bash
   # Ubuntu/Debian
   sudo snap install powershell --classic
   
   # macOS
   brew install powershell
   ```

4. **PSScriptAnalyzer** (PowerShell linting module)
   ```powershell
   Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
   ```

5. **BATS** (Bash testing framework)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install bats
   
   # macOS
   brew install bats-core
   
   # Or install manually
   git clone https://github.com/bats-core/bats-core.git
   cd bats-core
   sudo ./install.sh /usr/local
   ```

6. **Pester** (PowerShell testing module)
   ```powershell
   Install-Module -Name Pester -Force -Scope CurrentUser -MinimumVersion 5.0.0
   ```

### Running Linters

#### Bash Scripts
```bash
# Run ShellCheck on deploy.sh
shellcheck scripts/deploy.sh

# Run with specific configuration
shellcheck --shell=bash scripts/deploy.sh
```

#### PowerShell Scripts
```powershell
# Run PSScriptAnalyzer on deploy.ps1
pwsh -Command "Invoke-ScriptAnalyzer -Path scripts/deploy.ps1"

# Show only errors
pwsh -Command "Invoke-ScriptAnalyzer -Path scripts/deploy.ps1 -Severity Error"
```

#### Bicep Templates
```bash
# Lint main template
az bicep lint --file infra/main.bicep

# Lint all module files
for file in infra/modules/*.bicep; do
  echo "Linting $file"
  az bicep lint --file "$file"
done
```

### Running Tests

#### BATS Tests (Bash and Bicep Validation)
```bash
# Run all BATS tests
bats tests/*.bats

# Run specific test file
bats tests/deploy.bats
bats tests/bicep.bats
```

#### Pester Tests (PowerShell)
```powershell
# Run Pester tests
pwsh -Command "Invoke-Pester -Path tests/deploy.Tests.ps1"

# Run with detailed output
pwsh -Command "Invoke-Pester -Path tests/deploy.Tests.ps1 -Output Detailed"
```

### Run All Tests and Linters
```bash
# Make the script executable
chmod +x tests/run-all-tests.sh

# Run all tests and linters
./tests/run-all-tests.sh
```

## Test Files

| File | Description |
|------|-------------|
| `deploy.bats` | BATS tests validating bash deployment script has correct structure, error handling, required variables, and CLI tool usage |
| `bicep.bats` | BATS tests validating Bicep templates compile successfully, include all required modules, and output necessary deployment values |
| `deploy.Tests.ps1` | Pester tests validating PowerShell deployment script has correct parameters, functions, and error handling |
| `run-all-tests.sh` | Convenience script to run all linters and tests locally |
| `run-pester.ps1` | Helper script to run Pester tests |
| `run-psscriptanalyzer.ps1` | Helper script to run PowerShell linting |

## Configuration Files

- `.shellcheckrc` - ShellCheck configuration (repository root)
- `.github/workflows/lint-test.yml` - CI/CD workflow for automated testing

## Continuous Integration

All tests and linters run automatically via GitHub Actions (`.github/workflows/lint-test.yml`):

### Triggers
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- When files in `scripts/`, `infra/`, or `tests/` directories change

### CI Jobs

| Job | Tools | What It Checks |
|-----|-------|----------------|
| **shellcheck** | ShellCheck | Bash script syntax, quoting, common pitfalls |
| **bicep-lint** | Azure CLI + Bicep | Infrastructure template best practices |
| **powershell-lint** | PSScriptAnalyzer | PowerShell script best practices |
| **bats-tests** | BATS | Bash script and Bicep template validation tests |
| **pester-tests** | Pester | PowerShell script validation tests |

View the workflow results in the "Actions" tab of the GitHub repository.

## Writing New Tests

### Adding BATS Tests
```bash
@test "description of test" {
    run command_to_test
    [ "$status" -eq 0 ]
}
```

### Adding Pester Tests
```powershell
Describe "Feature Name" {
    Context "Scenario" {
        It "Should do something" {
            $result = Test-Something
            $result | Should -Be $expected
        }
    }
}
```

## Troubleshooting

### BATS not found
Make sure BATS is installed and in your PATH. You can verify with:
```bash
which bats
bats --version
```

### Pester tests fail to import
Ensure you have Pester 5.0.0 or higher:
```powershell
Get-Module -ListAvailable Pester
```

### Bicep CLI not found
Install or update Bicep:
```bash
az bicep install
az bicep upgrade
```

## Contributing

When adding new infrastructure scripts:
1. Add corresponding tests to the `tests/` directory
2. Ensure all linters pass
3. Update this README if new tools or test types are introduced
4. Run `./tests/run-all-tests.sh` before submitting PR
