#Karpenter Terraform
module "karpenter" {
  source     = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name                      = module.eks.cluster_name
  create_access_entry               = false
  create_node_iam_role              = false
  create_pod_identity_association   = true
  enable_pod_identity               = true
  enable_spot_termination           = true
  iam_policy_name                   = "${module.eks.cluster_name}-karpenter-policy"
  iam_policy_path                   = local.iam_path
  iam_role_path                     = local.iam_path
  iam_role_permissions_boundary_arn = local.permissions_boundary_arn
  namespace                         = local.karpenter_namespace
  node_iam_role_arn                 = module.main_nodes.iam_role_arn
  service_account                   = local.karpenter_service_account_name


  tags = var.karpenter_tags
}
