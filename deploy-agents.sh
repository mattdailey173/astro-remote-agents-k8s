#!/bin/bash

set -e

# Astronomer Remote Execution Agent Deployment Script

# Configuration
NAMESPACE="astronomer-remote-agents"
CHART_NAME="astro-agent"
REGISTRY="your-registry.com"
IMAGE_NAME="astro-remote-agent"
IMAGE_TAG="latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Astronomer Remote Execution Agent Deployment${NC}"
echo "=================================================="

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed${NC}"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ Helm is not installed${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites met${NC}"

# Verify Kubernetes connection
echo -e "${YELLOW}Verifying Kubernetes connection...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Kubernetes cluster accessible${NC}"

# Check required environment variables
if [ -z "$ASTRO_AGENT_TOKEN" ]; then
    echo -e "${RED}❌ ASTRO_AGENT_TOKEN environment variable is required${NC}"
    echo "Generate token from Astro UI: Deployment > Remote Agents > Add Agent"
    exit 1
fi

# Build custom agent image
echo -e "${YELLOW}Building custom agent image...${NC}"
docker build -f Dockerfile.remote-agent -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .

# Push image to registry
echo -e "${YELLOW}Pushing image to registry...${NC}"
docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

# Create namespace
echo -e "${YELLOW}Creating namespace...${NC}"
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Create image pull secret (if registry requires auth)
if [ -n "$REGISTRY_USERNAME" ] && [ -n "$REGISTRY_PASSWORD" ]; then
    echo -e "${YELLOW}Creating image pull secret...${NC}"
    kubectl create secret docker-registry astro-registry-secret \
        --docker-server=${REGISTRY} \
        --docker-username=${REGISTRY_USERNAME} \
        --docker-password=${REGISTRY_PASSWORD} \
        --namespace=${NAMESPACE} \
        --dry-run=client -o yaml | kubectl apply -f -
fi

# Add Astronomer Helm repository
echo -e "${YELLOW}Adding Astronomer Helm repository...${NC}"
helm repo add astronomer https://helm.astronomer.io
helm repo update

# Update values.yaml with environment-specific settings
echo -e "${YELLOW}Updating configuration...${NC}"
cat > /tmp/agent-values.yaml << EOF
resourceNamePrefix: "${CHART_NAME}"
namespace: "${NAMESPACE}"
agentToken: "${ASTRO_AGENT_TOKEN}"

image:
  repository: "${REGISTRY}/${IMAGE_NAME}"
  tag: "${IMAGE_TAG}"
  pullPolicy: "Always"

imagePullSecretName: "astro-registry-secret"

secretBackend:
  type: "k8s"
  k8s:
    secretName: "astro-secrets"
    namespace: "${NAMESPACE}"

xcomBackend:
  type: "k8s"

agents:
  worker:
    enabled: true
    replicas: ${WORKER_REPLICAS:-3}
    resources:
      requests:
        cpu: "500m"
        memory: "1Gi"
      limits:
        cpu: "2"
        memory: "4Gi"

  triggerer:
    enabled: true
    replicas: ${TRIGGERER_REPLICAS:-2}
    resources:
      requests:
        cpu: "250m"
        memory: "512Mi"
      limits:
        cpu: "1"
        memory: "2Gi"

monitoring:
  enabled: true

logging:
  level: "${LOG_LEVEL:-INFO}"
EOF

# Deploy or upgrade the agent
if helm list -n ${NAMESPACE} | grep -q ${CHART_NAME}; then
    echo -e "${YELLOW}Upgrading existing agent deployment...${NC}"
    helm upgrade ${CHART_NAME} astronomer/astro-remote-execution-agent \
        --namespace ${NAMESPACE} \
        -f /tmp/agent-values.yaml \
        --wait
else
    echo -e "${YELLOW}Installing new agent deployment...${NC}"
    helm install ${CHART_NAME} astronomer/astro-remote-execution-agent \
        --namespace ${NAMESPACE} \
        -f /tmp/agent-values.yaml \
        --wait
fi

# Verify deployment
echo -e "${YELLOW}Verifying deployment...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment -l app.kubernetes.io/instance=${CHART_NAME} -n ${NAMESPACE}

# Display deployment status
echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo ""
echo "Deployment Status:"
kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/instance=${CHART_NAME}

echo ""
echo "Agent Services:"
kubectl get svc -n ${NAMESPACE} -l app.kubernetes.io/instance=${CHART_NAME}

# Clean up temporary files
rm -f /tmp/agent-values.yaml

echo -e "${GREEN}🎉 Remote Execution Agents are ready!${NC}"