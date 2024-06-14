resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = data.aws_vpc.vpc.id
  cidr_block = "100.107.0.0/16"
}

resource "kubectl_manifest" "eni_config" {
  for_each = (local.all_container_subnet_ids)

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
