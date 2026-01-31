#!/bin/sh

# AWS CloudShell Initialization Script
# This script sets up a CloudShell environment with development tools and utilities
# for working with AWS, Terraform, and Kubernetes

# Add useful shell aliases and environment variables to bashrc
cat <<'EOF' >> ~/.bashrc

# Terraform aliases for faster workflow
alias t="terraform"
alias ti="terraform init"
alias taa="terraform apply --auto-approve --parallelism 100"
alias td="terraform destroy --parallelism 100"

# Kubernetes aliases for common operations
alias k="kubectl"
alias ka="kubectl apply -f"
alias kx="kubectl delete -f"
alias kd="kubectl describe -f"
alias kg="kubectl get pod -f"

# Set vim as the default editor
export EDITOR="vim"

EOF

# Switch to root user for installation commands
sudo su

# Detect system architecture for platform-specific downloads
uname_out=$(uname -m)
case "${uname_out}" in
  x86_64*)    archsm="amd64"; archlg="x86_64";;
  aarch64*)   archsm="arm64"; archlg="aarch64";;
  *)          echo "Unknown architecture: ${uname_out}"; exit 1;;
esac

# Create temporary directory for downloads
mkdir ~/.tmp

# Install Terraform from HashiCorp's official repository
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
dnf -y install terraform

# Install k9s - Kubernetes CLI UI for easier cluster management
wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${archsm}.tar.gz -O ~/.tmp/k9s.tar.gz
tar -xzf ~/.tmp/k9s.tar.gz -C ~/.tmp
install -o root -g root -m 0755 ~/.tmp/k9s /usr/local/bin/k9s

# Install gum - Beautiful interactive shell scripts
wget https://github.com/charmbracelet/gum/releases/download/v0.14.3/gum_0.14.3_Linux_${archlg}.tar.gz -O ~/.tmp/gum.tar.gz
tar -xzf ~/.tmp/gum.tar.gz -C ~/.tmp
install -o root -g root -m 0755 ~/.tmp/gum /usr/local/bin/gum

# Enable multi-architecture Docker image support (e.g., ARM64 images on x86_64)
mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
docker run --privileged --rm tonistiigi/binfmt --install all
