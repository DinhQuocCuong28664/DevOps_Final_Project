# ============================================================
# workstation.tf - DevOps Workstation EC2
# A control-plane EC2 instance for running terraform, kubectl,
# helm, and aws-cli without storing credentials locally.
# Uses IAM Instance Profile instead of Access Keys.
# ============================================================

# ============================================================
# 1. IAM Role for EC2 Workstation
# ============================================================
resource "aws_iam_role" "workstation_role" {
  name        = "devops-workstation-role"
  description = "IAM Role for DevOps Workstation EC2 - EKS, S3, ECR access"

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

resource "aws_iam_role_policy_attachment" "workstation_eks" {
  role       = aws_iam_role.workstation_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "workstation_ecr" {
  role       = aws_iam_role.workstation_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

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
# 2. IAM Instance Profile (attach Role to EC2)
# ============================================================
resource "aws_iam_instance_profile" "workstation_profile" {
  name = "devops-workstation-profile"
  role = aws_iam_role.workstation_role.name
}

# ============================================================
# 3. Security Group for Workstation
# ============================================================
resource "aws_security_group" "workstation_sg" {
  name        = "workstation-sg"
  description = "Security Group for DevOps Workstation EC2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "workstation-security-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================
# 4. SSH Key Pair for Workstation
# ============================================================
resource "tls_private_key" "workstation_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "workstation_key" {
  key_name   = "workstation-key"
  public_key = tls_private_key.workstation_key.public_key_openssh
}

resource "local_file" "workstation_private_key" {
  content         = tls_private_key.workstation_key.private_key_pem
  filename        = "${path.module}/workstation-key.pem"
  file_permission = "0400"
}

# ============================================================
# 5. EC2 Workstation Instance
# ============================================================
resource "aws_instance" "workstation" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.workstation_sg.id]
  key_name                    = aws_key_pair.workstation_key.key_name
  associate_public_ip_address = true

  # IAM Instance Profile - EC2 gets credentials automatically, no aws configure needed
  iam_instance_profile = aws_iam_instance_profile.workstation_profile.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = file("${path.module}/../setup.sh")

  tags = {
    Name      = "devops-workstation"
    ManagedBy = "terraform"
  }
}

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
  description = "Public IP of the DevOps Workstation EC2"
  value       = aws_eip.workstation_eip.public_ip
}

output "workstation_ssh" {
  description = "SSH command for the Workstation (no aws configure required)"
  value       = "ssh -i infrastructure/workstation-key.pem ubuntu@${aws_eip.workstation_eip.public_ip}"
}
