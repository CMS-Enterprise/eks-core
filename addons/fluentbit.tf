#Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "fluent-bit" {
  name              = local.fluentbit_log_name
  retention_in_days = var.fluentbit_log_retention
  kms_key_id        = var.fluentbit_log_encryption ? var.cloudwatch_kms_key_arn : null
  tags              = var.fluentbit_tags
}

resource "aws_cloudwatch_log_group" "fluent-bit-system" {
  count             = var.fluentbit_log_systemd ? 1 : 0
  name              = local.fluentbit_system_log_name
  retention_in_days = var.fluentbit_system_log_retention
  kms_key_id        = var.fluentbit_log_encryption ? var.cloudwatch_kms_key_arn : null
  tags              = var.fluentbit_tags
}

#Fluentbit HELM
resource "helm_release" "fluent-bit" {
  atomic           = true
  name             = "fluentbit"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-for-fluent-bit"
  version          = var.fluentbit_chart_version
  create_namespace = true
  namespace        = local.fluentbit_namespace

  values = [
    local.values
  ]

  set {
    name  = "clusterName"
    value = var.eks_cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = local.fluentbit_service_account_name
  }

  set{
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.fluentbit.arn
  }
}
