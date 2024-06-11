module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.11.0"

  access_entries                               = var.eks_access_entries
  authentication_mode                          = "API_AND_CONFIG_MAP"
  cloudwatch_log_group_class                   = "STANDARD"
  cloudwatch_log_group_kms_key_id              = module.cloudwatch_kms.key_arn
  cloudwatch_log_group_retention_in_days       = 365
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
  iam_role_path                                = "/delegatedadmin/developer/"
  iam_role_permissions_boundary                = data.aws_iam_policy.permissions_boundary.arn
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

  cluster_addons = {
    coredns = {
      most_recent = true
      preserve    = false
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      preserve                 = false
      service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
    }
    kube-proxy = {
      most_recent = true
      preserve    = false
    }
    vpc-cni = {
      most_recent = true
      preserve    = false
    }
    eks-pod-identity-agent = {
      most_recent = true
      preserve    = false
    }
  }

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

  name              = "eks-main-${local.cluster_name}"
  cluster_ip_family = "ipv4"
  cluster_name      = module.eks.cluster_name
  cluster_version   = module.eks.cluster_version

  cluster_primary_security_group_id = module.eks.cluster_security_group_id
  create_iam_role                   = false
  iam_role_additional_policies      = { ssm = "arn:${data.aws_caller_identity.current.provider}:iam::aws:policy/AmazonSSMManagedInstanceCore" }
  iam_role_arn                      = module.eks.cluster_iam_role_arn
  subnet_ids                        = local.all_private_subnet_ids
  vpc_security_group_ids            = [module.eks.node_security_group_id]

  desired_size = 3
  max_size     = 6
  min_size     = 3

  ami_type             = local.ami_id
  bootstrap_extra_args = local.ami_id != "BOTTLEROCKET_x86_64" ? null : local.cluster_bottlerocket_user_data
  capacity_type        = "ON_DEMAND"
  ebs_optimized        = true
  instance_types       = ["c6a.large"]
  labels               = var.node_labels
  launch_template_name = "eks-main-${local.cluster_name}"
  platform             = local.ami_id != "BOTTLEROCKET_x86_64" ? "linux" : "bottlerocket"
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

  tags = merge(var.eks_node_tags, {
    Name = "eks-main-${var.cluster_custom_name}"
  })
}

module "eks_base" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller          = false
  enable_secrets_store_csi_driver_provider_aws = true

  secrets_store_csi_driver_provider_aws = {
    atomic = true

    tags = {
      Name = "secrets-store-csi-driver-${var.cluster_custom_name}"
    }
  }

  tags = {
    service = "eks"
  }

  depends_on = [
    module.eks
  ]
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
    command = "${path.module}/utils/k8s_bootstrap.sh ${module.eks.cluster_name} ${data.aws_region.current.name} ${data.aws_caller_identity.current.arn}"
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

#EKS Pode Identities
module "aws_ebs_csi_pod_identity" {
  count  = var.enable_eks_pod_identities ? 1 : 0
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name            = "aws-ebs-csi"
  use_name_prefix = false
  description     = "AWS EKS EBS CSI Driver role"

  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns      = var.ebs_encryption_key
  aws_ebs_csi_policy_name   = "EKS_ebs_csi_driver_policy"

  tags = var.pod_identity_tags
}

module "aws_efs_csi_pod_identity" {
  count  = var.enable_eks_pod_identities ? 1 : 0
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name            = "aws-efs-csi"
  use_name_prefix = false
  description     = "AWS EKS EFS CSI Driver role"

  attach_aws_efs_csi_policy = true
  aws_efs_csi_policy_name   = "EKS_efs_csi_driver_policy"

  tags = var.pod_identity_tags
}

module "aws_lb_controller_pod_identity" {
  count  = var.enable_eks_pod_identities ? 1 : 0
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name            = "aws-lbc"
  use_name_prefix = false
  description     = "AWS EKS ALB Controller Driver role"

  attach_aws_lb_controller_policy = true
  aws_lb_controller_policy_name   = "EKS_lb_controller_policy"

  tags = var.lb_controller_tags
}

module "fluentbit_pod_identity" {
  count      = var.enable_eks_pod_identities ? 1 : 0
  source     = "terraform-aws-modules/eks-pod-identity/aws"
  depends_on = [helm_release.fluent-bit]

  name            = "fluentbit"
  use_name_prefix = false
  description     = "AWS EKS fluentbit role"


  attach_custom_policy    = true
  source_policy_documents = [data.aws_iam_policy_document.fluent-bit.json]

  associations = {
    default = {
      cluster_name    = local.cluster_name
      namespace       = "kube-system"
      service_account = "fluentbit"
    }
  }

  tags = merge(
    var.pod_identity_tags,
    var.fb_tags
  )

}
