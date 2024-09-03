#!/usr/bin/env bash
#set -x

#######################################################################
# Script Name: check_efscsi.sh
# Purpose: This script verifies the health and functionality of the
#          AWS EFS CSI driver within a Kubernetes cluster.
#
# The script performs the following checks:
#   1. Verifies the correct creation of EFS PersistentVolume (PV),
#      PersistentVolumeClaim (PVC), and associated Pods.
#   2. Confirms the presence of the EFS CSI controller pods.
#   3. Validates the binding of the PersistentVolume (PV) to the
#      PersistentVolumeClaim (PVC).
#   4. Ensures that the test Pod using the EFS PVC is running.
#   5. Verifies data persistence by writing and reading data on the
#      EFS-backed volume.
#   6. Cleans up all resources created during the test.
#
#######################################################################

# Load common utilities and variables
source "$(dirname "${BASH_SOURCE[0]}")/../libraries/general_funcs_vars.sh"

# Check arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cluster-name>"
    exit 1
fi

# Get EFS FileSystemId
efs_id=$(aws efs describe-file-systems --query "FileSystems[0].FileSystemId" --output text)
if [[ -z "$efs_id" ]]; then
    echo "ERROR: Could not retrieve EFS fileSystemId."
    exit 1
fi

# Define YAML files
cat <<EOF > pvc.yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-volume
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: "$efs_id"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 1Gi
EOF

cat <<EOF > pod.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: efs-app
spec:
  containers:
    - name: app
      image: centos
      command: ["/bin/sh"]
      args: ["-c", "while true; do echo \$(date -u) >> /data/out; sleep 5; done"]
      volumeMounts:
        - name: persistent-storage
          mountPath: /data
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: efs-claim
EOF

test_aws_efs_driver() {
    local cluster_name=$1

    # Apply YAML configurations
    kubectl apply -f pvc.yaml >/dev/null 2>&1
    kubectl apply -f pod.yaml >/dev/null 2>&1

    # Test Case 1: Verification of StorageClass, PVC and POD creation
    echo "TestCase name: EFSCSI Driver Addon: Verification of health and functionality."
    efs_csi_pods=$(kubectl get pods -n kube-system | grep efs-csi-controller | awk {'print $1'})
    if [[ -z "$efs_csi_pods" ]]; then
        echo "ERROR: Could retrieve EFS CSI controllers"
        return 1
    fi

    # Test Case 2: Verification of PVC and EFS
    kubectl get pv --no-headers | grep efs-claim 2>&1 >/dev/null
    if [ $? -ne 0 ]; then
        echo "ERROR: Pod efs-app did not reach the Ready state within the timeout period."
        return 1
    fi

    # Test Case 1: Verification of EFS CSI driver pods
    echo "TestCase: EFSCSI Driver Addon - Verify health and functionality."
    efs_csi_pods=$(kubectl get pods -n kube-system -l app=efs-csi-controller -o json | jq -r '.items[] | select(.status.phase != "Running") | .metadata.name')
    if [[ -n "$efs_csi_pods" ]]; then
        echo "ERROR: The following EFS CSI controller pods are not running: $efs_csi_pods."
        return 1
    fi

    # Test Case 2: Verification of PVC and EFS binding
    if ! kubectl get pv efs-volume >/dev/null 2>&1; then
        echo "ERROR: EFS PersistentVolume (efs-volume) not created."
        return 1
    fi
    if ! kubectl get pvc efs-claim >/dev/null 2>&1; then
        echo "ERROR: PersistentVolumeClaim (efs-claim) not created or bound."
        return 1
    fi

    # Test Case 3: Verification of Running Pod
    if ! kubectl get pod efs-app -o json | jq -e '.status.phase == "Running"' >/dev/null 2>&1; then
        echo "ERROR: Pod (efs-app) is not in Running state."
        return 1
    fi

    # Test Case 4: Verification of Data Persistence
    echo "Verification of Data Persistence..."
    if ! kubectl exec efs-app -- bash -c "tail -10 /data/out" >/dev/null 2>&1; then
        echo "ERROR: EFS Volume is not writable."
        return 1
    fi

    return 0
}

test_aws_efs_driver "$1"
result=$?

# Cleanup YAML configurations
kubectl delete -f pod.yaml >/dev/null 2>&1
kubectl delete -f pvc.yaml >/dev/null 2>&1
rm -f pod.yaml pvc.yaml >/dev/null 2>&1

if [ $result -eq 0 ]; then
    echo "PASS: AWS EFS Driver functioning correctly."
else
    echo "FAIL: AWS EFS Driver is not functioning correctly."
    exit 1
fi