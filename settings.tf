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

  cluster_name                  = var.cluster_custom_name == "" ? "main-test" : var.cluster_custom_name
  cluster_version               = var.eks_version

  ################################## VPC Settings ##################################
  vpc_cidr        = "10.10.0.0/16"
  private_subnets = ["10.10.15.0/24", "10.10.25.0/24", "10.10.35.0/24"]
  public_subnets  = ["10.10.10.0/24"]

  endpoints = {
    s3 = {
      service = "s3"
      tags    = { Name = "S3" }
    }
    ssm = {
      service = "ssm"
      tags    = { Name = "SSM" }
    }
    ssm-messages = {
      service = "ssmmessages"
      tags    = { Name = "SSM Messages" }
    }
    ec2-messages = {
      service = "ec2messages"
      tags    = { Name = "EC2 Messages" }
    }
  }

  ################################## Route Settings ##################################
  public_route_table_routes = [
    for subnet_cidr in module.vpc.public_subnets_cidr_blocks : {
      cidr_block = subnet_cidr,
      gateway_id = module.vpc.igw_id
    }
  ]
  private_route_table_routes = [
    for subnet_cidr in module.vpc.private_subnets_cidr_blocks : {
      cidr_block = subnet_cidr,
      gateway_id = module.vpc.natgw_ids[0]
    }
  ]

  ################################## NACL Settings ##################################
  public_nacl_ingress_rules = [
    { rule_number = 100, from_port = 53, to_port = 53, protocol = "udp", cidr_block = local.vpc_cidr, rule_action = "allow" },
    { rule_number = 101, from_port = 80, to_port = 80, protocol = "tcp", cidr_block = "0.0.0.0/0", rule_action = "allow" },
    { rule_number = 102, from_port = 443, to_port = 443, protocol = "tcp", cidr_block = "0.0.0.0/0", rule_action = "allow" },
    { rule_number = 103, from_port = 1024, to_port = 65535, protocol = "tcp", cidr_block = "0.0.0.0/0", rule_action = "allow" },
    { rule_number = 104, from_port = 22, to_port = 22, protocol = "tcp", cidr_block = "0.0.0.0/0", rule_action = "deny" },
    { rule_number = 105, from_port = 3389, to_port = 3389, protocol = "tcp", cidr_block = "0.0.0.0/0", rule_action = "deny" }
  ]
  private_nacl_ingress_rules = [
    { rule_number = 100, from_port = 22, to_port = 22, protocol = "tcp", cidr_block = local.vpc_cidr, rule_action = "allow" },
    { rule_number = 101, from_port = 53, to_port = 53, protocol = "tcp", cidr_block = local.vpc_cidr, rule_action = "allow" },
    { rule_number = 102, from_port = 53, to_port = 53, protocol = "udp", cidr_block = local.vpc_cidr, rule_action = "allow" },
    { rule_number = 103, from_port = 80, to_port = 80, protocol = "tcp", cidr_block = local.vpc_cidr, rule_action = "allow" },
    { rule_number = 104, from_port = 443, to_port = 443, protocol = "tcp", cidr_block = local.vpc_cidr, rule_action = "allow" },
    { rule_number = 105, from_port = 1024, to_port = 65535, protocol = "tcp", cidr_block = "0.0.0.0/0", rule_action = "allow" },
    { rule_number = 106, from_port = 1024, to_port = 65535, protocol = "udp", cidr_block = "0.0.0.0/0", rule_action = "allow" }
  ]

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