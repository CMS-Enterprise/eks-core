output "argocd_sub_domain" {
  value = local.argocd_sub_domain
}

output "argocd_helm_status" {
  value = helm_release.argocd.status
}