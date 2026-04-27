# ============================================================
# DevOps Workstation EC2
# Máy điều khiển hạ tầng: chạy terraform, kubectl, helm, aws cli
#
# Điểm khác biệt với Jenkins EC2:
#   - Dùng IAM Instance Profile thay vì Access Key thủ công
#   - EC2 tự lấy credentials từ AWS metadata service
#   - Không có key nào nằm trên máy → an toàn theo chuẩn DevSecOps
# ============================================================

# ============================================================
# 1. IAM Role cho EC2 Workstation
# ============================================================
resource "aws_iam_role" "workstation_role" {
  name        = "devops-workstation-role"
  description = "IAM Role cho DevOps Workstation EC2 — quyền quản lý EKS, S3, ECR"

  # Cho phép EC2 service đảm nhận role này
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name      = "devops-workstation-role"
    ManagedBy = "terraform"
  }
}

# Gắn quyền EKS vào Role (để chạy kubectl từ workstation)
resource "aws_iam_role_policy_attachment" "workstation_eks" {
  role       = aws_iam_role.workstation_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Gắn quyền ECR (để docker push lên ECR nếu cần)
resource "aws_iam_role_policy_attachment" "workstation_ecr" {
  role       = aws_iam_role.workstation_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Quyền custom: describe EKS, S3 uploads, describe EC2
resource "aws_iam_role_policy" "workstation_custom" {
  name = "devops-workstation-custom-policy"
  role = aws_iam_role.workstation_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSAccess"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:UpdateClusterConfig",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3UploadsAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::devops-final-uploads-dqc28664",
          "arn:aws:s3:::devops-final-uploads-dqc28664/*"
        ]
      },
      {
        Sid    = "EC2Describe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================
# 2. IAM Instance Profile (gắn Role vào EC2)
# ============================================================
resource "aws_iam_instance_profile" "workstation_profile" {
  name = "devops-workstation-profile"
  role = aws_iam_role.workstation_role.name
}

# ============================================================
# 3. Security Group cho Workstation
# ============================================================
resource "aws_security_group" "workstation_sg" {
  name        = "workstation-sg"
  description = "Security Group cho DevOps Workstation EC2"
  vpc_id      = module.vpc.vpc_id

  # SSH từ bất kỳ đâu (có thể giới hạn IP cụ thể nếu muốn bảo mật hơn)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Cho phép mọi traffic ra ngoài
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "workstation-security-group"
  }
}

# ============================================================
# 4. SSH Key Pair cho Workstation
# ============================================================
resource "tls_private_key" "workstation_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "workstation_key" {
  key_name   = "workstation-key"
  public_key = tls_private_key.workstation_key.public_key_openssh
}

# Lưu private key ra file local để SSH
resource "local_file" "workstation_private_key" {
  content         = tls_private_key.workstation_key.private_key_pem
  filename        = "${path.module}/workstation-key.pem"
  file_permission = "0400"
}

# ============================================================
# 5. EC2 Workstation Instance
# ============================================================
resource "aws_instance" "workstation" {
  ami                         = data.aws_ami.ubuntu.id   # dùng lại AMI Ubuntu từ jenkins.tf
  instance_type               = "t3.micro"               # Đủ dùng cho workstation (rẻ hơn t3.small)
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.workstation_sg.id]
  key_name                    = aws_key_pair.workstation_key.key_name
  associate_public_ip_address = true

  # ⭐ Gắn IAM Instance Profile — EC2 tự có credentials, không cần aws configure
  iam_instance_profile        = aws_iam_instance_profile.workstation_profile.name

  root_block_device {
    volume_size = 20    # 20GB cho terraform state, docker images
    volume_type = "gp3"
  }

  # Tự động cài tools khi EC2 khởi động
  user_data = file("${path.module}/../setup.sh")

  tags = {
    Name      = "devops-workstation"
    ManagedBy = "terraform"
  }
}

# Elastic IP (IP tĩnh, không đổi khi restart)
resource "aws_eip" "workstation_eip" {
  instance = aws_instance.workstation.id
  domain   = "vpc"

  tags = {
    Name = "workstation-eip"
  }
}

# ============================================================
# OUTPUT
# ============================================================
output "workstation_public_ip" {
  description = "IP của DevOps Workstation"
  value       = aws_eip.workstation_eip.public_ip
}

output "workstation_ssh" {
  description = "Lệnh SSH vào Workstation (không cần aws configure)"
  value       = "ssh -i infrastructure/workstation-key.pem ubuntu@${aws_eip.workstation_eip.public_ip}"
}
