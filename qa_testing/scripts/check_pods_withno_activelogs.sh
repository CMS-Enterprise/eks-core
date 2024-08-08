#!/bin/bash

# Temporary file to store logs
temp_file=$(mktemp)

# Variable to track if any pods are failing
result="PASS"
message=""

# Iterate over each pod and namespace
kubectl get pods -A -o json | jq -r '
  .items[] |
  select(.status.containerStatuses[]? | .state.waiting.reason == "CrashLoopBackOff" or .state.terminated.reason == "Error") |
  [.metadata.namespace, .metadata.name] | @tsv' | while IFS=$'\t' read -r namespace pod; do
  # Get logs for the pod and save to a temporary file
  kubectl logs -n "$namespace" "$pod" --all-containers=true > "$temp_file"

  # If logs are empty, mark as FAIL and add to message
  if [ ! -s "$temp_file" ]; then
    result="FAIL"
    message+="Podname '$pod' is not actively triggering error in namespace '$namespace'.\n"
  fi
done

# Clean up temporary file
rm "$temp_file"

# Test case name
echo "********************************************************************************"
echo "Testcase name: Confirm, are there any pods which are not actively triggering logs?"

# Output the result
if [[ "$result" == "PASS" ]]; then
  echo "PASS: all pods are actively triggering logs"
else
  echo -e "FAIL: $message"
fi
