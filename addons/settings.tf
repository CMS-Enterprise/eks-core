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

  user_data = {
    cluster_auth_base64        = base64encode(var.cluster_ca_data)
    cluster_endpoint           = var.cluster_endpoint
    cluster_cidr               = var.eks_cluster_cidr
    cluster_ip_family          = var.eks_cluster_ip_family
    cluster_name               = var.eks_cluster_name
    enable_bootstrap_user_data = var.enable_bootstrap_user_data
    pre_bootstrap_user_data    = var.pre_bootstrap_user_data
    post_bootstrap_user_data   = var.post_bootstrap_user_data
    bootstrap_extra_args       = var.bootstrap_extra_args
  }

  kp_config_settings = {
    cluster_name = var.eks_cluster_name
  }

  kpn_config_settings = {
    amiFamily       = var.bottlerocket_enabled ? "Bottlerocket" : (var.gold_image_ami_id != "" ? "Custom" : "AL2")
    amiID           = var.gold_image_ami_id != "" ? var.gold_image_ami_id : var.custom_ami
    iamRole         = var.eks_launch_template_name
    subnetTag       = "${var.deploy_project}-*-${var.deploy_env}-private-*"
    tags            = yamlencode(var.karpenter_base_tags)
    bottlerocket    = var.bottlerocket_enabled
    securityGroupID = var.eks_node_security_group_id
    userData        = templatefile("${path.module}/linux_bootstrap.tpl", local.user_data)
  }

  kp_values  = templatefile("${path.module}/values/karpenter/values.yaml.tpl", local.kp_config_settings)
  kpn_values = templatefile("${path.module}/values/karpenter-nodes/values.yaml.tpl", local.kpn_config_settings)
}