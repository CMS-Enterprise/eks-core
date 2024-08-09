#!/bin/bash
#set -x

# Load common utils
source gen_lib_funcs_vars.sh

# Check arguments
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <cluster-name>"
  exit 1
fi

# Get EFS FileSystemId
efs_id=$(aws efs describe-file-systems --query "FileSystems[*].FileSystemId" --output text | awk {'print $1'})
if [[ -z "$efs_id" ]]; then
    echo "ERROR: Could not retrieve EFS fileSystemId"
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
      args: ["-c", "while true; do echo $(date -u) >> /data/out; sleep 5; done"]
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
    kubectl apply -f pvc.yaml 2>&1 >/dev/null
    kubectl apply -f pod.yaml 2>&1 >/dev/null
    sleep 30

    # Test Case 1: Verification of StorageClass, PVC and POD creation
    echo "*************************************************************************"
    echo "TestCase name: Resource creation: Verification of health and functionality."
    efs_csi_pods=$(kubectl get pods -n kube-system | grep efs-csi-controller | awk {'print $1'})
    if [[ -z "$efs_csi_pods" ]]; then
        echo "ERROR: Could retrieve EFS CSI controllers"
        return 1
    fi

    echo

    # Test Case 2: Verification of PVC and EFS
    echo "*************************************************************************"
    echo "TestCase name: Volume Binding: Verification of health and functionality."
    kubectl get pv --no-headers | grep efs-claim
    if [ $? -ne 0 ]; then
        echo "ERROR: Volume not bound to PVC"
        return 1
    fi
    kubectl get pvc --no-headers | grep efs-claim
    if [ $? -ne 0 ]; then
        echo "ERROR: PVC not configured"
        return 1
    fi

    echo

    # Test Case 2: Verification of Running POD
    echo "*********************************************************************"
    echo "TestCase name: Pod Running: Verification of health and functionality."
    kubectl get pods --no-headers -o wide | grep efs-app | grep Running
    if [ $? -ne 0 ]; then
        echo "ERROR: Pod efs-app not running"
        return 1
    fi

    echo

    # Test Case 4: Verification of Data persistence
    echo "********************************************************************"
    echo "TestCase name: EFS Volume: Verification of health and functionality."
    kubectl exec efs-app -- bash -c "tail -10 data/out"
    if [ $? -ne 0 ]; then
        echo "ERROR: EFS Volume not writeable"
        return 1
    fi

    return 0
}

test_aws_efs_driver $1
result=$?

if [ $result -eq 0 ]; then
  echo "PASS: AWS EFS Driver functioning correctly"
else
  echo "FAIL: AWS EFS Driver is not functioning correctly"
fi

# Cleanup YAML configurations
kubectl delete -f pod.yaml 2>&1 >/dev/null
kubectl delete -f pvc.yaml 2>&1 >/dev/null
rm -f pod.yaml pvc.yaml 2>&1 >/dev/null
