#!/usr/bin/env bash
#set -x

#######################################################################
# Script Name: check_ebscsi.sh
# Purpose: This script verifies the health and functionality of the
#          AWS EBS CSI driver within a Kubernetes cluster.
#
# The script performs the following checks:
#   1. Creates and validates a StorageClass configured with the EBS CSI driver.
#   2. Creates a PersistentVolumeClaim (PVC) and verifies that it is bound.
#   3. Creates a test Pod that mounts the PVC and ensures it is running.
#   4. Verifies data persistence on the mounted EBS volume.
#   5. Cleans up all resources created during the test.
#
#######################################################################

# Load common utilities and variables
source "$(dirname "${BASH_SOURCE[0]}")/../libraries/general_funcs_vars.sh"

# Check arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cluster-name>"
    exit 1
fi

# Define YAML files
cat <<EOF > storageclass.yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
EOF

cat <<EOF > pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-sc
  resources:
    requests:
      storage: 4Gi
EOF

cat << EOF > pod.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: ebs-app
spec:
  containers:
  - name: ebs-app
    image: centos
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo \$(date -u) >> /data/out; sleep 5; done"]
    volumeMounts:
    - name: persistent-storage
      mountPath: /data
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: ebs-claim
EOF

test_aws_ebs_driver() {
    local cluster_name=$1

    # Apply YAML configurations
    kubectl apply -f storageclass.yaml >/dev/null 2>&1
    kubectl apply -f pvc.yaml >/dev/null 2>&1
    kubectl apply -f pod.yaml >/dev/null 2>&1

    # Wait for Pod readiness (up to 60 seconds)
    kubectl wait --for=condition=Ready pod/ebs-app --timeout=60s >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR: Pod ebs-app did not reach the Ready state within the timeout period."
        return 1
    fi

    # Test Case 1: Verification of StorageClass
    echo "TestCase name: EBSCSI Driver Addon: Verification of health and functionality."
    kubectl describe storageclass ebs-sc >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR: StorageClass ebs-sc not configured correctly."
        return 1
    fi

    # Test Case 2: Verification of PVC binding
    if ! kubectl get pvc ebs-claim -o jsonpath='{.status.phase}' | grep -q "Bound"; then
        echo "ERROR: PVC ebs-claim is not bound."
        return 1
    fi

    # Test Case 3: Verification of Pod Running state
    if ! kubectl get pod ebs-app -o jsonpath='{.status.containerStatuses[0].ready}' | grep -q "true"; then
        echo "ERROR: Pod ebs-app is not in a ready state."
        return 1
    fi

    # Test Case 4: Verification of Data persistence
    echo "Verification of Data persistence."
    kubectl exec ebs-app -- bash -c "tail -10 /data/out" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR: EBS Volume is not writable or data persistence failed."
        return 1
    fi

    return 0
}

test_aws_ebs_driver $1
result=$?

# Cleanup YAML configurations
kubectl delete -f pod.yaml >/dev/null 2>&1
kubectl delete -f pvc.yaml >/dev/null 2>&1
kubectl delete -f storageclass.yaml >/dev/null 2>&1
rm -f pod.yaml pvc.yaml storageclass.yaml

if [ $result -eq 0 ]; then
    echo "PASS: AWS EBS Driver is functioning correctly."
else
    echo "FAIL: AWS EBS Driver is not functioning correctly."
    exit 1
fi

