---
sidebar_position: 10
---

# csinit.sh

Initialize AWS CloudShell with essential development tools for AWS, Terraform, and Kubernetes workflows.

## Overview

`csinit.sh` is a comprehensive initialization script designed specifically for AWS CloudShell environments. It configures your CloudShell session with useful aliases, environment variables, and installs critical tools like Terraform and k9s. The script also enables multi-architecture Docker support for building ARM64 images on x86_64 hosts.

## Quick Install

```bash
curl https://awsutils.github.io/csinit.sh | sh
```

## Features

- **Shell Configuration**: Adds Terraform and kubectl aliases for faster workflow
- **Terraform Installation**: Installs latest Terraform from HashiCorp's official repository
- **k9s Installation**: Kubernetes CLI UI for easier cluster management
- **Multi-arch Docker Support**: Enables building and running ARM64 images on x86_64
- **Architecture Detection**: Automatically detects and supports AMD64/ARM64 architectures

## Prerequisites

- AWS CloudShell environment
- Internet connectivity
- Sufficient permissions to install packages

## What Gets Installed

### Shell Aliases

The script adds the following aliases to `~/.bashrc`:

**Terraform aliases:**
```bash
alias t="terraform"              # Shortcut for terraform
alias ti="terraform init"         # Initialize terraform
alias taa="terraform apply --auto-approve --parallelism 100"  # Fast apply
alias td="terraform destroy --parallelism 100"                # Fast destroy
```

**Kubernetes aliases:**
```bash
alias k="kubectl"                # Shortcut for kubectl
alias ka="kubectl apply -f"      # Apply manifest
alias kx="kubectl delete -f"     # Delete resources
alias kd="kubectl describe -f"   # Describe resources
alias kg="kubectl get pod -f"    # Get pods from file
```

**Environment variables:**
```bash
export EDITOR="vim"              # Set vim as default editor
```

### Installed Tools

1. **Terraform** - Infrastructure as Code tool from HashiCorp
2. **k9s** - Terminal-based UI for Kubernetes clusters
3. **Docker Multi-arch Support** - QEMU binfmt for building ARM64 images

## Installation Methods

### Method 1: Direct Installation (Recommended)

```bash
curl https://awsutils.github.io/csinit.sh | sh
```

### Method 2: Download and Review

```bash
# Download script
curl -o csinit.sh https://awsutils.github.io/csinit.sh

# Review script
cat csinit.sh

# Make executable
chmod +x csinit.sh

# Run installation
./csinit.sh
```

### Method 3: Save as CloudShell Startup Script

Create a startup script that runs automatically:

```bash
# Download to CloudShell home directory
cd ~
curl -o csinit.sh https://awsutils.github.io/csinit.sh
chmod +x csinit.sh

# Create startup script
cat > ~/.cloudshell/startup.sh << 'EOF'
#!/bin/bash
~/csinit.sh
EOF

chmod +x ~/.cloudshell/startup.sh
```

## Post-Installation

### Reload Shell Configuration

After installation, reload your bashrc to use the new aliases:

```bash
source ~/.bashrc
```

### Verify Installations

```bash
# Check Terraform
terraform version

# Check k9s
k9s version

# Test aliases
t version
k version --client
```

## Common Use Cases

### Terraform Workflows

```bash
# Initialize Terraform project
ti

# Format code
t fmt

# Validate configuration
t validate

# Plan changes
t plan

# Apply with auto-approval
taa

# Destroy infrastructure
td
```

### Kubernetes Management

```bash
# View cluster with k9s
k9s

# Apply Kubernetes manifest
ka deployment.yaml

# Get pods
k get pods

# Delete resources
kx deployment.yaml
```

### Multi-Architecture Docker Builds

```bash
# Build ARM64 image on x86_64 CloudShell
docker buildx build --platform linux/arm64 -t myapp:arm64 .

# Build multi-platform image
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:latest .
```

## Architecture Support

The script automatically detects your system architecture:

| Architecture | Detected As | Tools Installed |
|--------------|-------------|-----------------|
| x86_64 (Intel/AMD) | amd64/x86_64 | All tools (AMD64 versions) |
| ARM64 (Graviton) | arm64/aarch64 | All tools (ARM64 versions) |

## CloudShell-Specific Configuration

### Persistent Storage

CloudShell home directory (`~/`) persists across sessions. Tools installed to `/usr/local/bin` will need to be reinstalled after CloudShell resets (approximately every 20 minutes of inactivity).

To maintain tools across sessions:

