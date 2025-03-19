provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Managed = "Terraform"
      Project = "eks-lab"
    }
  }
}

data "terraform_remote_state" "shared" {
  backend = "s3"

  config = {
    bucket = "eks-lab-20250317-terraform-state"
    key    = "shared/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.shared.outputs.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.shared.outputs.eks_cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.shared.outputs.eks_cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.shared.outputs.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.shared.outputs.eks_cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.shared.outputs.eks_cluster_name]
      command     = "aws"
    }
  }
}
