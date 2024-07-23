locals {
  ################################## Karpenter Settings ##################################
  karpenter_namespace            = "karpenter"
  karpenter_service_account_name = "karpenter"

  user_data = {
    cluster_auth_base64        = var.cluster_ca_data
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

  kp_values  = templatefile("${path.module}/values/karpenter/values.yaml.tpl", local.kp_config_settings)
  iam_instance_profile_name = tolist(data.aws_iam_instance_profiles.nodes.names)
}

data "aws_iam_instance_profiles" "nodes" {
  role_name = var.eks_node_iam_role_name
}