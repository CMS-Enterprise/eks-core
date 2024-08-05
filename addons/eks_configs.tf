resource "helm_release" "eni_config" {
  atomic    = true
  name      = "eni-config"
  namespace = "kube-system"
  chart     = "${path.module}/charts/eni-configs"

  values = [
    local.eni_config_values
  ]
}

resource "helm_release" "efs_storage_class" {
  atomic    = true
  name      = "efs-storage-class"
  namespace = "kube-system"
  chart     = "${path.module}/charts/efs-storage-class"

  values = [
    local.efs_storage_class_values
  ]
}

resource "helm_release" "gp3_storage_class" {
  atomic    = true
  name      = "gp3-storage-class"
  namespace = "kube-system"
  chart     = "${path.module}/charts/gp3"

  values = [
    local.gp3_values
  ]
}
