#!/bin/bash

# Function to check resource health
check_resource() {
    local resource_type=$1
    local result="PASS"
    local message=""

    case $resource_type in
        "pods")
            # Check if there are any pods first
            all_pods=$(kubectl get pods -A --no-headers)
            if [[ -z "$all_pods" ]]; then
                message="No pods resources found."
                result="FAIL"
            else
                resource_status=$(echo "$all_pods" | awk '$4 != "Running"')
                if [[ -n "$resource_status" ]]; then
                    message="FAIL: Some pods are not running."
                    result="FAIL"
                fi
            fi
            ;;
        "deployments")
            resource_status=$(kubectl get deployments -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,AVAILABLE:.status.availableReplicas,TOTAL:.status.replicas | tail -n +2 | awk '$3 < $4 {print $0}')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some deployments have unavailable replicas."
                result="FAIL"
            fi
            ;;
        "statefulsets")
            resource_status=$(kubectl get statefulsets -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,AVAILABLE:.status.readyReplicas,TOTAL:.status.replicas | tail -n +2 | awk '$3 < $4')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some statefulsets have unavailable replicas."
                result="FAIL"
            fi
            ;;
        "daemonsets")
            resource_status=$(kubectl get daemonsets -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,AVAILABLE:.status.numberAvailable,TOTAL:.status.desiredNumberScheduled | tail -n +2 | awk '$3 < $4')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some daemonsets have unavailable replicas."
                result="FAIL"
            fi
            ;;
        "jobs")
            resource_status=$(kubectl get jobs -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,COMPLETIONS:.status.succeeded,TOTAL:.spec.completions | tail -n +2 | awk '$3 < $4')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some jobs are not completed."
                result="FAIL"
            fi
            ;;
        "hpa")
            resource_status=$(kubectl get hpa -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,CURRENT:.status.currentReplicas,DESIRED:.status.desiredReplicas | tail -n +2 | awk '$3 < $4')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some HPAs do not have desired replicas."
                result="FAIL"
            fi
            ;;
        "nodes")
            resource_status=$(kubectl get nodes --no-headers | awk '$2 != "Ready"')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some nodes are not in Ready state."
                result="FAIL"
            fi
            ;;
        "namespaces")
            resource_status=$(kubectl get namespaces -o custom-columns=NAME:.metadata.name,STATUS:.status.phase | grep -v "Active" | tail -n +2)
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some namespaces are not active."
                result="FAIL"
            fi
            ;;
        *)
            message="FAIL: Unknown resource type $resource_type"
            result="FAIL"
            ;;
    esac

    if [[ "$result" == "PASS" ]]; then
        echo "PASS: All $resource_type resources are healthy."
    else
        echo "$message"
    fi
}

# List of resource types to check
#echo "********************************************************"
echo "Testcase name: Verify if all resources are running healthy?"
resources=("pods" "deployments" "statefulsets" "daemonsets" "jobs" "hpa" "nodes" "namespaces")

# Check each resource type
for resource in "${resources[@]}"; do
    check_resource "$resource"
done