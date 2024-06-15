module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.11.0"

  access_entries                               = var.eks_access_entries
  authentication_mode                          = "API_AND_CONFIG_MAP"
  cloudwatch_log_group_class                   = "STANDARD"
  cloudwatch_log_group_kms_key_id              = module.cloudwatch_kms.key_arn
  cloudwatch_log_group_retention_in_days       = 365
  cluster_encryption_policy_path               = local.iam_path
  cluster_endpoint_private_access              = true
  cluster_endpoint_public_access               = false
  cluster_ip_family                            = "ipv4"
  cluster_name                                 = local.cluster_name
  cluster_security_group_name                  = "eks-${local.cluster_name}-cluster-sg"
  cluster_service_ipv4_cidr                    = "172.20.0.0/16"
  cluster_version                              = local.cluster_version
  control_plane_subnet_ids                     = local.all_private_subnet_ids
  create_cloudwatch_log_group                  = true
  create_cluster_primary_security_group_tags   = true
  create_cluster_security_group                = true
  create_iam_role                              = true
  create_kms_key                               = true
  create_node_security_group                   = true
  enable_cluster_creator_admin_permissions     = true
  enable_irsa                                  = true
  enable_kms_key_rotation                      = true
  iam_role_description                         = "IAM role for EKS cluster"
  iam_role_name                                = "eks-${local.cluster_name}"
  iam_role_path                                = local.iam_path
  iam_role_permissions_boundary                = local.permissions_boundary_arn
  iam_role_use_name_prefix                     = false
  kms_key_administrators                       = []
  kms_key_aliases                              = ["eks-${local.cluster_name}"]
  kms_key_deletion_window_in_days              = 7
  kms_key_description                          = "KMS key for EKS ${local.cluster_name} cluster"
  node_security_group_additional_rules         = var.eks_security_group_additional_rules
  node_security_group_description              = "Security group for EKS nodes"
  node_security_group_enable_recommended_rules = true
  node_security_group_name                     = "eks-${local.cluster_name}-node-sg"
  node_security_group_use_name_prefix          = false
  subnet_ids                                   = local.all_private_subnet_ids
  tags                                         = merge(var.eks_cluster_tags, { Name = local.cluster_name })
  vpc_id                                       = data.aws_vpc.vpc.id

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

module "main_nodes" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "20.2.1"

  name                              = "eks-main-${local.cluster_name}"
  cluster_auth_base64               = module.eks.cluster_certificate_authority_data
  cluster_endpoint                  = module.eks.cluster_endpoint
  cluster_ip_family                 = "ipv4"
  cluster_name                      = module.eks.cluster_name
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  cluster_service_ipv4_cidr         = module.eks.cluster_service_cidr
  cluster_version                   = module.eks.cluster_version

  create_iam_role               = true
  enable_bootstrap_user_data    = var.gold_image_date != "" ? true : false
  iam_role_additional_policies  = { ssm = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore" }
  iam_role_description          = "IAM role for EKS nodes for cluster ${local.cluster_name}"
  iam_role_name                 = "eks-nodes-${local.cluster_name}"
  iam_role_path                 = local.iam_path
  iam_role_permissions_boundary = local.permissions_boundary_arn
  subnet_ids                    = local.all_private_subnet_ids
  vpc_security_group_ids        = [module.eks.node_security_group_id]

  desired_size = var.eks_main_nodes_desired_size
  max_size     = var.eks_main_nodes_max_size
  min_size     = var.eks_main_nodes_min_size

  ami_id                  = local.ami_id
  ami_type                = local.ami_id != "BOTTLEROCKET_x86_64" ? "AL2_x86_64" : "BOTTLEROCKET_x86_64"
  block_device_mappings   = local.block_device_mappings
  bootstrap_extra_args    = local.ami_id != "BOTTLEROCKET_x86_64" ? "" : local.cluster_bottlerocket_user_data
  capacity_type           = "ON_DEMAND"
  instance_types          = var.eks_main_node_instance_types
  labels                  = var.node_labels
  launch_template_name    = "eks-main-${local.cluster_name}"
  platform                = local.ami_id != "BOTTLEROCKET_x86_64" ? "linux" : "bottlerocket"
  pre_bootstrap_user_data = var.gold_image_date != "" ? local.gold_image_pre_bootstrap_script : null
  taints                  = var.node_taints

  tags = merge(var.eks_node_tags, {
    Name = "eks-main-${var.cluster_custom_name}"
  })
}

