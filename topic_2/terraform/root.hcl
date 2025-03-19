locals {
  region = "us-east-1"

  provider = <<EOF
provider "aws" {
  region = "${local.region}"
  default_tags {
    tags = {
      Managed   = "Terraform"
      Project   = "eks-lab"
    }
  }
}
EOF

  version = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.90"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }
  }
}
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "eks-lab-20250317-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    dynamodb_table = "eks-lab-terraform-state-lock"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "skip"
  disable_signature = true
  contents  = local.provider
}

generate "terraform" {
  path      = "terraform.tf"
  if_exists = "overwrite"
  contents  = local.version
}

generate "variables" {
  path      = "variables.tf"
  if_exists = "skip"
  disable_signature = true
  contents  = <<EOF
variable "region" {
  type    = string
  default = "${local.region}"
}
EOF
}

