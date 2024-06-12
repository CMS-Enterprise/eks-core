#Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "fluent-bit" {
  name              = "${local.fluentbit_log_name}-${module.eks.cluster_name}"
  retention_in_days = var.fb_log_retention
  kms_key_id        = var.fb_log_encryption ? module.cloudwatch_kms.key_arn : null
  tags              = var.fb_tags
}

resource "aws_cloudwatch_log_group" "fluent-bit-system" {
  count             = var.fb_log_systemd ? 1 : 0
  name              = "${local.fluentbit_system_log_name}-${module.eks.cluster_name}"
  retention_in_days = var.fb_system_log_retention
  kms_key_id        = var.fb_log_encryption ? module.cloudwatch_kms.key_arn : null
  tags              = var.fb_tags
}

#Fluentbit HELM
resource "helm_release" "fluent-bit" {
  depends_on = [module.eks, module.main_nodes, module.eks_base]
  atomic     = true
  name       = "fluentbit"
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
    value = local.fluentbit_service_account_name
  }
}
