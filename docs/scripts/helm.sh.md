---
sidebar_position: 5
---

# helm.sh

Install Helm, the package manager for Kubernetes.

## Overview

`Helm` is the package manager for Kubernetes that helps you define, install, and upgrade complex Kubernetes applications. This script uses the official Helm installation script to install the latest version of Helm 4.

## Quick Install

```bash
curl https://awsutils.github.io/helm.sh | sh
```

## Features

- Official Helm installation method
- Latest stable version (Helm 4)
- Automatic architecture detection
- Cross-platform support (Linux, macOS, Windows)
- Simple one-line installation

## Prerequisites

- Bash/sh shell
- `curl` or `wget`
- kubectl configured with cluster access
- Internet connection

## Installation Methods

### Method 1: Direct Installation

```bash
curl https://awsutils.github.io/helm.sh | sh
```

### Method 2: Download and Review

```bash
# Download script
curl -o helm.sh https://awsutils.github.io/helm.sh

# Review script
cat helm.sh

# Make executable
chmod +x helm.sh

# Run installation
./helm.sh
```

### Method 3: Manual Installation

```bash
# Download official Helm install script
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 > get_helm.sh

# Make executable
chmod +x get_helm.sh

# Run installation
./get_helm.sh
```

### Method 4: Package Manager

**macOS (Homebrew):**

```bash
brew install helm
```

**Ubuntu/Debian (apt):**

```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

## Verification

After installation, verify Helm is working:

```bash
# Check version
helm version

# Check help
helm help

# List available commands
helm --help
```

## Basic Usage

### Repository Management

```bash
# Add a chart repository
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update repositories
helm repo update

# List repositories
helm repo list

# Remove repository
helm repo remove stable

# Search charts in repository
helm search repo nginx
helm search repo bitnami/mysql
```

### Installing Charts

```bash
# Install a chart
helm install my-release bitnami/nginx

# Install with custom values
helm install my-release bitnami/nginx --values values.yaml

# Install with set values
helm install my-release bitnami/nginx \
  --set service.type=LoadBalancer \
  --set replicaCount=3

# Install in specific namespace
helm install my-release bitnami/nginx -n my-namespace --create-namespace

# Dry run (test installation)
helm install my-release bitnami/nginx --dry-run --debug

# Generate manifest without installing
helm template my-release bitnami/nginx
```

### Managing Releases

```bash
# List installed releases
helm list
helm list -A  # All namespaces
helm list -n my-namespace  # Specific namespace

# Get release status
helm status my-release

# Get release values
helm get values my-release

# Get release manifest
helm get manifest my-release

# Get all release information
helm get all my-release
```

### Upgrading Releases

```bash
# Upgrade release
helm upgrade my-release bitnami/nginx

# Upgrade with new values
helm upgrade my-release bitnami/nginx --values new-values.yaml

# Upgrade or install if not exists
helm upgrade --install my-release bitnami/nginx

# Force upgrade
helm upgrade my-release bitnami/nginx --force

# Wait for resources to be ready
helm upgrade my-release bitnami/nginx --wait --timeout 5m
```

### Rolling Back

```bash
# View release history
helm history my-release

# Rollback to previous version
helm rollback my-release

# Rollback to specific revision
helm rollback my-release 2

# Rollback with wait
helm rollback my-release --wait
```

### Uninstalling Releases

```bash
# Uninstall release
helm uninstall my-release

# Uninstall with namespace
helm uninstall my-release -n my-namespace

# Keep history for rollback
helm uninstall my-release --keep-history
```

## Working with Charts

### Chart Structure

```
mychart/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default configuration values
├── charts/             # Dependency charts
├── templates/          # Kubernetes manifests templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── _helpers.tpl   # Template helpers
└── .helmignore        # Files to ignore
```

### Creating Charts

```bash
# Create new chart
helm create mychart

# Lint chart (validate)
helm lint mychart/

# Package chart
helm package mychart/

# Install local chart
helm install my-release ./mychart
```

### Chart Dependencies

```bash
# Add dependency in Chart.yaml
dependencies:
  - name: mysql
    version: 9.3.4
    repository: https://charts.bitnami.com/bitnami

# Update dependencies
helm dependency update mychart/

# List dependencies
helm dependency list mychart/
```

## Custom Values

### values.yaml Example

```yaml
# Default values for mychart
replicaCount: 2

image:
  repository: nginx
  tag: "1.21"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  annotations: {}
  hosts:
    - host: example.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

### Override Values

```bash
# Using values file
helm install my-release ./mychart -f custom-values.yaml

# Using --set flag
helm install my-release ./mychart \
  --set replicaCount=3 \
  --set image.tag=1.22

# Using --set-string (force string type)
helm install my-release ./mychart \
  --set-string nodeSelector."kubernetes\.io/role"=master

# Using --set-file (read from file)
helm install my-release ./mychart \
  --set-file config=config.txt

# Multiple values files
helm install my-release ./mychart \
  -f values.yaml \
  -f production-values.yaml
```

## Helm Repositories

### Popular Repositories

```bash
# Add popular repositories
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add jetstack https://charts.jetstack.io
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add elastic https://helm.elastic.co
helm repo add gitlab https://charts.gitlab.io
helm repo add hashicorp https://helm.releases.hashicorp.com

# Update all repositories
helm repo update
```

### Chart Museum (Private Repository)

```bash
# Add private repository with authentication
helm repo add myprivate https://charts.example.com \
  --username myuser \
  --password mypassword

# Add with certificate
helm repo add myprivate https://charts.example.com \
  --ca-file ca.crt \
  --cert-file cert.crt \
  --key-file key.pem
```

## Common Use Cases

### Deploy NGINX Ingress Controller

