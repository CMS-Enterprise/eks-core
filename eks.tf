module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.11.0"

  authentication_mode                          = "API_AND_CONFIG_MAP"
  cloudwatch_log_group_class                   = "STANDARD"
  cloudwatch_log_group_kms_key_id              = aws_kms_key.cloudwatch.arn
  cloudwatch_log_group_retention_in_days       = 365
  cluster_endpoint_private_access              = true
  cluster_endpoint_public_access               = false
  cluster_ip_family                            = "ipv4"
  cluster_name                                 = local.cluster_name
  cluster_security_group_name                  = "eks-${local.cluster_name}-cluster-sg"
  cluster_service_ipv4_cidr                    = "172.20.0.0/16"
  cluster_version                              = local.cluster_version
  control_plane_subnet_ids                     = module.vpc.private_subnets
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
  iam_role_use_name_prefix                     = false
  kms_key_administrators                       = []
  kms_key_aliases                              = ["eks-${local.cluster_name}"]
  kms_key_deletion_window_in_days              = 7
  kms_key_description                          = "KMS key for EKS ${local.cluster_name} cluster"
  node_security_group_description              = "Security group for EKS nodes"
  node_security_group_enable_recommended_rules = true
  node_security_group_name                     = "eks-${local.cluster_name}-node-sg"
  node_security_group_use_name_prefix          = false
  subnet_ids                                   = module.vpc.private_subnets
  tags                                         = { Name = local.cluster_name }
  vpc_id                                       = module.vpc.vpc_id

  access_entries = {
    admins = {
      principal_arn = ""
      type          = "STANDARD"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  cluster_addons = {
    coredns = {
      addon_version = "v1.10.1-eksbuild.7"
      preserve      = false
    }
    aws-ebs-csi-driver = {
      addon_version            = "v1.30.0-eksbuild.1"
      preserve                 = false
      service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
    }
    kube-proxy = {
      addon_version = "v1.28.8-eksbuild.2"
      preserve      = false
    }
    vpc-cni = {
      addon_version = "v1.18.1-eksbuild.1"
      preserve      = false
    }
    eks-pod-identity-agent = {
      addon_version = "v1.2.0-eksbuild.1"
      preserve      = false
    }
  }

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  node_security_group_additional_rules = {
    ingress_15017 = {
      description                   = "Cluster API - Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_15012 = {
      description                   = "Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
}

module "main_nodes" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "20.2.1"

  name              = "eks-main-${local.cluster_name}"
  cluster_ip_family = "ipv4"
  cluster_name      = module.eks.cluster_name
  cluster_version   = module.eks.cluster_version

  cluster_primary_security_group_id = module.eks.cluster_security_group_id
  iam_role_additional_policies      = { ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" }
  iam_role_arn                      = module.eks.cluster_iam_role_arn
  subnet_ids                        = var.subnet_ids
  vpc_security_group_ids            = [module.eks.node_security_group_id]

  desired_size = 3
  max_size     = 6
  min_size     = 3

  ami_type             = var.custom_ami_id != "" ? var.custom_ami_id : "BOTTLEROCKET_x86_64"
  bootstrap_extra_args = var.custom_ami_id != "" ? null : local.cluster_bottlerocket_user_data
  capacity_type        = "ON_DEMAND"
  ebs_optimized        = true
  instance_types       = ["c6a.large"]
  labels               = var.node_labels
  launch_template_name = "eks-main-${local.cluster_name}"
  platform             = var.custom_ami_id != "" ? "linux" : "bottlerocket"
  taints               = var.node_taints

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 5
        volume_type           = "gp3"
        delete_on_termination = true
        encrypted             = true
      }
    },
    {
      device_name = "/dev/xvdb"
      ebs = {
        volume_size           = 100
        volume_type           = "gp3"
        delete_on_termination = true
        encrypted             = true
      }
    }
  ]

  tags = {
    Name = "eks-main-${var.cluster_name}"
  }
}

module "eks_base" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller          = true
  enable_secrets_store_csi_driver_provider_aws = true

  secrets_store_csi_driver_provider_aws = {
    atomic = true

    tags = {
      Name = "secrets-store-csi-driver-${var.cluster_name}"
    }
  }

  tags = {
    service = "eks"
  }

  depends_on = [
    module.eks
  ]
}

module "aws_node_termination_handler_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role      = true
  role_name_prefix = local.node_termination_handler_name
  role_description = "IRSA role for node termination handler"

  provider_url                   = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns               = [aws_iam_policy.aws_node_termination_handler.arn]
  oidc_fully_qualified_subjects  = ["system:serviceaccount:kube-system:aws-node-termination-handler"]
  oidc_fully_qualified_audiences = ["sts.amazonaws.com"]
}

module "aws_node_termination_handler_sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.2.0"

  name                      = local.node_termination_handler_name
  message_retention_seconds = 300
  policy                    = data.aws_iam_policy_document.aws_node_termination_handler_sqs.json
  kms_master_key_id         = aws_kms_key.sqs.id

  tags = {
    service = "eks"
  }
}

# This installs the gp3 storage class and makes it the default
resource "kubernetes_storage_class_v1" "gp3" {
  storage_provisioner    = "kubernetes.io/aws-ebs"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "Immediate"

  parameters = {
    type = "gp3"
  }

  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  depends_on = [
    module.eks
  ]
}

# This deletes the default gp2 storage class
resource "null_resource" "gp2" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "${path.module}/utils/k8s_bootstrap.sh ${module.eks.cluster_name} ${var.region} ${local.role_to_assume}"
  }
  depends_on = [
    kubernetes_storage_class_v1.gp3
  ]
  lifecycle {
    ignore_changes = [
      triggers
    ]
  }
}

# This is intentionally separated from the other addons due to a bug
resource "aws_eks_addon" "guardduty" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-guardduty-agent"
  addon_version               = data.aws_eks_addon_version.guardduty.version
  preserve                    = false
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    module.eks
  ]
}