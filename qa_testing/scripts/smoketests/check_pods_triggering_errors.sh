#!/usr/bin/env bash

#######################################################################
# Script Name: check_pods_triggering_errors.sh
# Purpose: This script checks for any Kubernetes pods that are actively
#          generating errors in their logs.
#
# The script performs the following steps:
#   1. Retrieves all pod names and namespaces across all namespaces.
#   2. Checks the logs of each pod for errors.
#   3. Reports any pods that are actively triggering errors.
#
#######################################################################

echo "Testcase: Confirm, are there any pods which are actively triggering errors"

# Define the temporary file for error logs
error_file=$(mktemp)

# Function to check if pods are actively triggering errors
check_pod_errors() {
    local result="PASS"

    # Get all pod names and their namespaces using jq
    pods=$(kubectl get pods -A -o json | jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"')

    # Function to check logs for a specific pod
    check_pod_logs() {
        local namespace=$1
        local name=$2
        local pod_logs
        pod_logs=$(kubectl logs -n "$namespace" "$name" --tail=4 2>/dev/null | grep -i "error")
        if [ -n "$pod_logs" ]; then
            echo "FAIL: The following pod is actively triggering errors:" >> "$error_file"
            echo "Pod Name: $name" >> "$error_file"
            echo "Logs: $pod_logs" >> "$error_file"
            echo "" >> "$error_file"
        fi
    }

    # Process each pod sequentially
    while IFS= read -r pod; do
        namespace=$(echo "$pod" | cut -d ' ' -f 1)
        name=$(echo "$pod" | cut -d ' ' -f 2)
        check_pod_logs "$namespace" "$name"
    done <<< "$pods"

    # Check if the error file is empty or not
    if [ -s "$error_file" ]; then
        cat "$error_file"
        result="FAIL"
    fi

    # Print the final result
    if [ "$result" = "PASS" ]; then
        echo "PASS: There are no active pods which are triggering errors."
    else
        echo "FAIL: There are active pods triggering errors."
    fi

    # Cleanup
    rm -f "$error_file"

    # Exit with the appropriate status code
    if [ "$result" == "FAIL" ]; then
        exit 1
    fi
}

# Execute the function
check_pod_errors
