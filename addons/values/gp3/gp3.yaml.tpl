storageClass:
  name: "gp3"
  isDefaultClass: true
  provisioner: "kubernetes.io/aws-ebs"
  parameters:
    type: "gp3"
  reclaimPolicy: "${reclaim_policy}"
  volumeBindingMode: "${volume_binding_mode}"
