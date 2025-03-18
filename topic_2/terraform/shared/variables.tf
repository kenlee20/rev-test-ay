variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type = string
}

variable "vpc_configuration" {
  type = object({
    vpc_cidr = string
    public_subnets = list(string)
    private_subnets = list(string)
  })
}

variable "eks_configuration" {
  type = object({
    cluster_version = string
    cluster_zonal_shift_config = optional(bool, false)
    addons = map(object({
      version = optional(any, null)
      configuration_values = optional(any, {})
    }))
  })
}
