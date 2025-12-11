# Helper script for running PSScriptAnalyzer from bash
# This is called by run-all-tests.sh

$results = Invoke-ScriptAnalyzer -Path scripts/deploy.ps1 -Severity Error
if ($results.Count -gt 0) {
    $results | Format-Table -AutoSize
    exit 1
}
Write-Host "No errors found"
exit 0
