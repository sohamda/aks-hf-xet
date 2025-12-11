#!/usr/bin/env bats
# BATS tests for Bash deployment script
# Install BATS: https://github.com/bats-core/bats-core
# Run with: bats tests/deploy.bats

# Setup function runs before each test
setup() {
    SCRIPT_PATH="${BATS_TEST_DIRNAME}/../scripts/deploy.sh"
}

@test "deploy.sh script file exists" {
    [ -f "$SCRIPT_PATH" ]
}

@test "deploy.sh script is readable" {
    [ -r "$SCRIPT_PATH" ]
}

@test "deploy.sh has bash shebang" {
    run head -n 1 "$SCRIPT_PATH"
    [[ "$output" == "#!/bin/bash" ]]
}

@test "deploy.sh has set -e for error handling" {
    run grep -q "set -e" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh defines IMAGE_NAME variable" {
    run grep -q 'IMAGE_NAME=' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh defines IMAGE_TAG variable" {
    run grep -q 'IMAGE_TAG=' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh defines SKIP_BUILD flag" {
    run grep -q 'SKIP_BUILD=' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh defines SKIP_MODEL_WAIT flag" {
    run grep -q 'SKIP_MODEL_WAIT=' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh has get_config_value function" {
    run grep -q 'get_config_value()' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh references AZURE_RESOURCE_GROUP" {
    run grep -q 'AZURE_RESOURCE_GROUP' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh references AKS_CLUSTER_NAME" {
    run grep -q 'AKS_CLUSTER_NAME' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh references ACR_NAME" {
    run grep -q 'ACR_NAME' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh references STORAGE_ACCOUNT_NAME" {
    run grep -q 'STORAGE_ACCOUNT_NAME' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh uses az CLI commands" {
    run grep -q '\baz\b' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh uses kubectl commands" {
    run grep -q '\bkubectl\b' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh uses docker commands" {
    run grep -q '\bdocker\b' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh parses --skip-build argument" {
    run grep -q '\-\-skip-build' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh parses --skip-model-wait argument" {
    run grep -q '\-\-skip-model-wait' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh validates required config values" {
    run grep -q 'if \[ -z' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh references k8s directory" {
    run grep -q 'K8S_DIR=' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh applies namespace.yaml" {
    run grep -q 'namespace.yaml' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh applies storage.yaml with substitution" {
    run grep -q 'storage.yaml' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh applies download-job.yaml" {
    run grep -q 'download-job.yaml' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "deploy.sh applies deployment.yaml with substitution" {
    run grep -q 'deployment.yaml' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}
