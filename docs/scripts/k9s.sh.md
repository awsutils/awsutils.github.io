---
sidebar_position: 4
---

# k9s.sh

Install k9s, a terminal-based UI for managing and monitoring Kubernetes clusters.

## Overview

`k9s` is a terminal-based UI that provides an intuitive interface for navigating, observing, and managing your Kubernetes clusters in real-time. This script automates the installation of the latest version for Linux systems (AMD64 and ARM64 architectures).

## Quick Install

```bash
curl https://awsutils.github.io/k9s.sh | sudo sh
```

## Features

- Terminal-based UI for Kubernetes
- Real-time cluster monitoring
- Resource browsing and management
- Log viewing and streaming
- Pod shell access
- Quick navigation with keyboard shortcuts
- Multi-cluster support
- Context switching
- Resource editing
- Automatic architecture detection (x86_64/aarch64)

## Prerequisites

- Bash/sh shell
- `wget` or `curl`
- `tar` for extraction
- `sudo` access (for system-wide installation)
- Linux operating system
- kubectl configured with cluster access

## Installation Methods

### Method 1: Direct Installation

```bash
curl https://awsutils.github.io/k9s.sh | sudo sh
```

### Method 2: Download and Review

```bash
# Download script
curl -o k9s.sh https://awsutils.github.io/k9s.sh

# Review script
cat k9s.sh

# Make executable
chmod +x k9s.sh

# Run installation with sudo
sudo ./k9s.sh
```

### Method 3: User Installation (without sudo)

```bash
# Download k9s manually
ARCH=$(uname -m)
case $ARCH in
    x86_64) K9S_ARCH="amd64" ;;
    aarch64) K9S_ARCH="arm64" ;;
esac

wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${K9S_ARCH}.tar.gz
tar -xzf k9s_Linux_${K9S_ARCH}.tar.gz

# Install to user bin directory
mkdir -p ~/bin
chmod +x k9s
mv k9s ~/bin/

# Add to PATH
export PATH=$PATH:~/bin
```

## Verification

After installation, verify k9s is working:

```bash
# Check version
k9s version

# Check help
k9s help

# Launch k9s (requires kubectl configuration)
k9s
```

## Basic Usage

### Launching k9s

```bash
# Launch with default context
k9s

# Launch with specific context
k9s --context my-context

# Launch in specific namespace
k9s -n my-namespace

# Launch in all namespaces
k9s -A

# Launch with readonly mode
k9s --readonly

# Launch with custom kubeconfig
k9s --kubeconfig ~/.kube/custom-config
```

## Keyboard Shortcuts

### Navigation

| Key | Action |
|-----|--------|
| `?` | Show help/keyboard shortcuts |
| `:` | Enter command mode |
| `/` | Filter/search |
| `Esc` | Exit/back |
| `Ctrl+a` | Show all available resources |
| `Ctrl+d` | Delete resource |
| `Ctrl+k` | Kill pod/process |
| `0-9` | Switch to namespace (if configured) |

### Resource Management

| Key | Action |
|-----|--------|
| `d` | Describe resource |
| `e` | Edit resource |
| `l` | View logs |
| `y` | View YAML |
| `s` | Shell into container |
| `f` | Port forward |
| `ctrl+d` | Delete resource |
| `ctrl+l` | Toggle live logs |

### Views

| Key | Action |
|-----|--------|
| `:pods` | Show pods |
| `:deployments` | Show deployments |
| `:services` | Show services |
| `:nodes` | Show nodes |
| `:namespaces` | Show namespaces |
| `:pv` | Show persistent volumes |
| `:pvc` | Show persistent volume claims |
| `:events` | Show events |

## Common Use Cases

### Monitoring Pods

```bash
# Launch k9s
k9s

# Navigate to pods (type :pods or :po)
:pods

# Filter pods (press /)
/my-app

# View logs (select pod and press 'l')
# Stream logs in real-time
# Previous logs (shift+l)

# Shell into pod (select pod and press 's')
# Exit shell with 'exit' or Ctrl+D
```

### Viewing Resource Details

