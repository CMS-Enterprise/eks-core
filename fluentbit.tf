#Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "fluent-bit" {
  name              = var.fb_log_group_name
  retention_in_days = var.fb_log_retention
  kms_key_id        = var.fb_log_encryption ? var.fb_kms_key_id : ""
  tags              = var.fb_tags
}

resource "aws_cloudwatch_log_group" "fluent-bit-system" {
  count             = var.fb_log_systemd ? 1 : 0
  name              = var.fb_system_log_group_name
  retention_in_days = var.fb_system_log_retention
  kms_key_id        = var.fb_log_encryption ? var.fb_kms_key_id : ""
  tags              = var.fb_tags
}

#Fluentbit HELM
resource "helm_release" "fluent-bit" {
  depends_on = [module.eks, module.main_nodes, module.eks_base]
  name       = "${local.cluster_name}-fluenbit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = var.fb_chart_verison
  namespace  = "kube-system"

  values = [
    local.values
  ]

  set {
    name  = "clusterName"
    value = local.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "fluent-bit"
  }

}
