#Karpenter Terraform
module "karpenter" {
  source     = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name                      = var.eks_cluster_name
  create_access_entry               = false
  create_node_iam_role              = false
  create_pod_identity_association   = true
  enable_pod_identity               = true
  enable_spot_termination           = true
  iam_policy_name                   = "${var.eks_cluster_name}-karpenter-policy"
  iam_policy_path                   = var.iam_path
  iam_role_path                     = var.iam_path
  iam_role_permissions_boundary_arn = var.iam_permissions_boundary_arn
  namespace                         = local.karpenter_namespace
  node_iam_role_arn                 = var.eks_node_iam_role_arn
  service_account                   = local.karpenter_service_account_name


  tags = var.karpenter_base_tags
}

#Karpenter HELM
resource "helm_release" "karpenter-crd" {
  atomic           = true
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.karpenter_chart_version
  create_namespace = true
  namespace        = local.karpenter_namespace

  values = [
    local.kp_values
  ]

  set {
    name  = "serviceAccount.name"
    value = local.karpenter_service_account_name
  }
  set {
    name  = "settings.isolatedVPC"
    value = true
  }

  depends_on = [module.karpenter]
}

#Karpenter Nodes HELM
resource "helm_release" "karpenter-nodes" {
  depends_on = [helm_release.karpenter-crd]
  atomic     = true
  name       = "karpenter-nodes"
  repository = "${path.module}/values"
  chart      = "karpenter-nodes"
  version    = "1.0.0"
  namespace  = local.karpenter_namespace

  values = [
    local.kpn_values
  ]
}
