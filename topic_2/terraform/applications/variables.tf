variable "project" {
  type = string
  default = "eks-lab"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "mysql_configuration" {
  type = object({
    server_instances = number
    router_instances = number
  })
}

