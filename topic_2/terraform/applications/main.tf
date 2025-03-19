resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
  }
  parameters = {
    fsType    = "ext4"
    type      = "gp3"
    encrypted = "true"
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
}

resource "kubernetes_storage_class_v1" "gp3_retain" {
  metadata {
    name = "gp3-retain"
  }
  parameters = {
    fsType    = "ext4"
    type      = "gp3"
    encrypted = "true"
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}

resource "kubernetes_namespace_v1" "asiayo" {
  metadata {
    name = "asiayo"
  }
}

locals {
  frontend_mainfast = [
    "deployment",
    "hpa",
    "pvc",
    "service",
    "ingress",
  ]
  database_init_mainfast = [
    "wp-secret",
    "init-job",
  ]
}

resource "kubernetes_manifest" "frontend" {
  for_each = toset(local.frontend_mainfast)
  manifest = yamldecode(file("./manifests/frontend/${each.value}.yaml"))

  depends_on = [
    kubernetes_namespace_v1.asiayo,
    kubernetes_storage_class_v1.gp3,
    kubernetes_manifest.database_init,
  ]
}

resource "helm_release" "mysql_operator" {
  name       = "mysql-operator"
  namespace  = "asiayo"
  repository = "https://mysql.github.io/mysql-operator/"
  chart      = "mysql-operator"
  version    = "2.2.3"
}

resource "random_password" "mysql_password" {
  length  = 16
  special = false
}

resource "helm_release" "mysql" {
  name       = "mysql"
  namespace  = "asiayo"
  repository = "https://mysql.github.io/mysql-operator/"
  chart      = "mysql-innodbcluster"
  version    = "2.2.3"
  values = [
    templatefile("./values/mysql.yaml", {
      mysql_root_password = random_password.mysql_password.result,
      server_instances    = var.mysql_configuration.server_instances,
      router_instances    = var.mysql_configuration.router_instances,
    }),
  ]
  depends_on = [helm_release.mysql_operator]
}

resource "kubernetes_manifest" "database_init" {
  for_each = toset(local.database_init_mainfast)
  manifest = yamldecode(file("./manifests/database/${each.value}.yaml"))
  depends_on = [
    kubernetes_namespace_v1.asiayo,
    kubernetes_storage_class_v1.gp3_retain,
    helm_release.mysql,
  ]
}
