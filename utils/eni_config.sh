#!/usr/bin/env bash

security_group="${1}"
subnet_id="${2}"
availability_zone="${3}"
cluster_name="${4}"

# Set the kubeconfig file path
kubeconfig_file="/tmp/kubeconfig_${cluster_name}"

aws eks update-kubeconfig --name "${cluster_name}" --kubeconfig "${kubeconfig_file}"

# Check if the kubeconfig was successfully created
if [ ! -f "${kubeconfig_file}" ]; then
  echo "Failed to create kubeconfig for EKS cluster ${cluster_name}"
  exit 1
fi

# Create the YAML file
yaml_file="eni-config-${availability_zone}.yaml"
cat <<EOF > "${yaml_file}"
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: ${availability_zone}
spec:
  securityGroups:
    - ${security_group}
  subnet: ${subnet_id}
EOF

# Apply the YAML file to the EKS cluster
kubectl --kubeconfig="${kubeconfig_file}" apply -f "${yaml_file}"

# Check if the apply was successful
if [ $? -ne 0 ]; then
  echo "Failed to apply the YAML configuration to the EKS cluster"
  exit 1
fi

# Remove the kubeconfig file as a security precaution
rm -f "${kubeconfig_file}"

# Remove the YAML file as a security precaution
rm -f "${yaml_file}"