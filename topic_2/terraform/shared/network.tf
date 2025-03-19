locals {
  vpc = {
    public_subnets   = module.vpc.public_subnets
    private_subnets  = module.vpc.private_subnets
    database_subnets = module.vpc.database_subnets
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = var.project
  cidr = var.vpc_configuration.vpc_cidr

  azs            = var.vpc_configuration.azs
  public_subnets = var.vpc_configuration.public_subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnets = var.vpc_configuration.private_subnets
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
  database_subnets = var.vpc_configuration.database_subnets
  intra_subnets    = var.vpc_configuration.intra_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
}
