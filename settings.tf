locals {

  tags_for_all_resources = {
    programOffice = var.program_office
    ado           = var.ado
    env           = var.env
  }

  ################################## EKS Settings ##################################
  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = "300"
        volume_type           = "gp3"
        delete_on_termination = true
        encrypted             = true
      }
    }
  ]

  enable_bootstrap_user_data = var.gold_image_date != "" ? true : false
  post_bootstrap_user_data   = var.node_post_bootstrap_script
  pre_bootstrap_user_data    = var.gold_image_date != "" ? local.gold_image_pre_bootstrap_script : var.node_pre_bootstrap_script

  cluster_name = var.cluster_custom_name
  cluster_security_groups = {
    node            = module.eks.node_security_group_id
    cluster         = module.eks.cluster_security_group_id
    cluster_primary = module.eks.cluster_primary_security_group_id
  }
  cluster_security_group_prefix_list_ids = [
    data.aws_ec2_managed_prefix_list.vpn_prefix_list.id,
    data.aws_ec2_managed_prefix_list.cmscloud_shared_services_pl.id,
    data.aws_ec2_managed_prefix_list.cmscloud_security_tools.id,
    #     data.aws_ec2_managed_prefix_list.cmscloud_public_pl.id,
    data.aws_ec2_managed_prefix_list.zscaler_pl.id
  ]
  cluster_version                 = var.eks_version
  gold_image_pre_bootstrap_script = "mkdir -p /var/log/journal && sysctl -w net.ipv4.ip_forward=1\n"
  k8s_alb_name                    = "alb-${local.cluster_name}"

  ################################### ALB ###################################
  alb_security_group_rules = {
    ingress_80 = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress_443 = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_all = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ################################## VPC Settings ##################################
  all_private_subnet_ids   = flatten([for subnet in data.aws_subnets.private.ids : subnet])
  all_container_subnet_ids = flatten([for subnet in data.aws_subnets.container.ids : subnet])

  ################################## Security Group Settings ##################################
  eks_local = [
    { description = "Allow all traffic from orchestrator nodes", from_port = 0, to_port = 0, protocol = "-1", self = true },
    { description = "Allow instances required to reach to the API server", from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = [data.aws_vpc.vpc.cidr_block] },
    { description = "Allow necessary Kubelet and node communications", from_port = 10250, to_port = 10250, protocol = "tcp", cidr_blocks = [data.aws_vpc.vpc.cidr_block] },
    { description = "Allow LB communication", from_port = 3000, to_port = 31237, protocol = "tcp", cidr_blocks = [data.aws_vpc.vpc.cidr_block] }
  ]

  ################################## Misc Config ##################################
  ami_id                            = var.gold_image_date != "" ? data.aws_ami.gold_image[0].id : var.custom_ami_id
  available_availability_zone_names = [for az in data.aws_availability_zones.available.names : az]
  iam_path                          = "/delegatedadmin/developer/"
  kubeconfig_path                   = "${path.module}/kubeconfig"
  permissions_boundary_arn          = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/cms-cloud-admin/ct-ado-poweruser-permissions-boundary-policy"
  role_arn                          = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.role_name}"
  role_name                         = regex("arn:aws:sts::[0-9]+:assumed-role/([^/]+)/.*", data.aws_caller_identity.current.arn)[0]
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_iam_roles" "all_roles" {}

data "aws_availability_zones" "available" {}

data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name
}

data "aws_lb" "k8s_alb" {
  name       = local.k8s_alb_name
  depends_on = [module.eks_addons.argocd_helm_status]
}

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = true
}

data "aws_ami" "gold_image" {
  count = var.gold_image_date != "" ? 1 : 0

  most_recent = true
  name_regex  = "^amzn2-eks-${module.eks.cluster_version}-gi-${var.gold_image_date}*"
  owners      = ["743302140042"]
}

data "aws_s3_bucket" "logs" {
  bucket = "cms-cloud-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

data "aws_eks_addon_version" "aws-ebs-csi-driver" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "aws-efs-csi-driver" {
  addon_name         = "aws-efs-csi-driver"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "eks-pod-identity-agent" {
  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "kube-proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "vpc-cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "aws_cloudwatch_observability" {
  addon_name         = "amazon-cloudwatch-observability"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}
