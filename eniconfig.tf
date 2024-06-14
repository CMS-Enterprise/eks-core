
resource "kubectl_manifest" "eni_config" {
  for_each = { for k, all_container_subnet_ids in flatten(local.all_container_subnet_ids) : k => all_container_subnet_ids}

  yaml_body = yamlencode({
    apiVersion = "crd.k8s.amazonaws.com/v1alpha1"
    kind       = "ENIConfig"
    metadata = {
      name = each.key
    }
    spec = {
      securityGroups = [
        local.cluster_security_groups.node,
      ]
      subnet = each.value
    }
  })
}

