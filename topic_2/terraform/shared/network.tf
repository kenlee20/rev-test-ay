module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = var.project
  cidr = "10.0.0.0/16"

  azs            = ["${var.region}a", "${var.region}c"]
  public_subnets = ["10.0.0.0/24", "10.0.1.0/24"]
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = local.eks.name
  }

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  tags = {
    "kubernetes.io/cluster/${local.eks.name}" = "owned",
  }
}

