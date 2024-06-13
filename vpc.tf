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
