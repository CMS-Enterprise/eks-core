#!/usr/bin/env bash

# Ensure the script is running in bash >= 5.2
if ! bash --version | grep -qE 'version ([5-9]|[0-9]{2,})\.[2-9]'; then
  echo "Error: This script requires bash version 5.2 or higher."
  exit 1
fi

# Validate the OS and set the timestamp accordingly
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  TIMESTAMP=$(date +"%Y%m%d%H%M%S")
elif [[ "$OSTYPE" == "darwin"* ]]; then
  TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")
else
  echo "Unsupported OS: $OSTYPE"
  exit 1
fi

# Check if the correct number of parameters are passed
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <CLUSTER_NAME> <all|script_name>"
  exit 1
fi

# Set argument variables
CLUSTER_NAME="$1"
TEST_SCRIPT="$2"

# Set global variables
SCRIPT_COUNTER=1
FAIL_COUNT=0
AWS_REGION="us-east-1"

# Log file path
SCRIPT_LOCATION=$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]:-$0}")")" &> /dev/null && pwd)
mkdir -p ${SCRIPT_LOCATION}/../logs
LOG_FILE="${SCRIPT_LOCATION}/../logs/run_smoketest_temp.log"

# Clear previous log file
: > "$LOG_FILE"

# Get a list of all valid scripts in the smoketests subdirectory
SMOKETEST_DIR="${SCRIPT_LOCATION}/smoketests"

# Validate if the provided script parameter is valid (all or specific script name)
mapfile -t SMOKETEST_SCRIPTS < <(find "$SMOKETEST_DIR" -maxdepth 1 -type f -iname "check*.sh" -exec basename {} \; | sort)

# Check if the second argument is "all or valid script name"
if [ "$TEST_SCRIPT" == "all" ]; then
  RUN_ALL=true
else
  RUN_ALL=false
  script_exists=false

  for script in "${SMOKETEST_SCRIPTS[@]}"; do
    if [ "$script" == "$TEST_SCRIPT" ]; then
      script_exists=true
      break
    fi
  done

  if [ "$script_exists" = false ]; then
    echo "Invalid Smoketest Script: $TEST_SCRIPT"
    echo "Available Smoketest Scripts are:"
    for script in "${SMOKETEST_SCRIPTS[@]}"; do
      echo "    - $script"
    done
    echo ""
    echo "Usage: $0 <CLUSTER_NAME> <all|smoketest_script_name>"
    exit 1
  fi
fi

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
    echo "Available EKS clusters:"
    echo "$CLUSTERS"
    exit 1
fi

# Validate network access to AWS EKS endpoint using curl
if ! curl -s --connect-timeout 5 https://eks.${AWS_REGION}.amazonaws.com >/dev/null 2>&1; then
  echo "Error: Network connectivity issue detected. Unable to reach the AWS EKS endpoint."
  exit 1
fi

# Validate access to AWS account
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "Error: Unable to access AWS. Please ensure your credentials are valid and properly configured."
  exit 1
fi

# Check the current kubeconfig context
CURRENT_CONTEXT=$(kubectl config current-context)

# Determine the expected context name based on the cluster name
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
EXPECTED_CONTEXT="arn:aws:eks:${AWS_REGION}:${ACCOUNT_ID}:cluster/${CLUSTER_NAME}"

# If the current context doesn't match the expected context, prompt the user
if [ "$CURRENT_CONTEXT" != "$EXPECTED_CONTEXT" ]; then
  echo "Current kubeconfig context does not match the target cluster."
  echo "Current context: $CURRENT_CONTEXT"
  echo "Target cluster context: $EXPECTED_CONTEXT"
  read -p "Do you want to switch to the target cluster context? (yes/no): " RESPONSE
  if [ "$RESPONSE" == "yes" ]; then
    aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${AWS_REGION}"
    echo "Switched to the target cluster context."
  else
    echo "Aborting script as the kubeconfig context was not switched."
    exit 1
  fi
fi

# Log header information
echo "***************************************************" | tee -a "$LOG_FILE"
echo "Script Execution Started at: ${TIMESTAMP}" | tee -a "$LOG_FILE"
echo "Target Cluster: $CLUSTER_NAME" | tee -a "$LOG_FILE"
EKS_CLUSTER_VERSION=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query cluster.version --output text)
echo "EKS Cluster Version: $EKS_CLUSTER_VERSION" | tee -a "$LOG_FILE"

# Display the smoketest being run
if [ "$TEST_SCRIPT" == "all" ]; then
  echo "Running Smoketest: all" | tee -a "$LOG_FILE"
else
  echo "Running Smoketest: $TEST_SCRIPT" | tee -a "$LOG_FILE"
fi

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

# Run the appropriate scripts
if [ "$RUN_ALL" = true ]; then
  for script in "${SMOKETEST_SCRIPTS[@]}"; do
    run_test_script "$script" "$CLUSTER_NAME"
  done
else
  run_test_script "$TEST_SCRIPT" "$CLUSTER_NAME"
fi

echo "***************************************************" | tee -a "$LOG_FILE"
# Provide the final status based on the result
if [ $FAIL_COUNT -eq 0 ]; then
  echo "PASS: All smoketest scripts executed successfully" | tee -a "$LOG_FILE"
else
  echo "FAIL: $FAIL_COUNT smoketest scripts failed" | tee -a "$LOG_FILE"
fi

# Determine the suffix based on the FAIL_COUNT
if [ $FAIL_COUNT -eq 0 ]; then
  SUFFIX="_PASSED"
else
  SUFFIX="_FAILED"
fi

# Construct the new log file name based on the second argument
if [ "$TEST_SCRIPT" == "all" ]; then
  NEW_LOG_FILE="${SCRIPT_LOCATION}/../logs/${TIMESTAMP}_run_all_smoketests_on_${CLUSTER_NAME}${SUFFIX}.log"
else
  script_name_without_ext="${TEST_SCRIPT%.*}"
  NEW_LOG_FILE="${SCRIPT_LOCATION}/../logs/${TIMESTAMP}_smoketest_${script_name_without_ext}_on_${CLUSTER_NAME}${SUFFIX}.log"
fi

# Remove the "scripts/../" portion from the log file path
NEW_LOG_FILE=$(realpath "$NEW_LOG_FILE")

# Rename the log file adding date and time and the suffix based on pass/fail condition
mv "$LOG_FILE" "$NEW_LOG_FILE"

# Output the final log file name
echo "Smoketest logs saved to: $NEW_LOG_FILE"

# Exit with the correct return status
[ $FAIL_COUNT -eq 0 ]