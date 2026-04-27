#!/bin/bash
# ============================================================
# DevOps Workstation Setup Script
# Cài đặt toàn bộ công cụ cần thiết trên EC2 Ubuntu 22.04
# để quản lý hạ tầng DevOps Final Project
#
# Công cụ được cài:
#   - AWS CLI v2        → giao tiếp với AWS
#   - Terraform         → tạo/phá hủy hạ tầng
#   - kubectl           → điều khiển Kubernetes (EKS)
#   - Helm              → cài Ingress, Cert-Manager, Prometheus
#   - Docker            → build/test image local
#   - Node.js 18        → chạy ứng dụng và stress test
#
# Cách dùng:
#   chmod +x setup.sh
#   ./setup.sh
# ============================================================

set -e  # Dừng ngay nếu có lỗi

echo "============================================"
echo "  DevOps Final Project — Workstation Setup"
echo "============================================"

# ============================================================
# 0. Cập nhật hệ thống
# ============================================================
echo "[0/7] Cập nhật hệ thống..."
sudo apt-get update -y
sudo apt-get install -y curl unzip gnupg software-properties-common apt-transport-https ca-certificates

# ============================================================
# 1. AWS CLI v2
# ============================================================
echo "[1/7] Cài đặt AWS CLI v2..."
if ! command -v aws &> /dev/null; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip -q /tmp/awscliv2.zip -d /tmp/
  sudo /tmp/aws/install
  rm -rf /tmp/awscliv2.zip /tmp/aws
  echo "  ✅ AWS CLI $(aws --version)"
else
  echo "  ⏭️  AWS CLI đã có: $(aws --version)"
fi

# ============================================================
# 2. Terraform
# ============================================================
echo "[2/7] Cài đặt Terraform..."
if ! command -v terraform &> /dev/null; then
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update -y && sudo apt-get install -y terraform
  echo "  ✅ Terraform $(terraform version -json | python3 -c 'import sys,json; print(json.load(sys.stdin)["terraform_version"])')"
else
  echo "  ⏭️  Terraform đã có: $(terraform version | head -1)"
fi

# ============================================================
# 3. kubectl (tương thích EKS v1.30)
# ============================================================
echo "[3/7] Cài đặt kubectl..."
if ! command -v kubectl &> /dev/null; then
  KUBECTL_VERSION="v1.30.0"
  curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  rm /tmp/kubectl
  echo "  ✅ kubectl $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
  echo "  ⏭️  kubectl đã có: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
fi

# ============================================================
# 4. Helm
# ============================================================
echo "[4/7] Cài đặt Helm..."
if ! command -v helm &> /dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  echo "  ✅ Helm $(helm version --short)"
else
  echo "  ⏭️  Helm đã có: $(helm version --short)"
fi

# ============================================================
# 5. Docker
# ============================================================
echo "[5/7] Cài đặt Docker..."
if ! command -v docker &> /dev/null; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  sudo usermod -aG docker $USER
  echo "  ✅ Docker $(docker --version)"
  echo "  ⚠️  Logout và login lại để dùng Docker không cần sudo"
else
  echo "  ⏭️  Docker đã có: $(docker --version)"
fi

# ============================================================
# 6. Node.js 18 (để chạy stress-test.js và dev local)
# ============================================================
echo "[6/7] Cài đặt Node.js 18..."
if ! command -v node &> /dev/null || [[ $(node -v | cut -d'.' -f1) != "v18" ]]; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs
  echo "  ✅ Node.js $(node -v) / npm $(npm -v)"
else
  echo "  ⏭️  Node.js đã có: $(node -v)"
fi

# ============================================================
# 7. Cấu hình AWS Credentials
# ============================================================
echo "[7/7] Hướng dẫn cấu hình AWS Credentials..."
if [ ! -f "$HOME/.aws/credentials" ]; then
  echo ""
  echo "  ⚠️  Chưa có AWS credentials. Chạy lệnh sau và nhập thông tin:"
  echo "      aws configure"
  echo "  Thông tin cần có:"
  echo "      AWS Access Key ID     → Lấy từ AWS IAM Console"
  echo "      AWS Secret Access Key → Lấy từ AWS IAM Console"
  echo "      Default region        → ap-southeast-2"
  echo "      Default output format → json"
else
  echo "  ✅ AWS credentials đã được cấu hình"
fi

# ============================================================
# Tóm tắt
# ============================================================
echo ""
echo "============================================"
echo "  ✅ Cài đặt hoàn tất! Kiểm tra lại:"
echo "============================================"
echo "  aws       → $(aws --version 2>&1 | head -1)"
echo "  terraform → $(terraform version | head -1)"
echo "  kubectl   → $(kubectl version --client --short 2>/dev/null || echo 'installed')"
echo "  helm      → $(helm version --short)"
echo "  docker    → $(docker --version)"
echo "  node      → $(node -v)"
echo ""
echo "  📖 Bước tiếp theo:"
echo "     1. aws configure                          → nhập Access Key"
echo "     2. cd infrastructure && terraform init    → khởi tạo Terraform"
echo "     3. terraform apply -auto-approve          → tạo hạ tầng (~15 phút)"
echo "     4. aws eks update-kubeconfig --region ap-southeast-2 --name devops-final-cluster"
echo "     5. kubectl get nodes                      → kiểm tra EKS cluster"
echo "============================================"
