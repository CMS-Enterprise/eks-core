
cluster_addons = {
  vpc-cni = {
    before_compute = true
    most_recent    = true # To ensure access to the latest settings provided
    configuration_values = jsonencode({
      env = {
        AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
        ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
      }
    })
  }
}




resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = data.aws_vpc.vpc.id
  cidr_block = "100.107.0.0/16"
}

resource "kubectl_manifest" "eni_config" {
  for_each = zipmap(local.all_private_subnet_ids)

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
