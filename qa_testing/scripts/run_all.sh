#!/bin/bash

# Log file path
SCRIPT_LOCATION=$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]:-$0}")")" &> /dev/null && pwd)
mkdir -p ${SCRIPT_LOCATION}/../logs
LOG_FILE="${SCRIPT_LOCATION}/../logs/run_all.log"

# Check if the correct number of parameters are passed
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <CLUSTER_NAME>"
    exit 1
fi

# Capture input parameter
CLUSTER_NAME="$1"

# Initialize the counter
SCRIPT_COUNTER=1
FAIL_COUNT=0

# Clear previous log file
> "$LOG_FILE"

# Function to execute child scripts and log output
run_test_script() {
    local script_name="$1"
    shift  # Remove the script_name from the list of arguments
    echo "***************************************************" | tee -a "$LOG_FILE"
    echo "Execute script-${SCRIPT_COUNTER}: $script_name" | tee -a "$LOG_FILE"

    # Execute the command and log both stdout and stderr
    if ! "$script_name" "$@" >> "$LOG_FILE" 2>&1; then
        echo "$script_name failed. Moving on to the next script." | tee -a "$LOG_FILE"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    # Increment the counter
    SCRIPT_COUNTER=$((SCRIPT_COUNTER + 1))
}

#Execute child scripts in the specified order
run_test_script "smoketest_check_cluster_health.sh"
run_test_script "smoketest_check_pods_withno_activelogs.sh"
run_test_script "smoketest_check_pods_triggering_errors.sh"
run_test_script "smoketest_kubeproxy.sh"
run_test_script "smoketest_coredns.sh"
run_test_script "smoketest_pod_identity_agent.sh"
run_test_script "smoketest_fluentbit_check.sh" "$CLUSTER_NAME"
run_test_script "smoketest_observability_check_enhanced.sh" "$CLUSTER_NAME"
run_test_script "smoketest_vpccni_check.sh" "$CLUSTER_NAME"
run_test_script "smoketest_loadbalncer_check.sh" "$CLUSTER_NAME"
run_test_script "smoketest_ebscsi_check.sh" "$CLUSTER_NAME"
run_test_script "smoketest_efscsi_check.sh" "$CLUSTER_NAME"

echo "***************************************************" | tee -a "$LOG_FILE"

# Provide the final status based on the result
if [ $FAIL_COUNT -eq 0 ]; then
    echo "PASS: ALl smoke test scripts executed successfully" | tee -a "$LOG_FILE"
else
    echo "FAIL: $FAIL_COUNT test scripts failed" | tee -a "$LOG_FILE"
fi
echo "TestSuite logs are saved to $LOG_FILE"
[ $FAIL_COUNT -eq 0 ]