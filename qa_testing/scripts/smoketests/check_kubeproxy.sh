#!/usr/bin/env bash

# Function to test kube-proxy
test_kubeproxy() {
    local status_message=""
    echo "Testcase: Kube-Proxy addon: Verify health and functionality"

    # Initialize an array to capture step logs
    local step_logs=()

    # Check kube-proxy pods' statuses
    pod_status=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy -o jsonpath='{.items[*].status.phase}')
    for status in $pod_status; do
        if [[ "$status" != "Running" ]]; then
            status_message="FAIL: Kube-proxy pod is not in Running state. Current state: $status."
            step_logs+=("$status_message")
            for log in "${step_logs[@]}"; do echo "$log"; done
            return 1
        fi
    done

    # Describe kube-proxy pod to check for errors
    kubeproxy_describe=$(kubectl describe pod -n kube-system -l k8s-app=kube-proxy)
    if echo "$kubeproxy_describe" | grep -q "Error"; then
        status_message="FAIL: Errors found in kube-proxy pod description."
        step_logs+=("$status_message")
        for log in "${step_logs[@]}"; do echo "$log"; done
        return 1
    fi

    # Check kube-proxy logs for errors
    kubeproxy_logs=$(kubectl logs -n kube-system -l k8s-app=kube-proxy)
    if echo "$kubeproxy_logs" | grep -q "error"; then
        status_message="FAIL: Errors found in kube-proxy logs."
        step_logs+=("$status_message")
        for log in "${step_logs[@]}"; do echo "$log"; done
        return 1
    fi

    # Append the final status message
    for log in "${step_logs[@]}"; do echo "$log"; done
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