module "eks_addons" {
  source     = "./addons"
  depends_on = [module.main_nodes]

  aws_partition                    = data.aws_partition.current.partition
  aws_region                       = data.aws_region.current.name
  cloudwatch_kms_key_arn           = module.cloudwatch_kms.key_arn
  custom_ami                       = var.custom_ami_id
  deploy_env                       = var.env
  deploy_project                   = var.project
  eks_cluster_iam_role_arn         = module.eks.cluster_iam_role_arn
  eks_cluster_name                 = module.eks.cluster_name
  eks_cluster_security_group_id    = module.eks.cluster_security_group_id
  eks_node_security_group_id       = module.eks.node_security_group_id
  eks_oidc_provider                = module.eks.oidc_provider
  eks_oidc_provider_arn            = module.eks.oidc_provider_arn
  fluentbit_additional_log_filters = var.fb_additional_log_filters
  fluentbit_chart_version          = var.fb_chart_version
  fluentbit_drop_namespaces        = var.fb_drop_namespaces
  fluentbit_kube_namespaces        = var.fb_kube_namespaces
  fluentbit_log_encryption         = var.fb_log_encryption
  fluentbit_log_filters            = var.fb_log_filters
  fluentbit_log_retention          = var.fb_log_retention
  fluentbit_log_systemd            = var.fb_log_systemd
  fluentbit_system_log_retention   = var.fb_system_log_retention
  fluentbit_tags                   = var.fb_tags
  gold_image_ami_id                = var.gold_image_date != "" ? data.aws_ami.gold_image[0].id : ""
  iam_path                         = local.iam_path
  iam_permissions_boundary_arn     = local.permissions_boundary_arn
  karpenter_base_tags              = var.karpenter_tags
  karpenter_chart_version          = var.kp_chart_version
  main_nodes_iam_role_arn          = module.main_nodes.iam_role_arn
}

module "eks_base" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.0"

  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_name      = module.eks.cluster_name
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_secrets_store_csi_driver              = true
  enable_secrets_store_csi_driver_provider_aws = true

  secrets_store_csi_driver_provider_aws = {
    atomic = true

    tags = {
      Name = "secrets-store-csi-driver-${module.eks.cluster_name}"
    }
  }

  tags = {
    service = "eks"
  }

  depends_on = [
    module.main_nodes,
    aws_security_group_rule.allow_ingress_additional_prefix_lists
  ]
}

resource "aws_eks_addon" "aws-ebs-csi-driver" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = data.aws_eks_addon_version.aws-ebs-csi-driver.version

  depends_on = [module.main_nodes]
}

resource "aws_eks_addon" "aws-efs-csi-driver" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "aws-efs-csi-driver"
  addon_version = data.aws_eks_addon_version.aws-efs-csi-driver.version

  depends_on = [module.main_nodes]
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "coredns"
  addon_version = data.aws_eks_addon_version.coredns.version

  depends_on = [module.main_nodes]
}

resource "aws_eks_addon" "eks-pod-identity-agent" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "eks-pod-identity-agent"
  addon_version = data.aws_eks_addon_version.eks-pod-identity-agent.version
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "kube-proxy"
  addon_version = data.aws_eks_addon_version.kube-proxy.version
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "vpc-cni"
  addon_version = data.aws_eks_addon_version.vpc-cni.version

  configuration_values = jsonencode({
    env = {
      AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
      ENI_CONFIG_ANNOTATION_DEF          = "k8s.amazonaws.com/eniConfig"
      ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
    }
  })
}

resource "aws_eks_addon" "aws_cloudwatch_observability" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "amazon-cloudwatch-observability"
  addon_version = data.aws_eks_addon_version.aws_cloudwatch_observability.version

  configuration_values = jsonencode({
    agent = {
      config = {
        logs = {
          metrics_collected = {
            app_signals = {}
            kubernetes = {
              enhanced_container_insights = false
            }
          }
        }
      }
    }
    containerLogs = {
      enabled = false
    }
  })

  depends_on = [module.main_nodes]
}

resource "null_resource" "generate_eni_configs" {
  for_each = data.aws_subnet.container

  provisioner "local-exec" {
    command = <<EOT
      ${path.module}/utils/eni_config.sh "${module.eks.cluster_primary_security_group_id}" "${each.value.id}" "${each.value.availability_zone}" "${module.eks.cluster_name}"
    EOT
  }
}

