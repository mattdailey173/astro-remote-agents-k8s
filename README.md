# Astronomer Remote Execution Agents

Complete deployment setup for Astronomer Remote Execution Agents with Kubernetes 1.30+ and Helm 3+ support.

## 🚀 Quick Start

### Prerequisites

Before you begin, ensure you have:

- **Kubernetes 1.30+** cluster running
- **Helm 3+** installed
- **Docker** installed and configured
- **kubectl** configured for your cluster
- **Astronomer account** with Deployment Admin permissions

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd astronomer-remote-agents
chmod +x deploy-agents.sh
```

### 2. Generate Agent Token

1. Log into your **Astro UI**
2. Navigate to your **Deployment**
3. Go to **"Remote Agents"** tab
4. Click **"Add Agent"**
5. **Copy the generated token** (save securely - you'll need it next)

### 3. Configure Environment Variables

**Required Variables:**
```bash
export ASTRO_AGENT_TOKEN="your-agent-token-from-step-2"
```

**Optional Variables (with defaults):**
```bash
export REGISTRY_USERNAME="your-registry-username"      # For private registries
export REGISTRY_PASSWORD="your-registry-password"      # For private registries
export WORKER_REPLICAS=3                               # Number of worker agents
export TRIGGERER_REPLICAS=2                            # Number of triggerer agents
export LOG_LEVEL=INFO                                  # Logging level
```

### 4. Update Configuration Files

#### A. Registry Configuration

Edit `astronomer/remote-agents/values.yaml`:

```yaml
# Line 11-14: Update with your container registry
image:
  repository: "your-registry.com/astro-remote-agent"  # Change this
  tag: "latest"
  pullPolicy: "IfNotPresent"

# Line 17: Update if using private registry
imagePullSecretName: "astro-registry-secret"
```

#### B. Secrets Configuration (Optional)

Edit `astronomer/remote-agents/secrets.yaml` and add your base64-encoded secrets:

```yaml
# Example: echo -n "your-secret" | base64
data:
  database-url: "cG9zdGdyZXNxbDovL3VzZXI6cGFzc0Bob3N0OjU0MzIvZGI="  # Add your DB
  redis-url: "cmVkaXM6Ly9ob3N0OjYzNzkvMA=="                          # Add your Redis
  # ... add other secrets as needed
```

### 5. Deploy Agents

**Automated Deployment (Recommended):**
```bash
./deploy-agents.sh
```

**Manual Deployment:**
```bash
# Build custom image
npm run agents:build

# Apply secrets
npm run agents:secrets

# Deploy with Helm
helm repo add astronomer https://helm.astronomer.io
helm repo update
helm install astro-agent astronomer/astro-remote-execution-agent \
  -f astronomer/remote-agents/values.yaml \
  --namespace astronomer-remote-agents \
  --create-namespace
```

### 6. Verify Deployment

Check agent status:
```bash
npm run agents:status
```

View agent logs:
```bash
npm run agents:logs
```

## 📋 Configuration Checklist

### Must Change:
- [ ] `ASTRO_AGENT_TOKEN` environment variable
- [ ] `image.repository` in `astronomer/remote-agents/values.yaml`
- [ ] Registry credentials (if using private registry)

### Should Review:
- [ ] Worker/Triggerer replica counts
- [ ] Resource limits in `values.yaml`
- [ ] Secret backend configuration
- [ ] XCom backend configuration
- [ ] Network policies (if required)

### Optional:
- [ ] Custom Python packages in `requirements.txt`
- [ ] Custom scripts in `scripts/` directory
- [ ] DAGs in `dags/` directory
- [ ] Plugins in `plugins/` directory

## 🛠️ Available Commands

```bash
# Deployment
npm run agents:deploy          # Deploy agents using script
npm run agents:build           # Build custom agent image
npm run agents:secrets         # Apply Kubernetes secrets

# Management
npm run agents:status          # Check agent pod status
npm run agents:logs            # View worker agent logs
npm run agents:scale-workers   # Scale workers to 5 replicas

# Manual commands
kubectl get pods -n astronomer-remote-agents                    # Check pods
kubectl logs -f deployment/astro-agent-triggerer -n astronomer-remote-agents  # Triggerer logs
kubectl scale deployment astro-agent-worker --replicas=X -n astronomer-remote-agents  # Scale workers
```

## 🔧 Customization

### Adding Python Packages

Edit `requirements.txt`:
```txt
pandas==2.0.3
your-custom-package==1.0.0
```

### Adding Custom Scripts

Place scripts in `scripts/` directory and rebuild:
```bash
npm run agents:build
```

### Scaling Agents

```bash
# Scale workers
kubectl scale deployment astro-agent-worker --replicas=10 -n astronomer-remote-agents

# Scale triggerers
kubectl scale deployment astro-agent-triggerer --replicas=5 -n astronomer-remote-agents
```

## 🚨 Troubleshooting

### Common Issues

**Agent Token Invalid:**
- Regenerate token in Astro UI
- Update `ASTRO_AGENT_TOKEN` environment variable
- Re-run deployment

**Image Pull Errors:**
- Check registry credentials
- Verify image exists in registry
- Check `imagePullSecretName` configuration

**Pods Not Starting:**
```bash
kubectl describe pod <pod-name> -n astronomer-remote-agents
kubectl get events -n astronomer-remote-agents --sort-by='.lastTimestamp'
```

**Network Issues:**
- Verify cluster can reach Astro endpoints
- Check allowed IP ranges in Astro UI
- Test DNS resolution from pods

### Debug Commands

```bash
# Helm status
helm status astro-agent -n astronomer-remote-agents

# View Helm values
helm get values astro-agent -n astronomer-remote-agents

# Port forward for debugging
kubectl port-forward svc/astro-agent-worker 8080:8080 -n astronomer-remote-agents
```

## 📖 Documentation

For detailed configuration options and advanced usage, see [DEPLOYMENT.md](DEPLOYMENT.md).

## 🔐 Security Notes

- Never commit the `ASTRO_AGENT_TOKEN` to version control
- Use Kubernetes secrets for sensitive data
- Regularly rotate agent tokens (every 6 months recommended)
- Review allowed IP ranges in Astro UI

## 📞 Support

- **Astronomer Documentation**: https://www.astronomer.io/docs/astro/remote-execution-agents
- **Helm Chart Issues**: https://github.com/astronomer/astro-remote-execution-agent
- **Kubernetes Issues**: Check cluster logs and events