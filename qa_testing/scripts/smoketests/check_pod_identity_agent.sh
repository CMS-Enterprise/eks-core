#!/usr/bin/env bash

#######################################################################
# Script Name: check_pod_identity_agent.sh
# Purpose: This script verifies the health and functionality of the
#          EKS Pod Identity Agent addon within a Kubernetes cluster.
#
# The script performs the following checks:
#   1. Verifies that Pod Identity Agent pods are present and running.
#   2. Checks the logs of each Pod Identity Agent pod for errors and warnings.
#
#######################################################################

# Function to test Pod Identity Agent
test_pod_identity_agent() {
    echo "Testcase: Pod Identity Agent addon: Verify health and functionality"

    # Check for Pod Identity Agent pods
    pod_identity_pods=$(kubectl get pods -n kube-system -l app.kubernetes.io/instance=eks-pod-identity-agent -o json)

    # Check if pods were found
    if [[ $(echo "$pod_identity_pods" | jq '.items | length') -eq 0 ]]; then
        echo "FAIL: No Pod Identity Agent pods found."
        exit 1
    fi

    # Check the status of each Pod Identity Agent pod
    failed_pods=$(echo "$pod_identity_pods" | jq -r '.items[] | select(.status.phase != "Running") | [.metadata.name, .status.phase] | @tsv')
    if [[ -n "$failed_pods" ]]; then
        echo "FAIL: Some Pod Identity Agent pods are not in a Running state:"
        echo "$failed_pods"
        exit 1
    fi

    # Check Pod Identity Agent logs for errors or warnings
    found_errors=false
    while IFS= read -r pod; do
        namespace=$(echo "$pod" | jq -r '.metadata.namespace')
        name=$(echo "$pod" | jq -r '.metadata.name')

        logs=$(kubectl logs -n "$namespace" "$name" --tail=10 2>/dev/null | grep -i "error\|warning")

        if [[ -n "$logs" ]]; then
            echo "FAIL: Errors or warnings found in logs for pod $name in namespace $namespace."
            echo "Logs:"
            echo "$logs"
            echo ""
            found_errors=true
        fi
    done <<< "$(echo "$pod_identity_pods" | jq -c '.items[]')"

    # Determine the final result based on the findings
    if [[ "$found_errors" = true ]]; then
        echo "FAIL: Pod Identity Agent encountered issues. Review the logs for details."
        exit 1
    else
        echo "PASS: Pod Identity Agent is running correctly."
    fi
}

# Run the test
test_pod_identity_agent
