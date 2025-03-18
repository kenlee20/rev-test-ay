locals {
  eks = {
    name = var.project
    ca_certificate = module.eks.cluster_certificate_authority_data
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name    = var.project
  cluster_version = var.eks_configuration.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_zonal_shift_config = {
    enabled = var.eks_configuration.cluster_zonal_shift_config
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.project
  }

  fargate_profiles = {
    karpenter_fargate = {
      iam_role_name = "${var.project}-karpenter-fargate"
      iam_role_path = "/${var.project}/"
      selectors = [{
        namespace = "karpenter"
      }]
    }
  }

  cluster_endpoint_public_access           = false
  enable_cluster_creator_admin_permissions = true
}

resource "aws_eks_addon" "addons" {
  for_each                    = var.eks_configuration.addons
  cluster_name                = module.eks.cluster_name
  addon_name                  = each.key
  addon_version               = data.aws_eks_addon_version.this[each.key].version
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = each.value.create_irsa ? module.addons_irsa_role[each.key].iam_role_arn : null
  configuration_values        = jsonencode(each.value.configuration_values)
}

module "addons_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.52.2"

  for_each = {
    for key, value in var.var.eks_configuration.addons : key => value
    if value.create_irsa
  }
  role_name = "${var.project}-${each.key}"
  role_path = "/internal-service/"

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

resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.11.0"

  values = [
    templatefile("./values/aws_load_balancer_controller.yaml", {
      cluster_name                          = local.eks.name
      region                                = var.region
      vpc_id                                = local.vpc.id
      aws_load_balancer_controller_role_arn = module.eks_irsa_role["aws_load_balancer_controller"].iam_role_arn
    })
  ]
}
