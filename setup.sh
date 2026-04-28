#!/bin/bash
# ============================================================
# DevOps Workstation Setup Script
# Installs all required tools on EC2 Ubuntu 22.04
# for managing the DevOps Final Project infrastructure.
#
# Tools installed:
#   - AWS CLI v2        -> Communicate with AWS
#   - Terraform         -> Create/destroy infrastructure
#   - kubectl           -> Control Kubernetes (EKS)
#   - Helm              -> Install Ingress, Cert-Manager, Prometheus
#   - Docker            -> Build/test images locally
#   - Node.js 18        -> Run application and stress tests
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh
# ============================================================

set -e  # Exit immediately on error

echo "============================================"
echo "  DevOps Final Project - Workstation Setup"
echo "============================================"

# ============================================================
# 0. Update system packages
# ============================================================
echo "[0/7] Updating system packages..."
sudo apt-get update -y
sudo apt-get install -y curl unzip gnupg software-properties-common apt-transport-https ca-certificates

# ============================================================
# 1. AWS CLI v2
# ============================================================
echo "[1/7] Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip -q /tmp/awscliv2.zip -d /tmp/
  sudo /tmp/aws/install
  rm -rf /tmp/awscliv2.zip /tmp/aws
  echo "  [OK] AWS CLI $(aws --version)"
else
  echo "  [SKIP] AWS CLI already installed: $(aws --version)"
fi

# ============================================================
# 2. Terraform
# ============================================================
echo "[2/7] Installing Terraform..."
if ! command -v terraform &> /dev/null; then
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update -y && sudo apt-get install -y terraform
  echo "  [OK] Terraform $(terraform version -json | python3 -c 'import sys,json; print(json.load(sys.stdin)["terraform_version"])')"
else
  echo "  [SKIP] Terraform already installed: $(terraform version | head -1)"
fi

# ============================================================
# 3. kubectl (compatible with EKS v1.30)
# ============================================================
echo "[3/7] Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
  KUBECTL_VERSION="v1.30.0"
  curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  rm /tmp/kubectl
  echo "  [OK] kubectl $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
  echo "  [SKIP] kubectl already installed: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
fi

# ============================================================
# 4. Helm
# ============================================================
echo "[4/7] Installing Helm..."
if ! command -v helm &> /dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  echo "  [OK] Helm $(helm version --short)"
else
  echo "  [SKIP] Helm already installed: $(helm version --short)"
fi

# ============================================================
# 5. Docker
# ============================================================
echo "[5/7] Installing Docker..."
if ! command -v docker &> /dev/null; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  sudo usermod -aG docker $USER
  echo "  [OK] Docker $(docker --version)"
  echo "  [WARN] Log out and log back in to use Docker without sudo"
else
  echo "  [SKIP] Docker already installed: $(docker --version)"
fi

# ============================================================
# 6. Node.js 18 (for running stress-test.js and local dev)
# ============================================================
echo "[6/7] Installing Node.js 18..."
if ! command -v node &> /dev/null || [[ $(node -v | cut -d'.' -f1) != "v18" ]]; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs
  echo "  [OK] Node.js $(node -v) / npm $(npm -v)"
else
  echo "  [SKIP] Node.js already installed: $(node -v)"
fi

# ============================================================
# 7. Configure AWS Credentials
# ============================================================
echo "[7/7] AWS Credentials configuration..."
if [ ! -f "$HOME/.aws/credentials" ]; then
  echo ""
  echo "  [WARN] AWS credentials not found. Run the following command:"
  echo "      aws configure"
  echo "  Required information:"
  echo "      AWS Access Key ID     -> From AWS IAM Console"
  echo "      AWS Secret Access Key -> From AWS IAM Console"
  echo "      Default region        -> ap-southeast-2"
  echo "      Default output format -> json"
else
  echo "  [OK] AWS credentials already configured"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "============================================"
echo "  [OK] Installation complete! Verify below:"
echo "============================================"
echo "  aws       -> $(aws --version 2>&1 | head -1)"
echo "  terraform -> $(terraform version | head -1)"
echo "  kubectl   -> $(kubectl version --client --short 2>/dev/null || echo 'installed')"
echo "  helm      -> $(helm version --short)"
echo "  docker    -> $(docker --version)"
echo "  node      -> $(node -v)"
echo ""
echo "  Next steps:"
echo "     1. aws configure                          -> Enter Access Key"
echo "     2. cd infrastructure && terraform init    -> Initialize Terraform"
echo "     3. terraform apply -auto-approve          -> Create infrastructure (~15 min)"
echo "     4. aws eks update-kubeconfig --region ap-southeast-2 --name devops-final-cluster"
echo "     5. kubectl get nodes                      -> Verify EKS cluster"
echo "============================================"
