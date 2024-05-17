module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  cidr                                                       = local.vpc_cidr
  create_flow_log_cloudwatch_iam_role                        = false
  crete_flow_log_cloudwatch_log_group                        = true
  create_igw                                                 = true
  create_vpc                                                 = true
  default_network_acl_ingress                                = local.private_nacl_ingress_rules
  default_network_acl_name                                   = "${local.cluster_name}-private"
  default_network_acl_tags                                   = { Name = "${local.cluster_name}-private" }
  default_route_table_name                                   = "${local.cluster_name}-private"
  default_route_table_routes                                 = local.private_route_table_routes
  default_route_table_tags                                   = { Name = "${local.cluster_name}-private" }
  default_security_group_ingress                             = []
  default_security_group_name                                = "${local.cluster_name}-private"
  default_security_group_tags                                = { Name = "${local.cluster_name}-private" }
  default_vpc_name                                           = local.cluster_name
  default_vpc_tags                                           = { Name = local.cluster_name }
  enable_dns_hostnames                                       = true
  enable_dns_support                                         = true
  enable_flow_log                                            = true
  enable_nat_gateway                                         = true
  flow_log_cloudwatch_iam_role_arn                           = aws_iam_role.vpc.arn
  flow_log_cloudwatch_log_group_class                        = "STANDARD"
  flow_log_cloudwatch_log_group_kms_key_id                   = aws_kms_key.cloudwatch.arn
  flow_log_cloudwatch_log_group_retention_in_days            = 365
  flow_log_cloudwatch_log_group_skip_destroy                 = false
  flow_log_destination_arn                                   = module.s3_logs.s3_bucket_arn
  flow_log_destination_type                                  = "s3"
  flow_log_file_format                                       = "plain-text"
  flow_log_traffic_type                                      = "ALL"
  igw_tags                                                   = { Name = "${local.cluster_name}-igw" }
  manage_default_network_acl                                 = true
  manage_default_route_table                                 = true
  manage_default_security_group                              = true
  manage_default_vpc                                         = true
  name                                                       = local.cluster_name
  nat_eip_tags                                               = { Name = "${local.cluster_name}-nat-eip" }
  nat_gateway_tags                                           = { Name = "${local.cluster_name}-ngw" }
  private_acl_tags                                           = { Name = "${local.cluster_name}-private" }
  private_dedicated_network_acl                              = true
  private_inbound_acl_rules                                  = local.private_nacl_ingress_rules
  private_route_table_tags                                   = { Name = "${local.cluster_name}-private" }
  private_subnet_enable_resource_name_dns_a_record_on_launch = true
  private_subnet_private_dns_hostname_type_on_launch         = "ip-name"
  private_subnet_tags                                        = { Name = "${local.cluster_name}-private" }
  private_subnets                                            = local.private_subnets
  public_acl_tags                                            = { Name = "${local.cluster_name}-public" }
  public_dedicated_network_acl                               = true
  public_inbound_acl_rules                                   = local.public_nacl_ingress_rules
  public_route_table_tags                                    = { Name = "${local.cluster_name}-public" }
  public_subnet_enable_resource_name_dns_a_record_on_launch  = true
  public_subnet_private_dns_hostname_type_on_launch          = "ip-name"
  public_subnet_tags                                         = { Name = "${local.cluster_name}-public" }
  public_subnets                                             = local.public_subnets
  single_nat_gateway                                         = true
  tags                                                       = { Cluster = local.cluster_name }
  vpc_flow_log_tags                                          = { Name = "${local.cluster_name}-flow-log" }
  vpc_tags                                                   = { Name = local.cluster_name }
}

module "vpc_vpc-endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules"
  version = "5.8.1"

  create                     = true
  create_security_group      = true
  endpoints                  = local.endpoints
  security_group_description = "Allow traffic to VPC endpoints"
  security_group_name        = "${local.cluster_name}-vpce"
  security_group_rules       = local.endpoint_sg_rules
  security_group_tags        = { Name = "${local.cluster_name}-vpce" }
  subnet_ids                 = module.vpc.private_subnets
  tags                       = { Name = "${local.cluster_name}-vpce" }
  vpc_id                     = module.vpc.vpc_id
}
