locals {
  ################################## EKS Settings ##################################
  cluster_bottlerocket_user_data = templatefile("${path.module}/utils/bottlerocket_config.toml.tpl",
    {
      cluster_name     = module.eks.cluster_name
      cluster_endpoint = module.eks.cluster_endpoint
      cluster_ca_data  = module.eks.cluster_certificate_authority_data
      node_labels      = join("\n", [for label, value in var.node_labels : "\"${label}\" = \"${value}\""])
      node_taints      = join("\n", [for taint, value in var.node_taints : "\"${taint}\" = \"${value}\""])
    }
  )

  cluster_name    = var.cluster_custom_name == "" ? "main-test" : var.cluster_custom_name
  cluster_version = var.eks_version

  ################################## Fluentbit Settings ##################################
  config_settings = {
    log_group_name         = var.fb_log_group_name
    system_log_group_name  = var.system_log_group_name == "" ? "${local.log_group_name}-kube" : "${var.system_log_group_name}"
    region                 = var.region
    log_retention_days     = var.fb_log_retention_days
    drop_namespaces        = "(${join("|", var.drop_namespaces)})"
    log_filters            = "(${join("|", var.log_filters)})"
    additional_log_filters = "(${join("|", var.additional_log_filters)})"
    kube_namespaces        = var.kube_namespaces
  }

  values = templatefile("${path.module}/helm/fluenbit/values.yaml.tpl", local.config_settings)

  ################################## Karpenter Settings ##################################
  kp_config_settings = {
    cluster_name = local.cluster_name
  }

  kpn_config_settings = {
    amiFamily       = var.custom_ami_id != "" ? var.custom_ami_id : "BOTTLEROCKET_x86_64"
    iamRole         = module.eks.cluster_iam_role_arn
    subnetTag       = "${var.project}-*-${var.env}-private-*"
    tags            = var.karpenter_tags
    securityGroupID = module.eks.node_security_group_id
  }

  kp_values  = templatefile("${path.module}/helm/karpenter/values.yaml.tpl", local.kp_config_settings)
  kpn_values = templatefile("${path.module}/helm/karpenter/values.yaml.tpl", local.kpn_config_settings)

  ################################## VPC Settings ##################################
  all_non_public_subnets = merge({
    "private"   = data.aws_subnet.private
    "container" = data.aws_subnet.container
    },
  )

  all_non_public_subnet_ids = flatten([for subnet_group in local.all_non_public_subnets : [for subnet in subnet_group : subnet.id]])

  ################################## Security Group Settings ##################################
  eks_local = [
    { description = "Allow all traffic from orchestrator nodes", from_port = 0, to_port = 0, protocol = "-1", self = true },
    { description = "Allow instances required to reach to the API server", from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = [local.vpc_cidr] },
    { description = "Allow necessary Kubelet and node communications", from_port = 10250, to_port = 10250, protocol = "tcp", cidr_blocks = [local.vpc_cidr] },
    { description = "Allow LB communication", from_port = 3000, to_port = 31237, protocol = "tcp", cidr_blocks = [local.vpc_cidr] }
  ]

  ################################## Misc Config ##################################
  asg_names = module.main_nodes.node_group_autoscaling_group_names
  asg_arns  = [for name in local.asg_names : "arn:aws:autoscaling:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:autoScalingGroupName/${name}"]
}

resource "random_string" "s3" {
  length  = 12
  upper   = false
  special = false
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_roles" "all_roles" {}

data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name
}

data "aws_availability_zones" "available" {}

data "aws_iam_policy" "permissions_boundary" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/cms-cloud-admin/developer-boundary-policy"
}

data "aws_eks_addon_version" "guardduty" {
  addon_name         = "aws-guardduty-agent"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

data "aws_ami" "al2" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}
