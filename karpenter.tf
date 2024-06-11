#Karpenter Terraform
module "karpenter" {
  source     = "terraform-aws-modules/eks/aws//modules/karpenter"
  depends_on = [module.eks, module.main_nodes, module.eks_base]

  cluster_name            = module.eks.cluster_name
  create_access_entry     = false
  create_node_iam_role    = false
  enable_pod_identity     = true
  enable_spot_termination = true
  node_iam_role_arn       = module.eks.cluster_iam_role_arn


  tags = var.karpenter_tags
}

#Karpenter HELM
resource "helm_release" "karpenter-crd" {
  depends_on       = [module.eks, module.main_nodes, module.eks_base, module.karpenter]
  name             = "${local.cluster_name}-karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.kp_chart_verison
  create_namespace = true
  namespace        = "karpenter"

  values = [
    local.kp_values
  ]

}

#Karpenter Nodes HELM
resource "helm_release" "karpenter-nodes" {
  depends_on = [helm_release.karpenter-crd]
  name       = "${local.cluster_name}-karpenter"
  repository = "./helm/karpenter-nodes"
  chart      = "karpenter-nodes"
  version    = "1.0.0"
  namespace  = "karpenter"

  values = [
    local.kpn_values
  ]

}
