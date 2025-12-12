# Pester tests for PowerShell deployment script
# Run with: pwsh -Command "Invoke-Pester -Path tests/deploy.Tests.ps1"

BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot "../scripts/deploy.ps1"
}

Describe "deploy.ps1 Script Validation" {
    Context "Script Structure" {
        It "Should exist" {
            Test-Path $scriptPath | Should -Be $true
        }

        It "Should be valid PowerShell" {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $scriptPath -Raw), [ref]$errors)
            $errors.Count | Should -Be 0
        }

        It "Should define required parameters" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'param\s*\('
            $content | Should -Match '\$ImageName'
            $content | Should -Match '\$ImageTag'
        }

        It "Should have error handling" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match '\$ErrorActionPreference'
        }
    }

    Context "Function Definitions" {
        It "Should define Get-ConfigValue function" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'function Get-ConfigValue'
        }

        It "Get-ConfigValue should accept Name parameter" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'param\(\[string\]\$Name'
        }
    }

    Context "Required Tools Validation" {
        It "Should reference az CLI" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match '\baz\b'
        }

        It "Should reference kubectl" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match '\bkubectl\b'
        }

        It "Should reference docker" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match '\bdocker\b'
        }
    }

    Context "Configuration Variables" {
        It "Should reference AZURE_RESOURCE_GROUP" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'AZURE_RESOURCE_GROUP'
        }

        It "Should reference AKS_CLUSTER_NAME" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'AKS_CLUSTER_NAME'
        }

        It "Should reference ACR_NAME" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'ACR_NAME'
        }

        It "Should reference STORAGE_ACCOUNT_NAME" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match 'STORAGE_ACCOUNT_NAME'
        }
    }

    Context "Switch Parameters" {
        It "Should support SkipBuild switch" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match '\[switch\]\$SkipBuild'
        }

        It "Should support SkipModelWait switch" {
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match '\[switch\]\$SkipModelWait'
        }
    }
}
