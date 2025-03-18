project = "eks-lab"
vpc_configuration = {
  name = "eks-lav-vpc"
  vpc_cidr = "10.0.0.0/16"
  azs = ["us-east-1a", "us-east-1c"]
}

eks_configuration = {
  cluster_version = "1.32"
  addons = {
    coredns = {}
    kube-proxy = {}
    vpc_cni = {}
  }
}