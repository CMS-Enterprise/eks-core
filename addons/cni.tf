resource "local_file" "eni_config_files" {
  count = length(local.all_container_subnet_ids)

  filename = "${local.all_container_subnet_ids[count.index]}.yaml"

  content = <<EOF
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: ${local.all_container_subnet_ids[count.index]}
spec:
  securityGroups:
    - ${var.eks_cluster_security_group_id}
  subnet: ${local.all_container_subnet_ids[count.index]}
EOF
}

resource "null_resource" "apply_eni_configs" {
  depends_on = [local_file.eni_config_files]

  provisioner "local-exec" {
    command = "kubectl apply -f ${join(" -f ", local_file.eni_config_files[*].filename)}"
  }
}