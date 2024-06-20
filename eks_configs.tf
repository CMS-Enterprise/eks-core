provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

resource "kubectl_manifest" "eni_config" {
  for_each = data.aws_subnet.container

  yaml_body = yamlencode({
    apiVersion = "crd.k8s.amazonaws.com/v1alpha1"
    kind       = "ENIConfig"
    metadata = {
      name = each.value.availability_zone
    }
    spec = {
      securityGroups = [module.eks.cluster_primary_security_group_id]
      subnet         = each.value.id
    }
  })
}

resource "kubectl_manifest" "efs_storage_class" {
  yaml_body = yamlencode({
    kind       = "StorageClass"
    apiVersion = "storage.k8s.io/v1"
    metadata = {
      name = "efs-sc"
    }
    provisioner = "efs.csi.aws.com"
    parameters = {
      provisioningMode = "efs-ap"
      fileSystemId     = aws_efs_file_system.main.id
      directoryPerms   = "700"
    }
  })
}

resource "kubectl_manifest" "gp3" {
  yaml_body = yamlencode({
    kind       = "StorageClass"
    apiVersion = "storage.k8s.io/v1"
    metadata = {
      name = "gp3"
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = "true"
      }
    }
    provisioner = "kubernetes.io/aws-ebs"
    parameters = {
      type = "gp3"
    }
    reclaimPolicy     = "Delete"
    volumeBindingMode = "WaitForFirstConsumer"
  })
}
