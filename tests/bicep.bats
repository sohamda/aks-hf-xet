#!/usr/bin/env bats
# BATS tests for Bicep infrastructure templates
# Run with: bats tests/bicep.bats

setup() {
    INFRA_DIR="${BATS_TEST_DIRNAME}/../infra"
    MAIN_BICEP="${INFRA_DIR}/main.bicep"
    MODULES_DIR="${INFRA_DIR}/modules"
}

@test "main.bicep file exists" {
    [ -f "$MAIN_BICEP" ]
}

@test "main.bicep is valid bicep syntax" {
    run az bicep build --file "$MAIN_BICEP" --stdout
    [ "$status" -eq 0 ]
}

@test "main.bicep has required parameters" {
    run grep -q 'param environmentName' "$MAIN_BICEP"
    [ "$status" -eq 0 ]
}

@test "main.bicep has location parameter" {
    run grep -q 'param location' "$MAIN_BICEP"
    [ "$status" -eq 0 ]
}

@test "main.bicep defines resource group" {
    run grep -q "resource rg 'Microsoft.Resources/resourceGroups" "$MAIN_BICEP"
    [ "$status" -eq 0 ]
}

@test "main.bicep includes storage module" {
    run grep -q "module storage './modules/storage.bicep'" "$MAIN_BICEP"
    [ "$status" -eq 0 ]
}

@test "main.bicep includes aks module" {
    run grep -q "module aks './modules/aks.bicep'" "$MAIN_BICEP"
    [ "$status" -eq 0 ]
}

@test "main.bicep includes acr module" {
    run grep -q "module acr './modules/acr.bicep'" "$MAIN_BICEP"
    [ "$status" -eq 0 ]
}

@test "main.bicep includes aks-acr-role module" {
    run grep -q "module aksAcrRoleAssignment './modules/aks-acr-role.bicep'" "$MAIN_BICEP"
    [ "$status" -eq 0 ]
}

@test "main.bicep includes aks-storage-role module" {
    run grep -q "module aksStorageRoleAssignment './modules/aks-storage-role.bicep'" "$MAIN_BICEP"
    [ "$status" -eq 0 ]
}

@test "main.bicep outputs AKS_CLUSTER_NAME" {
    run grep -q 'output AKS_CLUSTER_NAME' "$MAIN_BICEP"
    [ "$status" -eq 0 ]
}

@test "main.bicep outputs STORAGE_ACCOUNT_NAME" {
    run grep -q 'output STORAGE_ACCOUNT_NAME' "$MAIN_BICEP"
    [ "$status" -eq 0 ]
}

@test "main.bicep outputs ACR_NAME" {
    run grep -q 'output ACR_NAME' "$MAIN_BICEP"
    [ "$status" -eq 0 ]
}

@test "main.bicep outputs ACR_LOGIN_SERVER" {
    run grep -q 'output ACR_LOGIN_SERVER' "$MAIN_BICEP"
    [ "$status" -eq 0 ]
}

@test "aks.bicep module exists" {
    [ -f "${MODULES_DIR}/aks.bicep" ]
}

@test "aks.bicep is valid bicep syntax" {
    run az bicep build --file "${MODULES_DIR}/aks.bicep" --stdout
    [ "$status" -eq 0 ]
}

@test "acr.bicep module exists" {
    [ -f "${MODULES_DIR}/acr.bicep" ]
}

@test "acr.bicep is valid bicep syntax" {
    run az bicep build --file "${MODULES_DIR}/acr.bicep" --stdout
    [ "$status" -eq 0 ]
}

@test "storage.bicep module exists" {
    [ -f "${MODULES_DIR}/storage.bicep" ]
}

@test "storage.bicep is valid bicep syntax" {
    run az bicep build --file "${MODULES_DIR}/storage.bicep" --stdout
    [ "$status" -eq 0 ]
}

@test "aks-acr-role.bicep module exists" {
    [ -f "${MODULES_DIR}/aks-acr-role.bicep" ]
}

@test "aks-acr-role.bicep is valid bicep syntax" {
    run az bicep build --file "${MODULES_DIR}/aks-acr-role.bicep" --stdout
    [ "$status" -eq 0 ]
}

@test "aks-storage-role.bicep module exists" {
    [ -f "${MODULES_DIR}/aks-storage-role.bicep" ]
}

@test "aks-storage-role.bicep is valid bicep syntax" {
    run az bicep build --file "${MODULES_DIR}/aks-storage-role.bicep" --stdout
    [ "$status" -eq 0 ]
}

@test "storage.bicep creates file share" {
    run grep -q "resource share 'shares'" "${MODULES_DIR}/storage.bicep"
    [ "$status" -eq 0 ]
}

@test "aks.bicep enables OIDC issuer" {
    run grep -q 'oidcIssuerProfile' "${MODULES_DIR}/aks.bicep"
    [ "$status" -eq 0 ]
}

@test "aks.bicep enables workload identity" {
    run grep -q 'securityProfile' "${MODULES_DIR}/aks.bicep"
    [ "$status" -eq 0 ]
}

@test "aks-storage-role.bicep assigns Storage Account Contributor role" {
    run grep -q '17d1049b-9a84-46fb-8f53-869881c3d3ab' "${MODULES_DIR}/aks-storage-role.bicep"
    [ "$status" -eq 0 ]
}

@test "aks-storage-role.bicep assigns Storage File Data SMB Share Contributor role" {
    run grep -q '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb' "${MODULES_DIR}/aks-storage-role.bicep"
    [ "$status" -eq 0 ]
}

@test "aks-acr-role.bicep assigns AcrPull role" {
    run grep -q '7f951dda-4ed3-4680-a7ca-43fe172d538d' "${MODULES_DIR}/aks-acr-role.bicep"
    [ "$status" -eq 0 ]
}