```bash
# Describe resource (press 'd' on selected resource)
# View YAML (press 'y' on selected resource)
# Edit resource (press 'e' on selected resource)
```

### Managing Deployments

```bash
# Navigate to deployments
:deployments

# Scale deployment
# Select deployment, press 's', enter replica count

# Restart deployment
# Select deployment, press 'ctrl+r'

# View pods for deployment
# Select deployment, press 'Enter'
```

### Port Forwarding

```bash
# Select pod or service
# Press 'shift+f' to configure port forward
# Enter local:remote port (e.g., 8080:80)
# Access via localhost:8080
```

### Log Viewing

```bash
# View logs (press 'l' on pod)
# Follow logs in real-time
# Filter logs (press '/')
# View previous container logs (shift+l)
# Toggle auto-scroll (press 'a')
# Clear logs (press 'c')
```

### Context and Namespace Switching

```bash
# Switch context (press ':ctx')
:ctx

# Switch namespace (press ':ns' or number 0-9)
:ns

# View all namespaces (press ':namespaces')
:namespaces
```

## Configuration

k9s uses a configuration file located at `~/.config/k9s/config.yaml`

### Basic Configuration

```yaml
k9s:
  # Set refresh rate (default: 2s)
  refreshRate: 2

  # Set max log lines (default: 1000)
  maxConnRetry: 5

  # Enable mouse support
  enableMouse: false

  # Set log level
  logLevel: info

  # Set log file
  logFile: /tmp/k9s.log

  # Set namespace
  namespace: default

  # Set view settings
  view:
    active: pods
```

### Custom Aliases

Create `~/.config/k9s/alias.yaml`:

```yaml
alias:
  # Custom shortcuts
  dp: v1/deployments
  svc: v1/services
  ing: networking.k8s.io/v1/ingresses
  sec: v1/secrets
  cm: v1/configmaps
  pv: v1/persistentvolumes
  pvc: v1/persistentvolumeclaims
  sa: v1/serviceaccounts
```

### Hotkeys Configuration

Create `~/.config/k9s/hotkey.yaml`:

```yaml
hotKey:
  # Custom hotkeys
  hotKey:
    shift-0:
      shortCut: Shift-0
      description: View pods
      command: pods
    shift-1:
      shortCut: Shift-1
      description: View deployments
      command: deployments
    shift-2:
      shortCut: Shift-2
      description: View services
      command: services
```

### Skin/Theme Configuration

k9s supports custom skins. Create `~/.config/k9s/skin.yaml`:

```yaml
k9s:
  body:
    fgColor: white
    bgColor: black
    logoColor: blue
  prompt:
    fgColor: white
    bgColor: black
  info:
    fgColor: lightskyblue
    sectionColor: white
  dialog:
    fgColor: white
    bgColor: black
    buttonFgColor: black
    buttonBgColor: lightskyblue
    buttonFocusFgColor: white
    buttonFocusBgColor: dodgerblue
  table:
    fgColor: white
    bgColor: black
    cursorColor: aqua
    header:
      fgColor: white
      bgColor: black
      sorterColor: cyan
```

## Advanced Features

### XRay View

View pod relationships and dependencies:

```bash
# In k9s, press 'x' on a pod to enter XRay mode
# Shows associated resources (services, deployments, etc.)
```

### Pulse View

Real-time metrics visualization:

```bash
# Press 'shift+p' to view cluster pulse
# Shows resource utilization across nodes
```

### Benchmarks

Performance testing within k9s:

```bash
# Select a resource
# Press 'b' to run benchmark
# Configure test parameters
```

### Popeye Integration

Cluster sanitization reports:

```bash
# Install popeye
# k9s will automatically detect and integrate
# Press 'shift+f' in k9s to run popeye scan
```

## Troubleshooting

### Issue: "k9s: command not found"

**Solution:**
```bash
# Check installation
which k9s

# Verify PATH
echo $PATH

# Add to PATH if needed
export PATH=$PATH:/usr/local/bin

# Make permanent
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### Issue: "Unable to connect to cluster"

**Solution:**
```bash
# Verify kubectl is configured
kubectl cluster-info

