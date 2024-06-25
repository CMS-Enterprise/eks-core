resource "kubectl_manifest" "eni_config" {
  for_each = data.aws_subnet.container

  yaml_body = yamlencode({
    # TODO: Please parametrize this version.
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
    # TODO: Please parametrize this version.
    apiVersion = "storage.k8s.io/v1"
    metadata = {
      name = "efs-sc"
    }
    provisioner = "efs.csi.aws.com"
    parameters = {
      provisioningMode = "efs-ap"
      fileSystemId     = aws_efs_file_system.main.id
# TODO: Please parametrize this.
      directoryPerms   = "700"
    }
  })
}

resource "kubectl_manifest" "gp3" {
  yaml_body = yamlencode({
    kind       = "StorageClass"
    # TODO: Please parametrize this version.
    apiVersion = "storage.k8s.io/v1"
    metadata = {
      name = "gp3"
      # TODO: Please parametrize this annotation.
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = "true"
      }
    }
    provisioner = "kubernetes.io/aws-ebs"
    parameters = {
      type = "gp3"
    }
    # TODO: Please parametrize both values.
    reclaimPolicy     = "Delete"
    volumeBindingMode = "WaitForFirstConsumer"
  })
}
