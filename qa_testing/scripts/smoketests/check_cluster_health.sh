#!/usr/bin/env bash

#######################################################################
# Script Name: check_cluster_health.sh
# Purpose: This script assesses the overall health of key Kubernetes
#          resources within a cluster.
#
# The script performs the following checks:
#   1. Verifies that all Pods are in a Running state.
#   2. Ensures Deployments have the desired number of replicas available.
#   3. Confirms StatefulSets have the expected number of ready replicas.
#   4. Verifies DaemonSets have the desired number of pods running per node.
#   5. Checks that Jobs have successfully completed.
#   6. Validates HPAs have matched current replicas to the desired count.
#   7. Ensures all Nodes are in a Ready state.
#   8. Confirms all Namespaces are in an Active phase.
#
#######################################################################

# Load common utilities and variables
source "$(dirname "${BASH_SOURCE[0]}")/../libraries/general_funcs_vars.sh"

# Initialize the overall result to "PASS"
overall_result="PASS"

# Function to check resource health with batch processing and parallelization
check_resource_batch() {
    local resource_type=$1
    local resources=$2
    local result="PASS"
    local message=""

    case $resource_type in
        "pods")
            resource_status=$(echo "$resources" | jq -r '.items[] | select(.status.phase != "Running") | [.metadata.namespace, .metadata.name, .status.phase] | @tsv')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some pods are not running:\n$resource_status"
                result="FAIL"
            fi
            ;;
        "deployments")
            resource_status=$(echo "$resources" | jq -r '.items[] | select(.status.availableReplicas < .status.replicas) | [.metadata.namespace, .metadata.name, .status.availableReplicas, .status.replicas] | @tsv')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some deployments have unavailable replicas:\n$resource_status"
                result="FAIL"
            fi
            ;;
        "statefulsets")
            resource_status=$(echo "$resources" | jq -r '.items[] | select(.status.readyReplicas < .status.replicas) | [.metadata.namespace, .metadata.name, .status.readyReplicas, .status.replicas] | @tsv')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some statefulsets have unavailable replicas:\n$resource_status"
                result="FAIL"
            fi
            ;;
        "daemonsets")
            resource_status=$(echo "$resources" | jq -r '.items[] | select(.status.numberAvailable < .status.desiredNumberScheduled) | [.metadata.namespace, .metadata.name, .status.numberAvailable, .status.desiredNumberScheduled] | @tsv')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some daemonsets have unavailable replicas:\n$resource_status"
                result="FAIL"
            fi
            ;;
        "jobs")
            resource_status=$(echo "$resources" | jq -r '.items[] | select(.status.succeeded < .spec.completions) | [.metadata.namespace, .metadata.name, .status.succeeded, .spec.completions] | @tsv')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some jobs are not completed:\n$resource_status"
                result="FAIL"
            fi
            ;;
        "hpa")
            resource_status=$(echo "$resources" | jq -r '.items[] | select(.status.currentReplicas < .status.desiredReplicas) | [.metadata.namespace, .metadata.name, .status.currentReplicas, .status.desiredReplicas] | @tsv')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some HPAs do not have desired replicas:\n$resource_status"
                result="FAIL"
            fi
            ;;
        "nodes")
            resource_status=$(echo "$resources" | jq -r '.items[] | select(.status.conditions[] | select(.type == "Ready" and .status != "True")) | [.metadata.name] | @tsv')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some nodes are not in Ready state:\n$resource_status"
                result="FAIL"
            fi
            ;;
        "namespaces")
            resource_status=$(echo "$resources" | jq -r '.items[] | select(.status.phase != "Active") | [.metadata.name, .status.phase] | @tsv')
            if [[ -n "$resource_status" ]]; then
                message="FAIL: Some namespaces are not active:\n$resource_status"
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
        echo -e "$message"
        overall_result="FAIL"
    fi
}

# List of resource types to check
echo "Testcase name: Verify if all resources are running healthy?"
resources=("pods" "deployments" "statefulsets" "daemonsets" "jobs" "hpa" "nodes" "namespaces")

# Fetch all resources in one batch to reduce the number of API calls
fetch_resources() {
    local resource_type=$1
    case $resource_type in
        "pods") kubectl get pods -A -o json ;;
        "deployments") kubectl get deployments -A -o json ;;
        "statefulsets") kubectl get statefulsets -A -o json ;;
        "daemonsets") kubectl get daemonsets -A -o json ;;
        "jobs") kubectl get jobs -A -o json ;;
        "hpa") kubectl get hpa -A -o json ;;
        "nodes") kubectl get nodes -o json ;;
        "namespaces") kubectl get namespaces -o json ;;
        *) echo "{}" ;;  # Empty JSON for unknown resource type
    esac
}

# Run checks in parallel with a batch size for better performance
parallel_check() {
    local resource_type=$1
    local resources
    resources=$(fetch_resources "$resource_type")
    check_resource_batch "$resource_type" "$resources"
}

export -f check_resource_batch fetch_resources parallel_check
parallel -j 4 parallel_check ::: "${resources[@]}"

# Exit with status 1 if any resource check failed
if [[ "$overall_result" == "FAIL" ]]; then
    exit 1
fi