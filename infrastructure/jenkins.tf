# ============================================================
# BONUS: Self-Hosted Jenkins CI/CD Server
# EC2 t3.small + Security Group + Elastic IP
# Domain: jenkins.moteo.fun (cần thêm A record trên Hostinger)
# ============================================================

# Lấy AMI Ubuntu 22.04 mới nhất
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group cho Jenkins
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security Group cho Jenkins Server"
  vpc_id      = module.vpc.vpc_id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP (Nginx redirect to HTTPS)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (Nginx + Certbot)
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins UI (backup, Nginx sẽ proxy từ 443)
  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
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
    Name = "jenkins-security-group"
  }
}

# SSH Key Pair (tự tạo, lưu vào file local)
resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = tls_private_key.jenkins_key.public_key_openssh
}

# Lưu private key ra file để SSH
resource "local_file" "jenkins_private_key" {
  content         = tls_private_key.jenkins_key.private_key_pem
  filename        = "${path.module}/jenkins-key.pem"
  file_permission = "0400"
}

# EC2 Instance cho Jenkins
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  key_name                    = aws_key_pair.jenkins_key.key_name
  associate_public_ip_address = true

  # Ổ cứng 20GB (đủ cho Jenkins + Docker images)
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  # Script tự động cài đặt Jenkins khi EC2 khởi động
  user_data = file("${path.module}/jenkins-setup.sh")

  tags = {
    Name = "jenkins-server"
  }
}

# Elastic IP (IP tĩnh, không đổi khi restart EC2)
resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"

  tags = {
    Name = "jenkins-eip"
  }
}

# ============================================================
# OUTPUT: Hiển thị thông tin sau khi terraform apply
# ============================================================
output "jenkins_public_ip" {
  description = "IP công khai của Jenkins Server (dùng cho DNS A record)"
  value       = aws_eip.jenkins_eip.public_ip
}

output "jenkins_url" {
  description = "URL truy cập Jenkins (sau khi cấu hình DNS)"
  value       = "https://jenkins.moteo.fun"
}

output "jenkins_ssh" {
  description = "Lệnh SSH vào Jenkins Server"
  value       = "ssh ubuntu@${aws_eip.jenkins_eip.public_ip}"
}
