# Astronomer Remote Execution Agents Deployment Guide

This project sets up Astronomer Remote Execution Agents with Kubernetes 1.30+ and Helm 3+ support.

## Prerequisites

- Kubernetes 1.30+
- Helm 3+
- Docker
- kubectl configured for your cluster
- Astronomer account with Deployment Admin permissions
- Agent Token from Astro UI

## Setup Steps

### 1. Generate Agent Token

1. Navigate to your Astro Deployment
2. Go to "Remote Agents" tab
3. Click "Add Agent"
4. Copy the generated token (save securely)

### 2. Configure Environment Variables

```bash
export ASTRO_AGENT_TOKEN="your-agent-token-here"
export REGISTRY_USERNAME="your-registry-username"
export REGISTRY_PASSWORD="your-registry-password"
export WORKER_REPLICAS=3
export TRIGGERER_REPLICAS=2
export LOG_LEVEL=INFO
```

### 3. Quick Deploy (Recommended)

Use the automated deployment script:

```bash
# Make script executable
chmod +x deploy-agents.sh

# Deploy agents
./deploy-agents.sh
```

### 4. Manual Deployment

#### Step 4.1: Build Custom Agent Image

```bash
# Build custom image with additional packages
docker build -f Dockerfile.remote-agent -t your-registry.com/astro-remote-agent:latest .

# Push to your registry
docker push your-registry.com/astro-remote-agent:latest
```

#### Step 4.2: Configure Values

Edit `astronomer/remote-agents/values.yaml`:

```yaml
agentToken: "your-agent-token"
image:
  repository: "your-registry.com/astro-remote-agent"
  tag: "latest"
```

#### Step 4.3: Deploy with Helm

```bash
# Add Astronomer Helm repository
helm repo add astronomer https://helm.astronomer.io
helm repo update

# Create namespace
kubectl create namespace astronomer-remote-agents

# Apply secrets
kubectl apply -f astronomer/remote-agents/secrets.yaml

# Install agents
helm install astro-agent astronomer/astro-remote-execution-agent \
  -f astronomer/remote-agents/values.yaml \
  --namespace astronomer-remote-agents
```

## Configuration Options

### Agent Types

- **Worker Agents**: Execute DAG tasks
- **Triggerer Agents**: Handle deferrable tasks

### Secret Backends

- **Kubernetes**: Store secrets as K8s secrets (default)
- **Vault**: HashiCorp Vault integration
- **AWS**: AWS Secrets Manager
- **GCP**: Google Secret Manager

### XCom Backends

- **Kubernetes**: Store XCom data in K8s (default)
- **S3**: Amazon S3 storage
- **GCS**: Google Cloud Storage

## Agent Management

### Check Agent Status

```bash
# View agent pods
kubectl get pods -n astronomer-remote-agents

# Check agent logs
kubectl logs -f deployment/astro-agent-worker -n astronomer-remote-agents

# View agent services
kubectl get svc -n astronomer-remote-agents
```

### Scale Agents

```bash
# Scale worker agents
kubectl scale deployment astro-agent-worker --replicas=5 -n astronomer-remote-agents

# Scale triggerer agents
kubectl scale deployment astro-agent-triggerer --replicas=3 -n astronomer-remote-agents
```

### Update Agent Configuration

```bash
# Update Helm values and upgrade
helm upgrade astro-agent astronomer/astro-remote-execution-agent \
  -f astronomer/remote-agents/values.yaml \
  --namespace astronomer-remote-agents
```

### Cordon/Uncordon Agents

```bash
# Cordon agents (prevent new task scheduling)
kubectl patch deployment astro-agent-worker -p '{"spec":{"replicas":0}}' -n astronomer-remote-agents

# Uncordon agents (resume task scheduling)
kubectl patch deployment astro-agent-worker -p '{"spec":{"replicas":3}}' -n astronomer-remote-agents
```

## Monitoring and Troubleshooting

### Agent Health Checks

```bash
# Check agent health
kubectl get pods -n astronomer-remote-agents -o wide

# View detailed pod status
kubectl describe pod <pod-name> -n astronomer-remote-agents

# Check agent connectivity to Astro
kubectl logs <pod-name> -n astronomer-remote-agents | grep "connection"
```

### Common Issues

#### Agent Token Issues
- Verify token is correctly set in values.yaml
- Check token hasn't expired (regenerate if needed)
- Ensure Deployment Admin permissions

#### Image Pull Issues
- Verify image registry credentials
- Check imagePullSecretName configuration
- Ensure image exists in registry

#### Network Connectivity
- Check allowed IP ranges in Astro UI
- Verify cluster can reach Astro endpoints
- Test DNS resolution from pods

### Debug Commands

```bash
# Get Helm release status
helm status astro-agent -n astronomer-remote-agents

# View current Helm values
helm get values astro-agent -n astronomer-remote-agents

# Check events
kubectl get events -n astronomer-remote-agents --sort-by='.lastTimestamp'

# Port forward for debugging
kubectl port-forward svc/astro-agent-worker 8080:8080 -n astronomer-remote-agents
```