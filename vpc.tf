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
  name  = "cmscloud-public"
}

data "aws_ec2_managed_prefix_list" "zscaler_pl" {
  name  = "zscaler"

}

#non-prod route table
data "aws_route_table" "all_private_route_tables" {
  for_each  = toset(local.all_private_subnet_ids)
  subnet_id = each.key
}

resource "aws_vpc_endpoint" "s3" {
  count = var.create_s3_vpc_endpoint ? 1 : 0

  vpc_id          = data.aws_vpc.vpc.id
  service_name    = "com.amazonaws.${data.aws_region.current.name}.s3"
  route_table_ids = [for route_table in data.aws_route_table.all_private_route_tables : route_table.id]

  tags = {
    Name = coalesce(var.vpc_endpoint_lookup_overrides, "${var.project}-${var.env}-s3-endpoint")
  }
}