#EKS Pode Identities
module "aws_ebs_csi_pod_identity" {
  count  = var.enable_eks_pod_identities ? 1 : 0
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name            = "aws-ebs-csi-${module.eks.cluster_name}"
  use_name_prefix = false
  description     = "AWS EKS EBS CSI Driver role"

  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns      = [module.ebs_kms.key_arn]
  aws_ebs_csi_policy_name   = "${module.eks.cluster_name}-ebs-csi-driver"
  path                      = local.iam_path
  permissions_boundary_arn  = local.permissions_boundary_arn
  policy_name_prefix        = "${module.eks.cluster_name}-"

  tags = var.pod_identity_tags

  depends_on = [aws_eks_addon.eks-pod-identity-agent]
}

module "aws_efs_csi_pod_identity" {
  count  = var.enable_eks_pod_identities ? 1 : 0
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name            = "aws-efs-csi-${module.eks.cluster_name}"
  use_name_prefix = false
  description     = "AWS EKS EFS CSI Driver role"

  attach_aws_efs_csi_policy = true
  aws_efs_csi_policy_name   = "${module.eks.cluster_name}-efs-csi-driver"
  path                      = local.iam_path
  permissions_boundary_arn  = local.permissions_boundary_arn
  policy_name_prefix        = "${module.eks.cluster_name}-"

  tags = var.pod_identity_tags

  depends_on = [aws_eks_addon.eks-pod-identity-agent]
}

module "aws_lb_controller_pod_identity" {
  count  = var.enable_eks_pod_identities ? 1 : 0
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name            = "aws-lbc-${module.eks.cluster_name}"
  use_name_prefix = false
  description     = "AWS EKS ALB Controller Driver role"

  attach_aws_lb_controller_policy = true
  aws_lb_controller_policy_name   = "${module.eks.cluster_name}-lb-controller"
  path                            = local.iam_path
  permissions_boundary_arn        = local.permissions_boundary_arn
  policy_name_prefix              = "${module.eks.cluster_name}-"

  tags = var.lb_controller_tags

  depends_on = [aws_eks_addon.eks-pod-identity-agent]
}

module "aws_cloudwatch_observability_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name            = "aws-cloudwatch-observability-${module.eks.cluster_name}"
  use_name_prefix = false
  description     = "AWS Cloudwatch Observability role"

  attach_aws_cloudwatch_observability_policy = true
  path                                       = local.iam_path
  permissions_boundary_arn                   = local.permissions_boundary_arn
  policy_name_prefix                         = "${module.eks.cluster_name}-"

  tags = var.cw_observability_tags

  associations = {
    "amazon-cloudwatch-observability-controller-manager" = {
      namespace       = "amazon-cloudwatch"
      cluster_name    = module.eks.cluster_name
      service_account = "amazon-cloudwatch-observability-controller-manager"
    }

    "cloudwatch-agent" = {
      namespace       = "amazon-cloudwatch"
      cluster_name    = module.eks.cluster_name
      service_account = "cloudwatch-agent"
    }

    "dcgm-exporter-service-acct" = {
      namespace       = "amazon-cloudwatch"
      cluster_name    = module.eks.cluster_name
      service_account = "dcgm-exporter-service-acct"
    }

    "neuron-monitor-service-acct" = {
      namespace       = "amazon-cloudwatch"
      cluster_name    = module.eks.cluster_name
      service_account = "neuron-monitor-service-acct"
    }

    "default" = {
      namespace       = "amazon-cloudwatch"
      cluster_name    = module.eks.cluster_name
      service_account = "default"
    }

  }
}

# Ingress for provided prefix lists
resource "aws_security_group_rule" "allow_ingress_additional_prefix_lists" {
  for_each          = local.cluster_security_groups
  type              = "ingress"
  description       = "allow_ingress_additional_prefix_lists"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  prefix_list_ids   = local.cluster_security_group_prefix_list_ids
  security_group_id = each.value
}

resource "aws_security_group_rule" "https-tg-ingress" {
  type              = "ingress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  security_group_id = module.eks.node_security_group_id
  cidr_blocks       = ["10.0.0.0/8"]
}

resource "aws_security_group_rule" "https-vpc-ingress" {
  count             = 1
  type              = "ingress"
  to_port           = 443
  from_port         = 0
  protocol          = "tcp"
  security_group_id = module.eks.cluster_primary_security_group_id
  cidr_blocks       = data.aws_vpc.vpc.cidr_block_associations.*.cidr_block
}
