#!/usr/bin/env bash

#######################################################################
# Script Name: check_coredns.sh
# Purpose: This script verifies the health and functionality of the
#          CoreDNS component within a Kubernetes cluster.
#
# The script performs the following checks:
#   1. Verifies that all CoreDNS pods are in a Running state.
#   2. Checks the CoreDNS pod logs for errors (keywords: error, fail,
#      crash, timeout).
#   3. Confirms that the CoreDNS service is available and has a
#      configured cluster IP.
#   4. Ensures that the CoreDNS endpoints are correctly populated.
#
#######################################################################

# Load common utilities and variables
source "$(dirname "${BASH_SOURCE[0]}")/../libraries/general_funcs_vars.sh"

# Function to test CoreDNS
test_coredns() {

    echo "Testcase: CoreDNS addon: Verify health and functionality"
    local result=0  # Default to pass

    # Verify CoreDNS Pod Status
    echo "Checking CoreDNS pod status..."
    coredns_pods=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.phase}{"\n"}{end}')
    if [[ -z "$coredns_pods" ]]; then
        echo "FAIL: No CoreDNS pods found."
        return 1
    fi

    echo "$coredns_pods" | while read -r pod_name pod_status; do
        if [[ "$pod_status" != "Running" ]]; then
            echo "FAIL: CoreDNS pod '$pod_name' is not in Running state. Current state: $pod_status."
            result=1
        fi
    done

    # Check CoreDNS Pod Logs for Errors
    echo "Checking CoreDNS pod logs for errors..."
    coredns_logs=$(kubectl logs -n kube-system -l k8s-app=kube-dns --tail=100)
    if echo "$coredns_logs" | grep -Eqi "error|fail|crash|timeout"; then
        echo "FAIL: Errors found in CoreDNS pod logs."
        result=1
    fi

    # CoreDNS Service Availability
    echo "Checking CoreDNS service availability..."
    coredns_service=$(kubectl get svc kube-dns -n kube-system -o jsonpath='{.spec.clusterIP}')
    if [[ -z "$coredns_service" ]]; then
        echo "FAIL: CoreDNS service is not available or has no cluster IP."
        result=1
    fi

    # CoreDNS Endpoints
    echo "Checking CoreDNS endpoints..."
    coredns_endpoints=$(kubectl get endpoints kube-dns -n kube-system -o jsonpath='{.subsets[*].addresses[*].ip}')
    if [[ -z "$coredns_endpoints" ]]; then
        echo "FAIL: CoreDNS endpoints are not correctly populated."
        result=1
    fi

    return $result
}

# Run the test and capture the result
test_coredns
result=$?

# Provide the final status based on the result
if [ $result -eq 0 ]; then
    echo "PASS: CoreDNS is running correctly."
else
    echo "FAIL: CoreDNS is not running correctly."
    exit 1
fi
