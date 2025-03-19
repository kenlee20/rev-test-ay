variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type = string
}

variable "vpc_configuration" {
  type = object({
    vpc_cidr         = string
    azs              = list(string)
    public_subnets   = list(string)
    private_subnets  = list(string)
    database_subnets = list(string)
    intra_subnets    = list(string)
  })
}

variable "eks_configuration" {
  type = object({
    cluster_version            = string
    cluster_zonal_shift_config = optional(bool, false)
    node_group = map(object({
      ami_type            = string
      ami_release_version = string
      instance_types      = list(string)
      min_size            = number
      max_size            = number
      subnet_alias        = string
      taints = optional(map(object({
        key    = string
        value  = string
        effect = string
      })), {})
    }))
  })
}

variable "eks_addons_configuration" {
  type = map(object({
    create_irsa                = optional(bool, false)
    namespace_service_accounts = optional(list(string), [])
    attach_policy              = optional(any, {})
    role_policy_arns           = optional(map(string), {})
    configuration_values       = optional(any, {})
  }))
  default = {
    "coredns"    = {}
    "kube-proxy" = {}
    "vpc-cni"    = {}
    "aws-ebs-csi-driver" = {
      create_irsa                = true
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
      attach_policy = {
        attach_ebs_csi_policy = true
      }
    }
  }
}

variable "eks_additional_addons_configuration" {
  type = object({
    cluster_autoscaler_version           = string
    aws_load_balancer_controller_version = string
    metric_server_version = string
  })
  default = {
    cluster_autoscaler_version           = "9.46.3"
    aws_load_balancer_controller_version = "1.11.0"
    metric_server_version = "3.12.2"
  }
}
