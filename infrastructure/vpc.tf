module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.0"

  name = "devops-final-vpc"
  cidr = "10.0.0.0/16"

  # Chọn 2 Availability Zones ở Sydney để đảm bảo tính sẵn sàng cao
  azs             = ["ap-southeast-2a", "ap-southeast-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  # Bật NAT Gateway để các worker node trong private subnet có thể ra internet tải image
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Các tag này BẮT BUỘC phải có để Kubernetes (EKS) nhận diện được mạng lưới
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}