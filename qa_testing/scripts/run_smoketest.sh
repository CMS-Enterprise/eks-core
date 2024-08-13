#!/usr/bin/env bash

# Log file path
SCRIPT_LOCATION=$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]:-$0}")")" &> /dev/null && pwd)
mkdir -p ${SCRIPT_LOCATION}/../logs
LOG_FILE="${SCRIPT_LOCATION}/../logs/run_all_smoketest_temp.log"

# Check if the temp log file exists and delete it if it does
if [ -f "$LOG_FILE" ]; then
    echo "Existing temp log file found and removed: $LOG_FILE"
    rm "$LOG_FILE"
fi

# Initialize the counter
SCRIPT_COUNTER=1
FAIL_COUNT=0

# Clear previous log file
> "$LOG_FILE"

# Check if the correct number of parameters are passed
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <CLUSTER_NAME> <all|script_name>"
  exit 1
fi

# Get the cluster name and test script from the arguments
CLUSTER_NAME="$1"
TEST_SCRIPT="$2"

# Get a list of all scripts in the smoketests subdirectory
SMOKETEST_DIR="${SCRIPT_LOCATION}/smoketests"
SMOKETEST_SCRIPTS=($(ls "$SMOKETEST_DIR"))

# Verify if the provided cluster name matches an accessible EKS cluster
CLUSTERS=$(aws eks list-clusters --query clusters --output text)

cluster_found=false
for cluster in $CLUSTERS; do
    if [ "$cluster" == "$CLUSTER_NAME" ]; then
        cluster_found=true
        break
    fi
done

if [ "$cluster_found" = false ]; then
    echo "Error: No matching EKS cluster found for '$CLUSTER_NAME'."
    exit 1
fi

# Check the current kubeconfig context
CURRENT_CONTEXT=$(kubectl config current-context)

# Determine the expected context name based on the cluster name
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
EXPECTED_CONTEXT="arn:aws:eks:us-east-1:${ACCOUNT_ID}:cluster/${CLUSTER_NAME}"

# If the current context doesn't match the expected context, prompt the user
if [ "$CURRENT_CONTEXT" != "$EXPECTED_CONTEXT" ]; then
  echo "Current kubeconfig context does not match the target cluster."
  echo "Current context: $CURRENT_CONTEXT"
  echo "Target cluster context: $EXPECTED_CONTEXT"
  read -p "Do you want to switch to the target cluster context? (yes/no): " RESPONSE
  if [ "$RESPONSE" == "yes" ]; then
    aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region us-east-1
    echo "Switched to the target cluster context."
  else
    echo "Aborting script as the kubeconfig context was not switched."
    exit 1
  fi
fi

echo "***************************************************" | tee -a "$LOG_FILE"
EKS_CLUSTER_VERSION=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query cluster.version --output text)
echo "EKS Cluster Version: $EKS_CLUSTER_VERSION" | tee -a "$LOG_FILE"

# Function to execute child scripts and log output
run_test_script() {
  local script_name="$1"
  shift  # Remove the script_name from the list of arguments
  local script_path="${SMOKETEST_DIR}/${script_name}"

  echo "***************************************************" | tee -a "$LOG_FILE"
  echo "Execute script-${SCRIPT_COUNTER}: $script_name" | tee -a "$LOG_FILE"

  # Execute the command and log both stdout and stderr
  if ! "$script_path" "$@" >> "$LOG_FILE" 2>&1; then
    echo "FAILED: Proceeding to the next smoketest." | tee -a "$LOG_FILE"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    echo "PASSED: Proceeding to the next smoketest." | tee -a "$LOG_FILE"
  fi

  # Increment the counter
  SCRIPT_COUNTER=$((SCRIPT_COUNTER + 1))
}

# Check if the second argument is "all"
if [ "$TEST_SCRIPT" == "all" ]; then
  # Run all scripts in the smoketests directory
  for script in "${SMOKETEST_SCRIPTS[@]}"; do
    run_test_script "$script" "$CLUSTER_NAME"
  done
else
  # Flag to track if the script is found
  script_exists=false

  # Loop through each script in the SMOKETEST_SCRIPTS array
  for script in "${SMOKETEST_SCRIPTS[@]}"; do
      if [ "$script" == "$TEST_SCRIPT" ]; then
          script_exists=true
          break
      fi
  done

  # Check if the script was found
  if [ "$script_exists" = true ]; then
      # Run the specified script
      run_test_script "$TEST_SCRIPT" "$CLUSTER_NAME"
  else
      # If the script name is not valid, show the usage statement
      echo "Invalid script name: $TEST_SCRIPT"
      echo "Usage: $0 <CLUSTER_NAME> <all|script_name>"
      exit 1
  fi
fi

##Execute child scripts in the specified order
#run_test_script "check_cluster_health.sh"
#run_test_script "check_pods_withno_activelogs.sh"
#run_test_script "check_pods_triggering_errors.sh"
#run_test_script "check_kubeproxy.sh"
#run_test_script "check_coredns.sh"
#run_test_script "check_pod_identity_agent.sh"
#run_test_script "check_fluentbit.sh" "$CLUSTER_NAME"
#run_test_script "check_observability_enhanced.sh" "$CLUSTER_NAME"
#run_test_script "check_vpccni.sh" "$CLUSTER_NAME"
#run_test_script "check_loadbalncer.sh" "$CLUSTER_NAME"
#run_test_script "check_ebscsi.sh" "$CLUSTER_NAME"
#run_test_script "check_efscsi.sh" "$CLUSTER_NAME"


echo "***************************************************" | tee -a "$LOG_FILE"
# Provide the final status based on the result
if [ $FAIL_COUNT -eq 0 ]; then
  echo "PASS: All smoketest scripts executed successfully" | tee -a "$LOG_FILE"
else
  echo "FAIL: $FAIL_COUNT smoketest scripts failed" | tee -a "$LOG_FILE"
fi

# Determine the correct date command for the system
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  TIMESTAMP=$(date +"%Y%m%d%H%M%S")
elif [[ "$OSTYPE" == "darwin"* ]]; then
  TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")
else
  echo "Unsupported OS: $OSTYPE"
  exit 1
fi

# Determine the suffix based on the FAIL_COUNT
if [ $FAIL_COUNT -eq 0 ]; then
  SUFFIX="_PASSED"
else
  SUFFIX="_FAILED"
fi

# Construct the new log file name
NEW_LOG_FILE="${SCRIPT_LOCATION}/../logs/${TIMESTAMP}_run_all_smoketest_on_${CLUSTER_NAME}${SUFFIX}.log"

# Rename the log file adding date and time and the suffix based on pass/fail condition
mv "$LOG_FILE" "$NEW_LOG_FILE"

# Output the final log file name
echo "Smoke Test Suite logs saved to: $NEW_LOG_FILE"

# Exit with the correct return status
[ $FAIL_COUNT -eq 0 ]