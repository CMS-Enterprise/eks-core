locals {
  ################################## Fluentbit Settings ##################################
  fluentbit_log_name             = "${var.eks_cluster_name}-fluent-bit"
  fluentbit_namespace            = "fluentbit"
  fluentbit_service_account_name = "fluent-bit"
  fluentbit_system_log_name      = "${var.eks_cluster_name}-fluent-bit-systemd"

  config_settings = {
    log_group_name         = local.fluentbit_log_name
    system_log_group_name  = local.fluentbit_system_log_name
    region                 = var.aws_region
    log_retention_days     = var.fluentbit_log_retention
    drop_namespaces        = "(${join("|", var.fluentbit_drop_namespaces)})"
    log_filters            = "(${join("|", var.fluentbit_log_filters)})"
    additional_log_filters = "(${join("|", var.fluentbit_additional_log_filters)})"
    kube_namespaces        = var.fluentbit_kube_namespaces
  }

  values = templatefile("${path.module}/values/fluentbit/values.yaml.tpl", local.config_settings)

  ################################## Karpenter Settings ##################################
  karpenter_namespace            = "karpenter"
  karpenter_service_account_name = "karpenter"

  kp_config_settings = {
    cluster_name = var.eks_cluster_name
  }

  kpn_config_settings = {
    amiFamily       = var.bottlerocket_enabled ? "Bottlerocket" : (var.gold_image_ami_id != "" ? "Custom" : "AL2")
    amiID           = var.gold_image_ami_id != "" ? var.gold_image_ami_id : var.custom_ami
    iamRole         = var.main_nodes_iam_role_arn
    subnetTag       = "${var.deploy_project}-*-${var.deploy_env}-private-*"
    tags            = yamlencode(var.karpenter_base_tags)
    bottlerocket    = var.bottlerocket_enabled
    securityGroupID = var.eks_node_security_group_id
  }

  kp_values  = templatefile("${path.module}/values/karpenter/values.yaml.tpl", local.kp_config_settings)
  kpn_values = templatefile("${path.module}/values/karpenter-nodes/values.yaml.tpl", local.kpn_config_settings)
}