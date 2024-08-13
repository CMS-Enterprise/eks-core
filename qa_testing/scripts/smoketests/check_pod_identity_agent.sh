#!/usr/bin/env bash

# Function to test Pod Identity Agent
test_pod_identity_agent() {
    local result="PASS"
    local message=""
    local found_errors=false

    echo "Testcase: Pod Identity Agent addon: Verify health and functionality"

    # Check Pod Identity Agent pods status
    pod_identity_pods=$(kubectl get pods -n kube-system -l app.kubernetes.io/instance=eks-pod-identity-agent -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers)

    if [[ -z "$pod_identity_pods" ]]; then
        message="FAIL: No Pod Identity Agent pods found."
        result="FAIL"
    else
        # Check Pod Identity Agent logs for errors and warnings
        while IFS= read -r pod; do
            namespace=$(echo "$pod" | awk '{print $1}')
            name=$(echo "$pod" | awk '{print $2}')

            # Check logs for the pod
            logs=$(kubectl logs -n "$namespace" "$name" --tail=4 2>/dev/null | grep -i "error\|warning")

            if [ ! -z "$logs" ]; then
                echo "FAIL: Errors or warnings found in pod $name."
                echo "Logs:"
                echo "$logs"
                echo ""
                result="FAIL"
                message="FAIL: Errors or warnings found in Pod Identity Agent logs."
                found_errors=true
            fi
        done <<< "$pod_identity_pods"
    fi

    # If no errors found, set result message to PASS
    if [ "$found_errors" = false ] && [[ "$result" == "PASS" ]]; then
        message="PASS: Pod Identity Agent is running correctly."
    fi

    # Output result message
    echo "$message"

    # Exit with the appropriate status code
    if [ "$result" == "FAIL" ]; then
        exit 1
    fi
}

# Run the test
test_pod_identity_agent