# Check kubeconfig
kubectl config view

# Update kubeconfig (for EKS)
aws eks update-kubeconfig --name my-cluster --region us-east-1

# Try k9s with explicit context
k9s --context my-context
```

### Issue: "Unauthorized" or "Forbidden" errors

**Solution:**
```bash
# Check RBAC permissions
kubectl auth can-i get pods --all-namespaces

# Use readonly mode if you lack permissions
k9s --readonly

# Request appropriate cluster permissions
```

### Issue: k9s crashes or hangs

**Solution:**
```bash
# Check logs
cat ~/.config/k9s/k9s.log

# Clear cache
rm -rf ~/.config/k9s/cache

# Reset configuration
mv ~/.config/k9s ~/.config/k9s.backup

# Restart k9s
k9s
```

### Issue: Missing metrics

**Solution:**
```bash
# Verify metrics-server is installed
kubectl get deployment metrics-server -n kube-system

# Install metrics-server if missing
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify metrics are available
kubectl top nodes
kubectl top pods
```

## Updating k9s

To update to the latest version:

```bash
# Re-run the installation script
curl https://awsutils.github.io/k9s.sh | sudo sh

# Verify new version
k9s version
```

## Uninstallation

To remove k9s:

```bash
# Remove binary
sudo rm /usr/local/bin/k9s

# Remove configuration (optional)
rm -rf ~/.config/k9s

# Or if installed in user directory
rm ~/bin/k9s
```

## Tips and Tricks

### Quick Navigation

1. **Use command palette** (`:`) for quick resource access
2. **Set up hotkeys** for frequently accessed resources
3. **Use filters** (`/`) to narrow down results
4. **Bookmark contexts** for quick switching

### Efficient Log Analysis

1. **Filter logs** with `/pattern`
2. **Toggle timestamps** with `t`
3. **Clear logs** with `c` for fresh view
4. **Use previous logs** (shift+l) for crashed containers

### Multi-Cluster Management

1. **Configure contexts** in kubectl
2. **Switch contexts** quickly with `:ctx`
3. **Use different terminals** for multiple clusters
4. **Set up aliases** for different environments

### Resource Monitoring

1. **Use pulse view** for cluster overview
2. **Monitor events** with `:events`
3. **Check node status** with `:nodes`
4. **Review pod status** regularly

## Best Practices

1. **Use readonly mode** in production: `k9s --readonly`
2. **Configure appropriate RBAC** permissions
3. **Familiarize yourself with shortcuts** for efficiency
4. **Set up custom aliases** for your workflow
5. **Use filtering** to reduce noise
6. **Monitor logs in real-time** for troubleshooting
7. **Leverage XRay view** for understanding relationships
8. **Keep k9s updated** for latest features

## Additional Resources

- [k9s Official Documentation](https://k9scli.io/)
- [k9s GitHub Repository](https://github.com/derailed/k9s)
- [k9s Video Tutorials](https://www.youtube.com/results?search_query=k9s+kubernetes)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Comparison with kubectl

| Feature | kubectl | k9s |
|---------|---------|-----|
| Interface | CLI | Terminal UI |
| Learning Curve | Steeper | Gentler |
| Speed | Command-based | Visual navigation |
| Log Viewing | Limited | Excellent |
| Resource Editing | YAML editor required | Built-in editor |
| Multi-tasking | Requires multiple terminals | Single interface |
| Scripting | Excellent | Not designed for it |

## Support

For issues with:
- **k9s tool**: Visit [k9s GitHub](https://github.com/derailed/k9s/issues)
- **Installation script**: Open issue on [AWS Utilities GitHub](https://github.com/awsutils/awsutils.github.io/issues)

## Related Scripts

- [kubectl.sh](./kubectl.sh.md) - Install kubectl CLI
- [eksctl.sh](./eksctl.sh.md) - Install eksctl for EKS
- [helm.sh](./helm.sh.md) - Install Helm package manager

## See Also

- [Getting Started Guide](../docs/getting-started.md)
- [Configuration Guide](../docs/configuration.md)
- [Best Practices](../docs/best-practices.md)