```bash
# Create a startup script (already in Method 3)
cat > ~/.cloudshell/startup.sh << 'EOF'
#!/bin/bash
# Re-run init script if tools are missing
if ! command -v terraform &> /dev/null; then
    curl -s https://awsutils.github.io/csinit.sh | sh
fi
EOF

chmod +x ~/.cloudshell/startup.sh
```

### CloudShell Limitations

- **Session Duration**: Sessions terminate after ~20 minutes of inactivity
- **Root Access**: Some commands require `sudo su` which is handled by the script
- **Docker**: Pre-installed in CloudShell
- **AWS CLI**: Pre-installed and pre-configured with your IAM credentials

## Troubleshooting

### Issue: "dnf: command not found"

**Solution:** This script is designed for Amazon Linux 2023-based CloudShell. If you see this error, you may be using an older CloudShell environment.

```bash
# Check OS version
cat /etc/os-release

# For older Amazon Linux 2, use yum instead
# (Consider using ec2init.sh instead)
```

### Issue: Aliases not working

**Solution:** Reload your bashrc after installation:

```bash
source ~/.bashrc
```

If still not working, check if the aliases were added:

```bash
tail -20 ~/.bashrc
```

### Issue: Permission denied errors

**Solution:** The script switches to root for installations:

```bash
# The script includes 'sudo su' command
# If you encounter issues, run manually
sudo dnf install -y terraform
```

### Issue: Multi-arch Docker not working

**Solution:** Verify binfmt is mounted and QEMU is registered:

```bash
# Check if binfmt is mounted
ls /proc/sys/fs/binfmt_misc/

# Re-register QEMU
sudo mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
sudo docker run --privileged --rm tonistiigi/binfmt --install all

# Test ARM64 build
docker run --rm --platform linux/arm64 alpine uname -m
```

## Updating

To update tools to their latest versions, re-run the script:

```bash
curl https://awsutils.github.io/csinit.sh | sh
```

## Uninstallation

To remove installed tools:

```bash
# Remove Terraform
sudo dnf remove -y terraform

# Remove k9s
sudo rm /usr/local/bin/k9s

# Remove aliases (edit ~/.bashrc and remove the added lines)
nano ~/.bashrc
```

## Security Considerations

- **Script Execution**: Always review scripts before running them
- **Auto-Approve**: The `taa` alias uses `--auto-approve` which bypasses confirmation
- **Root Access**: Script uses `sudo su` for system-level installations
- **Docker Privileged**: Multi-arch setup requires privileged Docker container

## Differences from ec2init.sh

| Feature | csinit.sh | ec2init.sh |
|---------|-----------|------------|
| Target Environment | AWS CloudShell | EC2 Instances |
| AWS CLI | Pre-installed | Installs AWS CLI v2 |
| kubectl | Uses CloudShell's | Installs kubectl |
| eksctl | Uses CloudShell's | Installs eksctl |
| Helm | Uses CloudShell's | Installs Helm |
| Docker Setup | Minimal | Full setup with user permissions |
| Database Clients | Not included | Includes MariaDB, PostgreSQL, Redis |
| Persistence Service | Not needed | Creates systemd service for multi-arch |

## Best Practices

1. **Review before running**: Always review scripts before executing them
2. **Use version control**: Keep your Terraform code in Git
3. **Test in dev first**: Use CloudShell for development, not production changes
4. **Limit auto-approve**: Use `taa` alias only when you're confident about changes
5. **Regular updates**: Re-run the script periodically to get latest tool versions

## Additional Resources

- [AWS CloudShell Documentation](https://docs.aws.amazon.com/cloudshell/latest/userguide/welcome.html)
- [Terraform Documentation](https://www.terraform.io/docs)
- [k9s Documentation](https://k9scli.io/)

## Support

For issues with:

- **CloudShell environment**: Contact [AWS Support](https://aws.amazon.com/support/)
- **Installation script**: Open issue on [awsutils GitHub](https://github.com/awsutils/awsutils.github.io/issues)
- **Terraform**: Visit [Terraform GitHub](https://github.com/hashicorp/terraform/issues)
- **k9s**: Visit [k9s GitHub](https://github.com/derailed/k9s/issues)

## Related Scripts

- [ec2init.sh](./ec2init.sh.md) - Full EC2 instance initialization
- [kubectl.sh](./kubectl.sh.md) - Install kubectl only
- [k9s.sh](./k9s.sh.md) - Install k9s only
- [helm.sh](./helm.sh.md) - Install Helm only

## See Also

- [Getting Started Guide](../docs/getting-started.md)
- [Best Practices](../docs/best-practices.md)
- [Configuration Guide](../docs/configuration.md)
