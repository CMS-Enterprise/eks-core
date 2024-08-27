#!/usr/bin/env bash

#######################################################################
# Script Name: check_observability_enhanced.sh
# Purpose: This script verifies the health and functionality of the
#          Amazon CloudWatch observability addon within a Kubernetes cluster.
#
# The script performs the following checks:
#   1. Confirms the availability of the observability namespace and its pods.
#   2. Checks for any failed observability pods within the namespace.
#   3. Verifies that the specified metric is being delivered to CloudWatch.
#   4. Ensures that the target metric contains recent data points.
#
#######################################################################

# Check if the cluster name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cluster-name>"
    exit 1
fi

# Define variables
NAMESPACE="amazon-cloudwatch"
CLUSTER_NAME=$1
TARGET_METRIC="node_cpu_utilization"

echo "TestCase name: Observability addon: Verification of health and functionality."

# Check observability addon health
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "FAIL: Namespace $NAMESPACE does not exist or is not reachable."
    exit 1
fi

# Check for failed observability pods specifically
FAILED_PODS=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=amazon-cloudwatch-observability" -o json | jq -r '.items[] | select(.status.phase != "Running") | [.metadata.name, .status.phase] | @tsv')
if [[ -n "$FAILED_PODS" ]]; then
    echo "FAIL: The following observability pods are not in a Running state:"
    echo "$FAILED_PODS"
    exit 1
fi


# Retrieve metrics from CloudWatch
METRICS=$(aws cloudwatch list-metrics --namespace ContainerInsights --dimensions Name=ClusterName,Value="$CLUSTER_NAME" --output json | jq -r '.Metrics[].MetricName' | sort | uniq)
if [ -z "$METRICS" ]; then
    echo "FAIL: No metrics found in namespace $NAMESPACE."
    exit 1
fi

# Check if the target metric is in the list of metrics
if echo "$METRICS" | grep -q "$TARGET_METRIC"; then
    #echo "Metric $TARGET_METRIC is present in CloudWatch."

    # Check if the target metric has data
    if [ "$(uname)" == "Darwin" ]; then
        # macOS date command
        START_TIME=$(date -u -v -10M '+%Y-%m-%dT%H:%M:%SZ')
        END_TIME=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    else
        # GNU date command
        START_TIME=$(date -u -d '-10 minutes' '+%Y-%m-%dT%H:%M:%SZ')
        END_TIME=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    fi

    METRIC_DATA=$(aws cloudwatch get-metric-statistics \
        --namespace ContainerInsights \
        --metric-name $TARGET_METRIC \
        --dimensions Name=ClusterName,Value=$CLUSTER_NAME \
        --start-time $START_TIME \
        --end-time $END_TIME \
        --period 300 \
        --statistics Average \
        --query 'Datapoints[0]' \
        --output text)

    if [ "$METRIC_DATA" = "None" ]; then
        echo "FAIL: Metric $TARGET_METRIC does not have data in CloudWatch."
        exit 1
    fi
else
    echo "FAIL: Metric $TARGET_METRIC is not present in CloudWatch."
    exit 1
fi

echo "PASS: Observability is running healthy and metrics are being delivered to CloudWatch."