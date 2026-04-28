# ============================================================
# EKS Cluster
# ============================================================
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "devops-final-cluster"
  cluster_version = "1.30" # Stable Kubernetes version

  # Use the VPC created in vpc.tf
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # Enable public endpoint so kubectl can reach the cluster from Windows
  cluster_endpoint_public_access = true

  # Install EBS CSI Driver addon automatically (required for PersistentVolumeClaims)
  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

    # Attach the EBS CSI Driver policy to all node groups
    # This allows the CSI driver to create/attach/detach EBS volumes
    iam_role_additional_policies = {
      AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  }

  eks_managed_node_groups = {
    worker_nodes = {
      name           = "worker-group-1"
      instance_types = ["t3.medium"] # Sufficient for the project, cost-effective

      min_size     = 1
      max_size     = 2
      desired_size = 2
    }
  }

  # Grant cluster admin permissions to the devops-admin IAM user
  enable_cluster_creator_admin_permissions = true
}