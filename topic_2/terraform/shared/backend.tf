# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
terraform {
  backend "s3" {
    bucket         = "eks-lab-20250317-terraform-state"
    dynamodb_table = "eks-lab-terraform-state-lock"
    key            = "shared/terraform.tfstate"
    region         = "us-east-1"
  }
}
