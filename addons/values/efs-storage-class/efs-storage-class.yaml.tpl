storageClass:
  name: "efs-sc"
  provisioner: "efs.csi.aws.com"
  parameters:
    provisioningMode: "efs-ap"
    fileSystemId: "${file_system_id}"
    directoryPerms: "${directory_permissions}"
