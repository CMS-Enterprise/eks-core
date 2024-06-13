# vpc id
data "aws_vpc" "vpc" {
  tags = {
    Name = coalesce(var.vpc_lookup_override, "${var.project}-*-${var.env}")
  }
}

# private subnets
data "aws_subnets" "private" {
  filter {
    name = "tag:Name"
    values = [
      try(var.subnet_lookup_overrides.private, "${var.project}-*-${var.env}-private-*")
    ]
  }
}

# container subnets
data "aws_subnets" "container" {
  filter {
    name = "tag:Name"
    values = [
      try(var.subnet_lookup_overrides.container, "${var.project}-*-${var.env}-unroutable-*")
    ]
  }
}

data "aws_ec2_managed_prefix_list" "vpn_prefix_list" {
  name = "cmscloud-vpn"
}

data "aws_ec2_managed_prefix_list" "cmscloud_shared_services_pl" {
  name = "cmscloud-shared-services"
}

data "aws_ec2_managed_prefix_list" "cmscloud_security_tools" {
  name = "cmscloud-security-tools"
}

data "aws_ec2_managed_prefix_list" "cmscloud_public_pl" {
  name = "cmscloud-public"
}

data "aws_ec2_managed_prefix_list" "zscaler_pl" {
  name = "zscaler"
}

#non-prod route table
data "aws_route_table" "all_private_route_tables" {
  for_each  = toset(local.all_private_subnet_ids)
  subnet_id = each.key
}

# Endpoints are required for Karpenter to work properly since it is deployed to a private cluster
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  security_group_ids  = [for key, value in local.cluster_security_groups : value]
  subnet_ids          = local.all_private_subnet_ids
  vpc_endpoint_type   = "Interface"

  tags = {
    Name = coalesce(var.vpc_endpoint_lookup_overrides, "${module.eks.cluster_name}-ec2-endpoint")
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  security_group_ids  = [for key, value in local.cluster_security_groups : value]
  subnet_ids          = local.all_private_subnet_ids
  vpc_endpoint_type   = "Interface"

  tags = {
    Name = coalesce(var.vpc_endpoint_lookup_overrides, "${module.eks.cluster_name}-ecr-endpoint")
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  security_group_ids  = [for key, value in local.cluster_security_groups : value]
  subnet_ids          = local.all_private_subnet_ids
  vpc_endpoint_type   = "Interface"

  tags = {
    Name = coalesce(var.vpc_endpoint_lookup_overrides, "${module.eks.cluster_name}-ecr-dkr-endpoint")
  }
}

resource "aws_vpc_endpoint" "eks" {
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.eks"
  security_group_ids  = [for key, value in local.cluster_security_groups : value]
  subnet_ids          = local.all_private_subnet_ids
  vpc_endpoint_type   = "Interface"

  tags = {
    Name = coalesce(var.vpc_endpoint_lookup_overrides, "${module.eks.cluster_name}-eks-endpoint")
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.s3"
  security_group_ids  = [for key, value in local.cluster_security_groups : value]
  subnet_ids          = local.all_private_subnet_ids
  vpc_endpoint_type   = "Interface"

  tags = {
    Name = coalesce(var.vpc_endpoint_lookup_overrides, "${module.eks.cluster_name}-s3-endpoint")
  }
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  security_group_ids  = [for key, value in local.cluster_security_groups : value]
  subnet_ids          = local.all_private_subnet_ids
  vpc_endpoint_type   = "Interface"

  tags = {
    Name = coalesce(var.vpc_endpoint_lookup_overrides, "${module.eks.cluster_name}-sts-endpoint")
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  security_group_ids  = [for key, value in local.cluster_security_groups : value]
  subnet_ids          = local.all_private_subnet_ids
  vpc_endpoint_type   = "Interface"

  tags = {
    Name = coalesce(var.vpc_endpoint_lookup_overrides, "${module.eks.cluster_name}-ssm-endpoint")
  }
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sqs"
  security_group_ids  = [for key, value in local.cluster_security_groups : value]
  subnet_ids          = local.all_private_subnet_ids
  vpc_endpoint_type   = "Interface"

  tags = {
    Name = coalesce(var.vpc_endpoint_lookup_overrides, "${module.eks.cluster_name}-sqs-endpoint")
  }
}
