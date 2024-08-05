resource "helm_release" "argocd" {
  depends_on       = [helm_release.karpenter-crd, helm_release.karpenter_nodepool, helm_release.karpenter_ec2nodeclass]
  atomic           = true
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true
  values           = [local.argocd_values]
  wait             = true
  timeout          = 600
}
