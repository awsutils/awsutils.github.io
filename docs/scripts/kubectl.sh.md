---
sidebar_position: 3
---

# kubectl.sh

Install kubectl, the Kubernetes command-line tool for interacting with Kubernetes clusters.

## Overview

`kubectl` is the official Kubernetes command-line tool that allows you to run commands against Kubernetes clusters. This script automates the installation of the latest stable version for Linux systems (AMD64 and ARM64 architectures).

## Quick Install

```bash
curl https://awsutils.github.io/kubectl.sh | sudo sh
```

## Features

- Automatic architecture detection (x86_64/aarch64)
- Latest stable version installation
- System-wide installation to `/usr/local/bin`
- Support for AMD64 and ARM64 architectures

## Prerequisites

- Bash/sh shell
- `curl` or `wget`
- `sudo` access (for system-wide installation)
- Linux operating system

## Installation Methods

### Method 1: Direct Installation

```bash
curl https://awsutils.github.io/kubectl.sh | sudo sh
```

### Method 2: Download and Review

```bash
# Download script
curl -o kubectl.sh https://awsutils.github.io/kubectl.sh

# Review script
cat kubectl.sh

# Make executable
chmod +x kubectl.sh

# Run installation with sudo
sudo ./kubectl.sh
```

### Method 3: User Installation

For installation without sudo (user directory):

```bash
# Download kubectl manually
ARCH=$(uname -m)
case $ARCH in
    x86_64) K8S_ARCH="amd64" ;;
    aarch64) K8S_ARCH="arm64" ;;
esac

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${K8S_ARCH}/kubectl"

# Install to user bin directory
mkdir -p ~/bin
chmod +x kubectl
mv kubectl ~/bin/

# Add to PATH (add to ~/.bashrc for persistence)
export PATH=$PATH:~/bin
```

## Verification

After installation, verify kubectl is working:

```bash
# Check version
kubectl version --client

# Check help
kubectl help

# View available commands
kubectl --help
```

## Configuration

### Connecting to a Cluster

**For Amazon EKS:**
```bash
# Update kubeconfig for EKS cluster
aws eks update-kubeconfig --name my-cluster --region us-east-1

# Verify connection
kubectl get nodes
```

**For other Kubernetes clusters:**
```bash
# Set kubeconfig file location
export KUBECONFIG=~/.kube/config

# Or specify with each command
kubectl --kubeconfig=/path/to/config get nodes
```

### Context Management

```bash
# List contexts
kubectl config get-contexts

# Switch context
kubectl config use-context my-context

# View current context
kubectl config current-context

# Set default namespace
kubectl config set-context --current --namespace=my-namespace
```

### Multiple Clusters

```bash
# Add cluster configuration
kubectl config set-cluster my-cluster \
    --server=https://cluster-endpoint.com \
    --certificate-authority=ca.crt

# Add user credentials
kubectl config set-credentials my-user \
    --token=bearer_token

# Create context
kubectl config set-context my-context \
    --cluster=my-cluster \
    --user=my-user \
    --namespace=default
```

## Common Use Cases

### Cluster Information

```bash
# Get cluster info
kubectl cluster-info

# View nodes
kubectl get nodes

# View all resources
kubectl get all --all-namespaces
```

### Working with Pods

```bash
# List pods
kubectl get pods
kubectl get pods -n namespace-name

# Pod details
kubectl describe pod pod-name

# Pod logs
kubectl logs pod-name
kubectl logs -f pod-name  # Follow logs
kubectl logs pod-name -c container-name  # Specific container

# Execute command in pod
kubectl exec -it pod-name -- /bin/bash
kubectl exec pod-name -- ls -la /app
```

### Deployments

```bash
# List deployments
kubectl get deployments

# Create deployment
kubectl create deployment nginx --image=nginx:latest

# Scale deployment
kubectl scale deployment nginx --replicas=3

# Update image
kubectl set image deployment/nginx nginx=nginx:1.21

# Rollout status
kubectl rollout status deployment/nginx

# Rollout history
kubectl rollout history deployment/nginx

# Rollback
kubectl rollout undo deployment/nginx
```

### Services

```bash
# List services
kubectl get services
kubectl get svc

# Expose deployment
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Port forwarding
kubectl port-forward service/nginx 8080:80
```

### ConfigMaps and Secrets

```bash
# Create ConfigMap
kubectl create configmap app-config --from-file=config.properties

# Create Secret
kubectl create secret generic app-secret --from-literal=password=mypassword

# View ConfigMap
kubectl get configmap app-config -o yaml

# View Secret (base64 encoded)
kubectl get secret app-secret -o yaml
```

