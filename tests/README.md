# Infrastructure Tests and Linting

This directory contains tests and linting configurations for the infrastructure scripts in this repository.

## Overview

We use multiple tools to ensure code quality and correctness:

- **ShellCheck**: Linter for bash scripts
- **PSScriptAnalyzer**: Linter for PowerShell scripts
- **Bicep Linter**: Built-in linter for Azure Bicep templates
- **BATS**: Testing framework for bash scripts and Bicep validation
- **Pester**: Testing framework for PowerShell scripts

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

- `deploy.bats` - BATS tests for bash deployment script
- `bicep.bats` - BATS tests for Bicep template validation
- `deploy.Tests.ps1` - Pester tests for PowerShell deployment script

## Configuration Files

- `.shellcheckrc` - ShellCheck configuration (repository root)
- `.github/workflows/lint-test.yml` - CI/CD workflow for automated testing

## Continuous Integration

All tests and linters run automatically on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- When files in `scripts/`, `infra/`, or `tests/` directories change

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