```bash
# Add repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

### Deploy cert-manager

```bash
# Add repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml

# Install cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace
```

### Deploy Prometheus & Grafana

```bash
# Add repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin
```

### Deploy MySQL Database

```bash
# Add repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install MySQL
helm install mysql bitnami/mysql \
  --namespace database \
  --create-namespace \
  --set auth.rootPassword=secretpassword \
  --set auth.database=myapp
```

## Helm Plugins

### Installing Plugins

```bash
# Install helm-diff plugin
helm plugin install https://github.com/databus23/helm-diff

# Install helm-secrets plugin
helm plugin install https://github.com/jkroepke/helm-secrets

# List installed plugins
helm plugin list

# Update plugin
helm plugin update diff

# Uninstall plugin
helm plugin uninstall diff
```

### Popular Plugins

**helm-diff:**

```bash
# Compare changes before upgrade
helm diff upgrade my-release bitnami/nginx --values new-values.yaml
```

**helm-secrets:**

```bash
# Encrypt secrets
helm secrets enc secrets.yaml

# Decrypt secrets
helm secrets dec secrets.yaml

# Install with encrypted values
helm secrets install my-release ./mychart -f secrets.yaml
```

## Configuration

### Helm Configuration File

Location: `~/.config/helm/repositories.yaml`

```yaml
apiVersion: ""
generated: "2024-01-15T10:30:00Z"
repositories:
  - name: stable
    url: https://charts.helm.sh/stable
  - name: bitnami
    url: https://charts.bitnami.com/bitnami
```

### Environment Variables

```bash
# Set custom helm home
export HELM_CONFIG_HOME=~/.config/helm
export HELM_CACHE_HOME=~/.cache/helm
export HELM_DATA_HOME=~/.local/share/helm

# Set kubeconfig
export KUBECONFIG=~/.kube/config

# Set default namespace
export HELM_NAMESPACE=my-namespace

# Debug mode
export HELM_DEBUG=true
```

## Troubleshooting

### Issue: "helm: command not found"

**Solution:**

```bash
# Check installation
which helm

# Verify PATH
echo $PATH

# Add to PATH if needed
export PATH=$PATH:/usr/local/bin

# Make permanent
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### Issue: "Error: Kubernetes cluster unreachable"

**Solution:**

```bash
# Verify kubectl is configured
kubectl cluster-info

# Check kubeconfig
kubectl config view

# Update kubeconfig (for EKS)
aws eks update-kubeconfig --name my-cluster --region us-east-1

# Test with helm
helm list
```

### Issue: "Error: INSTALLATION FAILED: has no deployed releases"

**Solution:**

```bash
# Check helm releases
helm list -A

# Check pending/failed releases
helm list --all

# Uninstall failed release
helm uninstall my-release

# Reinstall
helm install my-release bitnami/nginx
```

### Issue: "Error: release has failed"

**Solution:**

```bash
# Get release status
helm status my-release

# View release history
helm history my-release

# Check Kubernetes resources
kubectl get all -n namespace

# Rollback if needed
helm rollback my-release

# Or uninstall and reinstall
helm uninstall my-release
helm install my-release bitnami/nginx
```

### Issue: Chart validation errors

**Solution:**

```bash
# Lint the chart
helm lint ./mychart

# Dry run to see what will be created
helm install my-release ./mychart --dry-run --debug

# Template to see rendered manifests
helm template my-release ./mychart

# Fix template errors in chart files
```

## Best Practices

1. **Always use version constraints** in Chart.yaml
2. **Pin chart versions** in production:
   ```bash
   helm install my-release bitnami/nginx --version 13.2.0
   ```
3. **Use values files** instead of --set for complex configurations
4. **Test charts** with --dry-run before installation
5. **Version control** your values files
6. **Use semantic versioning** for your charts
7. **Document values** in values.yaml with comments
8. **Implement health checks** in templates
9. **Set resource limits** in chart templates
10. **Use helm diff** plugin before upgrades

## Updating Helm

To update to the latest version:

```bash
# Re-run the installation script
curl https://awsutils.github.io/helm.sh | sh

# Verify new version
helm version
```

## Uninstallation

To remove Helm:

```bash
# Remove binary
sudo rm /usr/local/bin/helm

# Remove configuration (optional)
rm -rf ~/.config/helm
rm -rf ~/.cache/helm
rm -rf ~/.local/share/helm
```

## Additional Resources

- [Helm Official Documentation](https://helm.sh/docs/)
- [Helm Hub (Artifact Hub)](https://artifacthub.io/)
- [Helm Charts GitHub](https://github.com/helm/charts)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Helm GitHub Repository](https://github.com/helm/helm)

## Helm vs kubectl

| Feature            | kubectl     | Helm         |
| ------------------ | ----------- | ------------ |
| Package Management | No          | Yes          |
| Templating         | No          | Yes          |
| Versioning         | Manual      | Built-in     |
| Rollback           | Manual      | Automatic    |
| Complexity         | Simple apps | Complex apps |
| Learning Curve     | Lower       | Higher       |
| Reusability        | Limited     | High         |

## Support

For issues with:

- **Helm tool**: Visit [Helm GitHub](https://github.com/helm/helm/issues)
- **Installation script**: Open issue on [awsutils GitHub](https://github.com/awsutils/awsutils.github.io/issues)

## Related Scripts

- [kubectl.sh](./kubectl.sh.md) - Install kubectl CLI
- [eksctl.sh](./eksctl.sh.md) - Install eksctl for EKS
- [k9s.sh](./k9s.sh.md) - Install k9s Kubernetes UI

## See Also

- [Getting Started Guide](../docs/getting-started.md)
- [Configuration Guide](../docs/configuration.md)
- [Best Practices](../docs/best-practices.md)
