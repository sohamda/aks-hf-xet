#!/bin/bash
set -e

# Deploy Docling Model to AKS
# Bash deployment script

IMAGE_NAME="docling-api"
IMAGE_TAG="latest"
SKIP_BUILD=false
SKIP_MODEL_WAIT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build) SKIP_BUILD=true; shift ;;
        --skip-model-wait) SKIP_MODEL_WAIT=true; shift ;;
        *) shift ;;
    esac
done

# Helper function to get value from azd or environment
get_config_value() {
    local name=$1
    local default=$2
    local value="${!name}"
    if [ -z "$value" ]; then
        value=$(azd env get-value "$name" 2>/dev/null || echo "")
    fi
    if [ -z "$value" ]; then
        value="$default"
    fi
    echo "$value"
}

echo "=== Docling Model Deployment Script ==="

# Get all config values
RESOURCE_GROUP=$(get_config_value "AZURE_RESOURCE_GROUP")
CLUSTER_NAME=$(get_config_value "AKS_CLUSTER_NAME")
NAMESPACE=$(get_config_value "KUBERNETES_NAMESPACE" "docling")
STORAGE_ACCOUNT_NAME=$(get_config_value "STORAGE_ACCOUNT_NAME")
STORAGE_ACCOUNT_KEY=$(get_config_value "STORAGE_ACCOUNT_KEY")
ACR_NAME=$(get_config_value "ACR_NAME")
ACR_LOGIN_SERVER=$(get_config_value "ACR_LOGIN_SERVER")

# Validate required values
if [ -z "$RESOURCE_GROUP" ] || [ -z "$CLUSTER_NAME" ] || [ -z "$ACR_NAME" ]; then
    echo "Error: Missing required config. Run 'azd provision' first or set environment variables."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$SCRIPT_DIR/../k8s"
SRC_DIR="$SCRIPT_DIR/../src"
FULL_IMAGE_NAME="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "Resource Group: $RESOURCE_GROUP"
echo "AKS Cluster: $CLUSTER_NAME"
echo "Namespace: $NAMESPACE"
echo "ACR: $ACR_LOGIN_SERVER"
echo "Image: $FULL_IMAGE_NAME"

# Build and push Docker image
if [ "$SKIP_BUILD" = false ]; then
    echo ""
    echo "=== Building and Pushing Docker Image ==="
    
    az acr login --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" || {
        echo "ACR login failed"; exit 1
    }
    
    cd "$SRC_DIR"
    docker build -t "$FULL_IMAGE_NAME" . || {
        echo "Docker build failed"; exit 1
    }
    cd -
    
    docker push "$FULL_IMAGE_NAME" || {
        echo "Docker push failed"; exit 1
    }
    
    echo "Image pushed: $FULL_IMAGE_NAME"
fi

# Get AKS credentials
echo ""
echo "Getting AKS credentials..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing

# Apply Kubernetes manifests
echo ""
echo "Applying Kubernetes manifests..."
kubectl apply -f "$K8S_DIR/namespace.yaml"

# Apply storage with substituted values
sed -e "s/\${STORAGE_ACCOUNT_NAME}/$STORAGE_ACCOUNT_NAME/g" \
    -e "s/\${STORAGE_ACCOUNT_KEY}/$STORAGE_ACCOUNT_KEY/g" \
    "$K8S_DIR/storage.yaml" | kubectl apply -f -

# Model download job
echo ""
echo "Starting model download job..."
kubectl delete job download-docling-model -n "$NAMESPACE" --ignore-not-found=true
kubectl apply -f "$K8S_DIR/download-job.yaml"

if [ "$SKIP_MODEL_WAIT" = false ]; then
    echo "Waiting for model download..."
    timeout=600
    elapsed=0
    while [ $elapsed -lt $timeout ]; do
        sleep 10
        elapsed=$((elapsed + 10))
        status=$(kubectl get job download-docling-model -n "$NAMESPACE" -o jsonpath='{.status.succeeded}' 2>/dev/null || echo "")
        if [ "$status" = "1" ]; then
            echo "Model download completed!"
            break
        fi
        echo "  Waiting... (${elapsed}s)"
    done
fi

# Apply deployment with image substitution
echo ""
echo "Applying Deployment..."
sed "s|<YOUR_REGISTRY>/docling-api:latest|$FULL_IMAGE_NAME|g" \
    "$K8S_DIR/deployment.yaml" | kubectl apply -f -

kubectl rollout status deployment/docling-model -n "$NAMESPACE" --timeout=300s

# Summary
echo ""
echo "=== Deployment Complete ==="
kubectl get svc,pods -n "$NAMESPACE"

ip=$(kubectl get svc docling-model-service -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
if [ -n "$ip" ]; then
    echo ""
    echo "Service URL: http://$ip"
fi
