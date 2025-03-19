project = "eks-lab"
vpc_configuration = {
  name             = "eks-lav-vpc"
  vpc_cidr         = "10.0.0.0/16"
  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  intra_subnets    = ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]
}

eks_configuration = {
  cluster_version = "1.32"
  node_group = {
    general = {
      ami_type            = "AL2023_x86_64_STANDARD"
      ami_release_version = "1.32.1-20250304"
      instance_types      = ["t3.medium"]
      min_size            = 3
      max_size            = 12
      subnet_alias        = "private_subnets"
    }
    database = {
      ami_type            = "AL2023_x86_64_STANDARD"
      ami_release_version = "1.32.1-20250304"
      instance_types      = ["t3.medium"]
      min_size            = 3
      max_size            = 12
      subnet_alias        = "database_subnets"
      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "database"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }
}