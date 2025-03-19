module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name    = var.project
  cluster_version = var.eks_configuration.cluster_version

  vpc_id                   = module.vpc.vpc_id
  control_plane_subnet_ids = module.vpc.intra_subnets

  cluster_zonal_shift_config = {
    enabled = var.eks_configuration.cluster_zonal_shift_config
  }

  cluster_addons = {
    for name, config in var.eks_addons_configuration : name => {
      addon_name                  = name
      addon_version               = try(config.addon_version, null)
      resolve_conflicts_on_update = try(config.resolve_conflicts, null)
      service_account_role_arn    = config.create_irsa ? module.addons_irsa_role[name].iam_role_arn : null
      configuration_values        = try(jsonencode(config.configuration_values), null)
    }
  }

  eks_managed_node_groups = {
    for name, config in var.eks_configuration.node_group : name => {
      name                = name
      ami_type            = config.ami_type
      ami_release_version = config.ami_release_version
      instance_types      = config.instance_types
      min_size            = config.min_size
      max_size            = config.max_size
      desired_size        = config.min_size
      subnet_ids          = local.vpc[config.subnet_alias]
      taints              = config.taints
    }
  }

  cluster_endpoint_public_access           = true # 方便部署所以設置於public
  enable_cluster_creator_admin_permissions = true
  depends_on                               = [module.vpc]
}

# Addons IRSA

module "addons_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.52.2"

  for_each = {
    for key, value in var.eks_addons_configuration : key => value
    if value.create_irsa
  }
  role_name = "${var.project}-${each.key}"

  attach_vpc_cni_policy = try(each.value.attach_policy.attach_vpc_cni_policy, false)
  vpc_cni_enable_ipv4   = try(each.value.attach_policy.vpc_cni_enable_ipv4, false)
  attach_ebs_csi_policy = try(each.value.attach_policy.attach_ebs_csi_policy, false)

  role_policy_arns = try(each.value.role_policy_arns, {})

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = try(each.value.namespace_service_accounts, null)
    }
  }
}

# Custom Component and IRSA

locals {
  eks_irsa = {
    aws_load_balancer_controller = {
      attach_load_balancer_controller_policy = true
      namespace_service_accounts             = ["kube-system:aws-load-balancer-controller"]
    }
    cluster_autoscaler = {
      attach_cluster_autoscaler_policy = true
      cluster_autoscaler_cluster_names = [var.project]
      namespace_service_accounts       = ["kube-system:aws-cluster-autoscaler"]
    }
  }
}

module "eks_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.52.0"

  for_each                                        = local.eks_irsa
  role_name                                       = try(each.value.role_name, "${var.project}-${replace(each.key, "_", "-")}")
  role_path                                       = try(each.value.role_path, "/")
  attach_velero_policy                            = try(each.value.attach_velero_policy, false)
  velero_s3_bucket_arns                           = try(each.value.velero_s3_bucket_arns, ["*"])
  attach_cluster_autoscaler_policy                = try(each.value.attach_cluster_autoscaler_policy, false)
  cluster_autoscaler_cluster_names                = try(each.value.cluster_autoscaler_cluster_names, [])
  attach_external_dns_policy                      = try(each.value.attach_external_dns_policy, false)
  attach_external_secrets_policy                  = try(each.value.attach_external_secrets_policy, false)
  external_secrets_secrets_manager_arns           = try(each.value.external_secrets_secrets_manager_arns, ["arn:aws:secretsmanager:*:*:secret:*"])
  attach_load_balancer_controller_policy          = try(each.value.attach_load_balancer_controller_policy, false)
  attach_amazon_managed_service_prometheus_policy = try(each.value.attach_amazon_managed_service_prometheus_policy, false)
  role_policy_arns                                = try(each.value.role_policy_arns, {})

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = try(each.value.namespace_service_accounts, [])
    }
  }
}

resource "helm_release" "cluster_autoscaler" {
  name       = "aws-cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = var.eks_additional_addons_configuration.cluster_autoscaler_version
  values = [
    templatefile("./values/cluster_autoscaler.yaml", {
      cluster_name = module.eks.cluster_name
      aws_region   = var.region
      iam_role_arn = module.eks_irsa_role["cluster_autoscaler"].iam_role_arn
    })
  ]
  depends_on = [module.eks]
}

resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.eks_additional_addons_configuration.aws_load_balancer_controller_version

  values = [
    templatefile("./values/aws_load_balancer_controller.yaml", {
      cluster_name = module.eks.cluster_name
      region       = var.region
      vpc_id       = module.vpc.vpc_id
      iam_role_arn = module.eks_irsa_role["aws_load_balancer_controller"].iam_role_arn
    })
  ]
  depends_on = [module.eks]
}

resource "helm_release" "metric_server" {
  name = "metric-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = var.eks_additional_addons_configuration.metric_server_version

}
