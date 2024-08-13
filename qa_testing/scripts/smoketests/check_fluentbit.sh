#!/usr/bin/env bash

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

# Check if FluentBit pods are running
FLUENT_BIT_PODS=$(kubectl get pods -n $NAMESPACE | grep $FLUENT_BIT_LABEL)
if [ -z "$FLUENT_BIT_PODS" ]; then
  echo "FAIL: FluentBit pods are not running."
  exit 1
fi

# Test Case 2: Verification of logs forwarding to CloudWatch
aws logs describe-log-streams \
    --log-group-name "$LOG_GROUP_NAME" \
    --query 'logStreams[*].logStreamName' \
    --output text > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "FAIL: Log group $LOG_GROUP_NAME not found or unable to describe log streams."
  exit 1
fi

LOG_STREAMS=$(aws logs describe-log-streams \
    --log-group-name "$LOG_GROUP_NAME" \
    --order-by "LastEventTime" \
    --descending \
    --limit 1 \
    --query 'logStreams[*].logStreamName' \
    --output text)

if [ -z "$LOG_STREAMS" ]; then
  echo "FAIL: No log streams found for cluster $CLUSTER_NAME in log group $LOG_GROUP_NAME."
  exit 1
fi

echo "PASS: Fluent-bit is running healthy and logs are forwarding to CloudWatch."
exit 0