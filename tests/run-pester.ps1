# Helper script for running Pester tests from bash
# This is called by run-all-tests.sh

Import-Module Pester
$config = New-PesterConfiguration
$config.Run.Path = 'tests/deploy.Tests.ps1'
$config.Run.Exit = $true
$config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $config
