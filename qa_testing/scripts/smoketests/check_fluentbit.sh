#!/usr/bin/env bash

#######################################################################
# Script Name: check_fluentbit.sh
# Purpose: This script verifies the health and functionality of the
#          Fluent Bit logging addon within a Kubernetes cluster.
#
# The script performs the following checks:
#   1. Verifies that Fluent Bit Pods are running in the correct namespace.
#   2. Checks if logs are being forwarded to Amazon CloudWatch in the
#      appropriate log group.
#
#######################################################################

# Check arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cluster-name>"
    exit 1
fi

CLUSTER_NAME="$1"
NAMESPACE="amazon-cloudwatch"
FLUENT_BIT_LABEL="fluent-bit"

# Derive log group name from cluster name
LOG_GROUP_NAME="/aws/containerinsights/$CLUSTER_NAME/application"

# Test Case 1: Verification of FluentBit health
echo "TestCase name: Fluent-bit addon: Verification of health and functionality."

# Check if Fluent Bit Pods are running in the expected namespace
# Ensure the label "app.kubernetes.io/name=fluent-bit" is accurate for your deployment
if ! kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=$FLUENT_BIT_LABEL,app=$FLUENT_BIT_LABEL" >/dev/null 2>&1; then
    echo "FAIL: Fluent Bit Pods are not running in namespace '$NAMESPACE'."
    exit 1
fi

# Test Case 2: Verification of logs forwarding to CloudWatch

# Step 1: Check if the log group exists
if ! aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP_NAME" >/dev/null 2>&1; then
    echo "FAIL: Log group $LOG_GROUP_NAME does not exist."
    exit 1
fi

# Step 2: Verify that log streams exist and retrieve the most recent one
# If no logs are found, it could indicate low activity rather than a configuration issue
retry_count=0
max_retries=3
while [ $retry_count -lt $max_retries ]; do
    LOG_STREAMS=$(aws logs describe-log-streams \
      --log-group-name "$LOG_GROUP_NAME" \
      --order-by "LastEventTime" \
      --descending \
      --limit 1 \
      --query 'logStreams[*].logStreamName' \
      --output text)

    if [ -n "$LOG_STREAMS" ]; then
        break
    fi

    retry_count=$((retry_count + 1))
    echo "Retrying log stream check... Attempt $retry_count of $max_retries."
    sleep 5  # Wait a few seconds before retrying
done

if [ -z "$LOG_STREAMS" ]; then
    echo "FAIL: No log streams found for cluster '$CLUSTER_NAME' in log group '$LOG_GROUP_NAME'."
    exit 1
fi

echo "PASS: Fluent Bit is running healthy and logs are forwarding to CloudWatch."
exit 0