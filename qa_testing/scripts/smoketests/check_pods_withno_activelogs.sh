#!/usr/bin/env bash

#######################################################################
# Script Name: check_pods_with_no_activity_logs.sh
# Purpose: This script checks for any pods in a Kubernetes cluster that
#          are in problematic states (e.g., CrashLoopBackOff, Error)
#          but are not generating logs.
#
# The script performs the following checks:
#   1. Identifies pods that are in CrashLoopBackOff or Error states.
#   2. Verifies whether these pods are generating any logs.
#   3. Reports pods that are not generating logs as FAIL.
#
#######################################################################

# Temporary file to store logs
temp_file=$(mktemp)

# Variable to track if any pods are failing
result="PASS"
message=""

# Test case name
echo "Testcase name: Confirm if there are any pods which are not actively generating logs."

# Iterate over each pod in CrashLoopBackOff or Error state
kubectl get pods -A -o json | jq -r '
  .items[] |
  select(.status.containerStatuses[]? | .state.waiting.reason == "CrashLoopBackOff" or .state.terminated.reason == "Error") |
  [.metadata.namespace, .metadata.name] | @tsv' | while IFS=$'\t' read -r namespace pod; do

  # Get logs for the pod and save to a temporary file
  kubectl logs -n "$namespace" "$pod" --all-containers=true > "$temp_file" 2>/dev/null

  # If logs are empty, mark as FAIL and add to message
  if [ ! -s "$temp_file" ]; then
    result="FAIL"
    message+="Pod '$pod' in namespace '$namespace' is not generating logs.\n"
  fi
done

# Clean up temporary file
rm "$temp_file"

# Output the result
if [[ "$result" == "PASS" ]]; then
  echo "PASS: All problematic pods are actively generating logs."
else
  echo -e "FAIL: The following problematic pods are not generating logs:\n$message"
  exit 1
fi