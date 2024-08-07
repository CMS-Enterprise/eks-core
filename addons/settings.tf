locals {
  ################################## ArgoCD Settings ##################################
  argocd_sub_domain = var.is_prod_cluster ? "argocd" : "argocd-${var.eks_cluster_name}"
  argo_values_file  = "${path.module}/values/argocd/values.yaml.tpl"


  argocd_values = templatefile(local.argo_values_file, {
    alb_security_group_id = var.alb_security_group_id
    argocd_cert_arn       = data.aws_acm_certificate.argocd.arn
    argocd_sub_domain     = local.argocd_sub_domain
    cluster_name          = var.eks_cluster_name
    domain_name           = var.domain_name
    k8s_alb_name          = var.k8s_alb_name
    s3_logging_bucket     = data.aws_s3_bucket.logging.bucket
    argocd_use_sso        = var.argocd_use_sso
    okta_client_id        = var.okta_client_id
    okta_client_secret    = var.okta_client_secret
    okta_issuer           = var.okta_issuer
  })

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

  kp_values                 = templatefile("${path.module}/values/karpenter/values.yaml.tpl", local.kp_config_settings)
  iam_instance_profile_name = tolist(data.aws_iam_instance_profiles.nodes.names)

  kpnp_config_settings = {
    name                         = var.karpenter_nodepool_name == "" ? "default" : var.karpenter_nodepool_name
    ec2nodeclass_name            = var.karpenter_ec2nodeclass_name == "" ? "default" : var.karpenter_ec2nodeclass_name
    available_availability_zones = var.available_availability_zones
    karpenter_nodepool_taints    = var.karpenter_nodepool_taints
  }

  karpenter_node_pool_values = templatefile("${path.module}/values/karpenter/karpenter-node-pool-values.yaml.tpl", local.kpnp_config_settings)

  karpenter_nodeclass_tags = merge(var.karpenter_base_tags, { Name = "eks-karpenter-${var.eks_cluster_name}" })
  kpnc_config_settings = {
    name                = var.karpenter_ec2nodeclass_name == "" ? "default" : var.karpenter_ec2nodeclass_name
    amiFamily           = var.gold_image_ami_id != "" ? "Custom" : "AL2"
    deviceName          = "/dev/xvda"
    volumeSize          = "300G"
    volumeType          = "gp3"
    deleteOnTermination = true
    encrypted           = true
    ebs_kms_key_id      = var.ebs_kms_key_id
    instanceProfile     = local.iam_instance_profile_name[0]
    amiSelectorId       = var.gold_image_ami_id != "" ? var.gold_image_ami_id : var.custom_ami
    subnetTag           = "${var.ado}-*-${var.env}-private-*"
    securityGroupID     = var.eks_node_security_group_id
    userData            = templatefile("${path.module}/linux_bootstrap.tpl", local.user_data)

    tags = local.karpenter_nodeclass_tags

  }

  karpenter_node_class_values = templatefile("${path.module}/values/karpenter/karpenter-node-class-values.yaml.tpl", local.kpnc_config_settings)

}

data "aws_iam_instance_profiles" "nodes" {
  role_name = var.eks_node_iam_role_name
}

data "aws_acm_certificate" "argocd" {
  domain   = var.domain_name
  statuses = ["ISSUED"]
}

data "aws_s3_bucket" "logging" {
  bucket = "cms-cloud-${var.account_num}-${var.region_name}"
}
