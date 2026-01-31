#!/bin/bash

# EC2 Instance Initialization Script
# This script configures an Amazon Linux 2023 EC2 instance with development tools
# for AWS, Terraform, Kubernetes, and container workflows

# Detect system architecture for platform-specific downloads
uname_out=$(uname -m)
case "${uname_out}" in
  x86_64*)    archsm="amd64"; archlg="x86_64";;
  aarch64*)   archsm="arm64"; archlg="aarch64";;
  *)          echo "Unknown architecture: ${uname_out}"; exit 1;;
esac

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

# Install essential utilities and database clients
yum install -y --allowerasing jq curl wget git mariadb1011 postgresql17 docker redis6

# Create temporary directory for downloads
mkdir ~/.tmp

# Install AWS CLI v2
wget https://awscli.amazonaws.com/awscli-exe-linux-${archlg}.zip -O ~/.tmp/awscliv2.zip
cd ~/.tmp; unzip ~/.tmp/awscliv2.zip; ~/.tmp/aws/install

# Install kubectl - Kubernetes command-line tool
wget https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${archsm}/kubectl -O ~/.tmp/kubectl
install -o root -g root -m 0755 ~/.tmp/kubectl /usr/local/bin/kubectl

# Install eksctl - EKS cluster management tool
wget https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_linux_${archsm}.tar.gz -O ~/.tmp/eksctl.tar.gz
tar -xzf ~/.tmp/eksctl.tar.gz -C ~/.tmp
install -o root -g root -m 0755 ~/.tmp/eksctl /usr/local/bin/eksctl

# Install Helm 3 - Kubernetes package manager
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install k9s - Kubernetes CLI UI for easier cluster management
wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${archsm}.tar.gz -O ~/.tmp/k9s.tar.gz
tar -xzf ~/.tmp/k9s.tar.gz -C ~/.tmp
install -o root -g root -m 0755 ~/.tmp/k9s /usr/local/bin/k9s

# Install gum - Beautiful interactive shell scripts
wget https://github.com/charmbracelet/gum/releases/download/v0.14.3/gum_0.14.3_Linux_${archlg}.tar.gz -O ~/.tmp/gum.tar.gz
tar -xzf ~/.tmp/gum.tar.gz -C ~/.tmp
install -o root -g root -m 0755 ~/.tmp/gum /usr/local/bin/gum

# Add default users to docker group for non-root Docker access
usermod -aG docker ec2-user
usermod -aG docker ssm-user

# Enable and start Docker service, then configure multi-architecture support
systemctl enable --now docker
mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
docker run --privileged --rm tonistiigi/binfmt --install all

# Create systemd service for persistent multi-architecture support across reboots
sh -c '
cat <<EOF > /etc/systemd/system/binfmt-qemu.service
[Unit]
Description=Register binfmt for qemu
After=proc-sys-fs-binfmt_misc.mount

[Service]
Type=oneshot
ExecStart=/usr/bin/docker run --privileged --rm tonistiigi/binfmt --install arm64

[Install]
WantedBy=multi-user.target
EOF
'

# Enable the binfmt service to run on boot
systemctl enable --now binfmt-qemu