### Namespaces

```bash
# List namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace my-app

# Delete namespace
kubectl delete namespace my-app

# Set default namespace
kubectl config set-context --current --namespace=my-app
```

### Apply Manifests

```bash
# Apply configuration
kubectl apply -f deployment.yaml

# Apply directory
kubectl apply -f ./manifests/

# Apply from URL
kubectl apply -f https://example.com/deployment.yaml

# Delete resources
kubectl delete -f deployment.yaml
```

## Required Permissions

### For EKS Clusters

IAM permissions needed to access EKS:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "eks:DescribeCluster",
      "eks:ListClusters"
    ],
    "Resource": "*"
  }]
}
```

### Kubernetes RBAC

Example Role for namespace access:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: my-app
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: my-app
subjects:
- kind: User
  name: my-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

## Troubleshooting

### Issue: "kubectl: command not found"

**Solution:**
```bash
# Check installation
which kubectl

# Verify PATH
echo $PATH

# Add to PATH if needed
export PATH=$PATH:/usr/local/bin

# Make permanent (add to ~/.bashrc)
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### Issue: "The connection to the server was refused"

**Solution:**
```bash
# Check kubeconfig
kubectl config view

# Verify cluster endpoint
kubectl cluster-info

# For EKS, update kubeconfig
aws eks update-kubeconfig --name my-cluster --region us-east-1

# Test connection
kubectl get nodes
```

### Issue: "error: You must be logged in to the server (Unauthorized)"

**Solution:**
```bash
# Check current context
kubectl config current-context

# View credentials
kubectl config view --raw

# For EKS, ensure AWS credentials are valid
aws sts get-caller-identity

# Update EKS kubeconfig
aws eks update-kubeconfig --name my-cluster --region us-east-1
```

### Issue: "Error from server (Forbidden)"

**Solution:**
```bash
# Check RBAC permissions
kubectl auth can-i get pods
kubectl auth can-i create deployments

# View current user
kubectl config view --minify

# Request appropriate permissions from cluster admin
```

## Updating kubectl

To update to the latest version:

```bash
# Re-run the installation script
curl https://awsutils.github.io/kubectl.sh | sudo sh

# Verify new version
kubectl version --client
```

## Uninstallation

To remove kubectl:

```bash
# Remove binary
sudo rm /usr/local/bin/kubectl

# Or if installed in user directory
rm ~/bin/kubectl
```

## kubectl Plugins

### krew - kubectl Plugin Manager

```bash
# Install krew
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

# Add to PATH
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Install plugins
kubectl krew install ctx
kubectl krew install ns
```

### Useful Plugins

```bash
# kubectx - Switch contexts easily
kubectl krew install ctx
kubectl ctx

# kubens - Switch namespaces easily
kubectl krew install ns
kubectl ns

# stern - Multi-pod log tailing
kubectl krew install stern
kubectl stern pod-name
```

## kubectl Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Common aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'

# Namespace aliases
alias kgpn='kubectl get pods -n'
alias kgsn='kubectl get services -n'
alias kgdn='kubectl get deployments -n'
```

## Best Practices

1. **Use namespaces** to organize resources
2. **Label resources** for better organization
3. **Use declarative configuration** (YAML files) over imperative commands
4. **Version control** your manifests
5. **Use dry-run** before applying changes:
   ```bash
   kubectl apply -f deployment.yaml --dry-run=client
   ```
6. **Monitor resource usage:**
   ```bash
   kubectl top nodes
   kubectl top pods
   ```
7. **Use resource limits** in pod specifications
8. **Implement RBAC** for access control

## Additional Resources

- [kubectl Official Documentation](https://kubernetes.io/docs/reference/kubectl/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl GitHub Repository](https://github.com/kubernetes/kubectl)

## Support

For issues with:
- **kubectl tool**: Visit [Kubernetes GitHub](https://github.com/kubernetes/kubectl/issues)
- **Installation script**: Open issue on [AWS Utilities GitHub](https://github.com/awsutils/awsutils.github.io/issues)

## Related Scripts

- [eksctl.sh](./eksctl.sh.md) - Install eksctl for EKS management
- [k9s.sh](./k9s.sh.md) - Install k9s Kubernetes CLI UI
- [helm.sh](./helm.sh.md) - Install Helm package manager

## See Also

- [Getting Started Guide](../docs/getting-started.md)
- [Configuration Guide](../docs/configuration.md)
- [Best Practices](../docs/best-practices.md)
