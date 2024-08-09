#!/bin/bash

# Function to test CoreDNS
test_coredns() {

    echo "Testcase: CoreDNS addon: Verify health and functionality"
   
    # Verify CoreDNS Pod Status
    coredns_pods=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[*].status.phase}')
    for status in $coredns_pods; do
        if [[ "$status" != "Running" ]]; then
            echo "FAIL: CoreDNS pod is not in Running state. Current state: $status."
            return 1
        fi
    done

    # Check CoreDNS Pod Logs
    coredns_logs=$(kubectl logs -n kube-system -l k8s-app=kube-dns)
    if echo "$coredns_logs" | grep -q "error"; then
        echo "FAIL: Errors found in CoreDNS pod logs."
        return 1
    fi

    # CoreDNS Service Availability
    coredns_service=$(kubectl get svc kube-dns -n kube-system -o jsonpath='{.spec.clusterIP}')
    if [[ -z "$coredns_service" ]]; then
         echo "FAIL: CoreDNS service is not available or has no cluster IP."
        return 1
    fi

    # CoreDNS Endpoints
    coredns_endpoints=$(kubectl get endpoints kube-dns -n kube-system -o jsonpath='{.subsets[*].addresses[*].ip}')
    if [[ -z "$coredns_endpoints" ]]; then
         echo "FAIL: CoreDNS endpoints are not correctly populated."
        return 1
    fi

    return 0
}

# Run the test and capture the result
test_coredns
result=$?

# Provide the final status based on the result
if [ $result -eq 0 ]; then
    echo "PASS: CoreDNS is running correctly."
else
    echo "FAIL: CoreDNS is not running correctly."
fi
