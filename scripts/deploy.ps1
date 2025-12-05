# Deploy Docling Model to AKS
# PowerShell deployment script

param(
    [string]$ImageName = "docling-api",
    [string]$ImageTag = "latest",
    [switch]$SkipBuild,
    [switch]$SkipModelWait
)

$ErrorActionPreference = "Stop"

# Helper function to get value from azd or environment
function Get-ConfigValue {
    param([string]$Name, [string]$Default = "")
    $value = [Environment]::GetEnvironmentVariable($Name)
    if (-not $value) { $value = azd env get-value $Name 2>$null }
    if (-not $value) { $value = $Default }
    return $value
}

Write-Host "=== Docling Model Deployment Script ===" -ForegroundColor Cyan

# Get all config values
$ResourceGroup = Get-ConfigValue "AZURE_RESOURCE_GROUP"
$ClusterName = Get-ConfigValue "AKS_CLUSTER_NAME"
$Namespace = Get-ConfigValue "KUBERNETES_NAMESPACE" "docling"
$StorageAccountName = Get-ConfigValue "STORAGE_ACCOUNT_NAME"
$StorageAccountKey = Get-ConfigValue "STORAGE_ACCOUNT_KEY"
$AcrName = Get-ConfigValue "ACR_NAME"
$AcrLoginServer = Get-ConfigValue "ACR_LOGIN_SERVER"

# Validate required values
if (-not $ResourceGroup -or -not $ClusterName -or -not $AcrName) {
    Write-Error "Missing required config. Run 'azd provision' first or set environment variables."
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$K8sDir = Join-Path $ScriptDir "..\k8s"
$SrcDir = Join-Path $ScriptDir "..\src"
$FullImageName = "${AcrLoginServer}/${ImageName}:${ImageTag}"

Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Yellow
Write-Host "AKS Cluster: $ClusterName" -ForegroundColor Yellow
Write-Host "Namespace: $Namespace" -ForegroundColor Yellow
Write-Host "ACR: $AcrLoginServer" -ForegroundColor Yellow
Write-Host "Image: $FullImageName" -ForegroundColor Yellow

# Build and push Docker image
if (-not $SkipBuild) {
    Write-Host "`n=== Building and Pushing Docker Image ===" -ForegroundColor Cyan
    
    az acr login --name $AcrName --resource-group $ResourceGroup
    if ($LASTEXITCODE -ne 0) { Write-Error "ACR login failed"; exit 1 }
    
    Push-Location $SrcDir
    docker build -t $FullImageName .
    if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Error "Docker build failed"; exit 1 }
    Pop-Location
    
    docker push $FullImageName
    if ($LASTEXITCODE -ne 0) { Write-Error "Docker push failed"; exit 1 }
    
    Write-Host "Image pushed: $FullImageName" -ForegroundColor Green
}

# Get AKS credentials
Write-Host "`nGetting AKS credentials..." -ForegroundColor Green
az aks get-credentials --resource-group $ResourceGroup --name $ClusterName --overwrite-existing

# Apply Kubernetes manifests
Write-Host "`nApplying Kubernetes manifests..." -ForegroundColor Green
kubectl apply -f (Join-Path $K8sDir "namespace.yaml")

# Apply storage with substituted values
(Get-Content (Join-Path $K8sDir "storage.yaml") -Raw) `
    -replace '\$\{STORAGE_ACCOUNT_NAME\}', $StorageAccountName `
    -replace '\$\{STORAGE_ACCOUNT_KEY\}', $StorageAccountKey | kubectl apply -f -

# Model download job
Write-Host "`nStarting model download job..." -ForegroundColor Green
kubectl delete job download-docling-model -n $Namespace --ignore-not-found=true
kubectl apply -f (Join-Path $K8sDir "download-job.yaml")

if (-not $SkipModelWait) {
    Write-Host "Waiting for model download..." -ForegroundColor Yellow
    $timeout = 600; $elapsed = 0
    while ($elapsed -lt $timeout) {
        Start-Sleep -Seconds 10; $elapsed += 10
        $status = kubectl get job download-docling-model -n $Namespace -o jsonpath='{.status.succeeded}' 2>$null
        if ($status -eq "1") { Write-Host "Model download completed!" -ForegroundColor Green; break }
        Write-Host "  Waiting... ($elapsed`s)" -ForegroundColor Gray
    }
}

# Apply deployment with image substitution
Write-Host "`nApplying Deployment..." -ForegroundColor Green
(Get-Content (Join-Path $K8sDir "deployment.yaml") -Raw) `
    -replace '<YOUR_REGISTRY>/docling-api:latest', $FullImageName | kubectl apply -f -

kubectl rollout status deployment/docling-model -n $Namespace --timeout=300s

# Summary
Write-Host "`n=== Deployment Complete ===" -ForegroundColor Cyan
kubectl get svc,pods -n $Namespace

$ip = kubectl get svc docling-model-service -n $Namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
if ($ip) { Write-Host "`nService URL: http://$ip" -ForegroundColor Green }
