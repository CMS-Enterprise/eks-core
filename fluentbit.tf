#Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "fluent-bit" {
  name              = local.fluentbit_log_name
  retention_in_days = var.fb_log_retention
  kms_key_id        = var.fb_log_encryption ? module.cloudwatch_kms.key_arn : null
  tags              = var.fb_tags
}

resource "aws_cloudwatch_log_group" "fluent-bit-system" {
  count             = var.fb_log_systemd ? 1 : 0
  name              = local.fluentbit_system_log_name
  retention_in_days = var.fb_system_log_retention
  kms_key_id        = var.fb_log_encryption ? module.cloudwatch_kms.key_arn : null
  tags              = var.fb_tags
}


resource "helm_release" "aws_for_fluentbit" {
  name       = "aws-for-fluentbit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  # version    = "0.1.0"  # replace with the desired version

  values = [
    <<EOF
cloudWatchLogs:
  enabled: true
  match: "*"
  region: "us-east-1"
  logGroupName: "hema-ami-fluent-bit"
cloudWatch:
  enabled: false
  match: "*"
  region: "us-east-1"
  logGroupName: "hema-ami-fluent-bit"
EOF
  ]

  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "fluentbit"
  }

}
