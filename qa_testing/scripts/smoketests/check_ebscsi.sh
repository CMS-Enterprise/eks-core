#!/usr/bin/env bash
#set -x

# Load common utils
source gen_lib_funcs_vars.sh

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
    args: ["-c", "while true; do echo $(date -u) >> /data/out; sleep 5; done"]
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
    kubectl apply -f storageclass.yaml 2>&1 >/dev/null
    kubectl apply -f pvc.yaml 2>&1 >/dev/null
    kubectl apply -f pod.yaml 2>&1 >/dev/null
    sleep 30

    # Test Case 1: Verification of StorageClass
    echo "TestCase name: EBSCSI Driver Addon: Verification of health and functionality."
    kubectl describe storageclass ebs-sc 2>&1 >/dev/null
    if [ $? -ne 0 ]; then
        echo "ERROR: StorageClass ebs-sc not configured"
        return 1
    fi

    # Test Case 2: Verification of PVC and EBS
    ebs_pvc=$(kubectl get pv --no-headers | awk {'print $1'})
    if [[ -z $ebs_pvc ]]; then
        echo "ERROR: Could not validate PVC"
        return 1
    fi

    # Test Case 2: Verification of Running POD
    kubectl get pods --no-headers -o wide | grep ebs-app | grep Running 2>&1 >/dev/null
    if [ $? -ne 0 ]; then
        echo "ERROR: Pod ebs-app not running"
        return 1
    fi

    # Test Case 4: Verification of Data persistence
    echo "Verification of Data persistence."
    kubectl exec ebs-app -- bash -c "tail -10 data/out"
    if [ $? -ne 0 ]; then
        echo "ERROR: EBS Volume not writeable"
        return 1
    fi

    return 0
}

# Cleanup YAML configurations
kubectl delete -f pod.yaml 2>&1 >/dev/null
kubectl delete -f pvc.yaml 2>&1 >/dev/null
kubectl delete -f storageclass.yaml 2>&1 >/dev/null
rm -f pod.yaml pvc.yaml storageclass.yaml 2>&1 >/dev/null

test_aws_ebs_driver $1
result=$?

if [ $result -eq 0 ]; then
  echo "PASS: AWS EBS Driver functioning correctly"
else
  echo "FAIL: AWS EBS Driver is not functioning correctly"
  exit 1
fi

