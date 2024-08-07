#!/bin/bash
echo "**************************************************************************"
echo "Testcase: Confirm, are there any pods which are actively triggering errors"

# Function to check if pods are actively triggering errors
check_pod_errors() {
    local result="PASS"
    local error_pods=()

    # Get all pod names and their namespaces
    pods=$(kubectl get pods -A --no-headers -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name)

    # Function to check logs for a specific pod
    check_pod_logs() {
        local namespace=$1
        local name=$2
        local pod_logs
        pod_logs=$(kubectl logs -n "$namespace" "$name" --tail=4 2>/dev/null | grep -i "error")
        if [ ! -z "$pod_logs" ]; then
            echo "FAIL: The following pod is actively triggering errors:"
            echo "Pod Name: $name"
            echo "Logs: $pod_logs"
            echo ""
            error_pods+=("$name in namespace $namespace")
        fi
    }

    export -f check_pod_logs

    # Process each pod in parallel to improve speed
    echo "$pods" | while IFS= read -r pod; do
        namespace=$(echo "$pod" | awk '{print $1}')
        name=$(echo "$pod" | awk '{print $2}')

        # Using xargs to run checks in parallel
        echo "$namespace $name" | xargs -n2 -P10 bash -c 'check_pod_logs "$@"' _
    done

    # Wait for all background jobs to complete
    wait

    if [[ ${#error_pods[@]} -eq 0 ]]; then
        echo "PASS: There are no active pods which are triggering errors."
    else
        echo "FAIL: The following pods are actively triggering errors:"
        for pod in "${error_pods[@]}"; do
            echo "    $pod"
        done
    fi
}

# Execute the function
check_pod_errors