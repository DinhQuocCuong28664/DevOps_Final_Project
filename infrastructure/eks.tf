module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "devops-final-cluster"
  cluster_version = "1.30" # Bản K8s mới và ổn định

  # Chỉ định EKS sử dụng Mạng VPC mà chúng ta vừa tạo ở file vpc.tf
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # Bật tính năng này để bạn có thể gõ lệnh kubectl điều khiển cluster từ máy tính Windows
  cluster_endpoint_public_access  = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    worker_nodes = {
      name = "worker-group-1"
      instance_types = ["t3.medium"] # Đủ dùng cho đồ án, không bị lố tiền

      min_size     = 1
      max_size     = 2
      desired_size = 2
    }
  }

  # Cấp quyền Admin của Cluster cho tài khoản devops-admin mà bạn đang dùng
  enable_cluster_creator_admin_permissions = true
}