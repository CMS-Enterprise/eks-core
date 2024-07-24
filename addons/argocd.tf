resource "helm_release" "argocd" {
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