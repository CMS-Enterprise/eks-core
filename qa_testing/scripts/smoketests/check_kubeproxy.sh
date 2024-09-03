#!/usr/bin/env bash

#######################################################################
# Script Name: check_kubeproxy.sh
# Purpose: This script verifies the health and functionality of the
#          kube-proxy component within a Kubernetes cluster.
#
# The script performs the following checks:
#   1. Verifies that all kube-proxy pods are in a Running state.
#   2. Checks kube-proxy pod descriptions for any reported errors.
#   3. Analyzes kube-proxy logs to detect any errors.
#
#######################################################################

# Function to test kube-proxy
test_kubeproxy() {
    echo "Testcase: Kube-Proxy addon: Verify health and functionality"

    # Check kube-proxy pods' statuses
    pod_status=$(kubectl get pods -n kube-system -l "k8s-app=kube-proxy" -o jsonpath='{.items[*].status.phase}')
    for status in $pod_status; do
        if [[ "$status" != "Running" ]]; then
            echo "FAIL: Kube-proxy pod '$pod_name' is not in Running state. Current state: $pod_status."
            return 1
        fi
    done

    # Describe kube-proxy pods to check for errors
    kubeproxy_describe=$(kubectl describe pod -n kube-system -l "k8s-app=kube-proxy")
    if echo "$kubeproxy_describe" | grep -qi "error"; then
        echo "FAIL: Errors found in kube-proxy pod description."
        return 1
    fi

    # Check kube-proxy logs for errors
    kubeproxy_logs=$(kubectl logs -n kube-system -l "k8s-app=kube-proxy")
    if echo "$kubeproxy_logs" | grep -qi "error"; then
        echo "FAIL: Errors found in the logs of kube-proxy pod '$pod_name'."
        return 1
    fi

    return 0
}

# Run the test and capture the result
test_kubeproxy
result=$?

# Provide the final status based on the result
if [ $result -eq 0 ]; then
    echo "PASS: Kube-proxy is running correctly."
else
    echo "FAIL: Kube-proxy is not running correctly."
    exit 1
fi