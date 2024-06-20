data "aws_vpc" "vpc" {
  tags = {
    Name = coalesce(var.vpc_lookup_override, "${var.project}-*-${var.env}")
  }
}

# all subnets
data "aws_subnets" "all_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

# public subnets
data "aws_subnets" "public" {
  filter {
    name = "tag:Name"
    values = [
      try(var.subnet_lookup_overrides.private, "${var.project}-*-${var.env}-public-*")
    ]
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

data "aws_subnets" "container" {
  filter {
    name = "tag:Name"
    values = [
      try(var.subnet_lookup_overrides.private, "${var.project}-*-${var.env}-unroutable-*")
    ]
  }
}

data "aws_subnet" "container" {
  for_each = toset(local.all_container_subnet_ids)
  id       = each.key
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

# data "aws_ec2_managed_prefix_list" "cmscloud_public_pl" {
#   name = "cmscloud-public"
# }

data "aws_ec2_managed_prefix_list" "zscaler_pl" {
  name = "zscaler"
}

#non-prod route table
data "aws_route_table" "all_private_route_tables" {
  for_each  = toset(local.all_private_subnet_ids)
  subnet_id = each.key
}

# Creating subnet tags for load balancer controller
resource "aws_ec2_tag" "elb_controller" {
  for_each    = toset(data.aws_subnets.public.ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "internal_elb_controller" {
  for_each    = toset(data.aws_subnets.private.ids)
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "all_subnets" {
  for_each    = toset(data.aws_subnets.all_subnets.ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.cluster_name}"
  value       = "shared"
}
