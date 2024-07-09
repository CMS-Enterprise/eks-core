resource "aws_secretsmanager_secret" "argocd_admin" {
  name = local.argocd_cd_secret_name
  tags = var.eks_cluster_tags
}
