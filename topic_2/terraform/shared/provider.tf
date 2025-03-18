provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Managed = "Terraform"
      Project = "eks-lab"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = local.eks.endpoint
    cluster_ca_certificate = base64decode(local.eks.ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", local.eks.name]
      command     = "aws"
    }
  }
}
