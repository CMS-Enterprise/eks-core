#!/bin/bash

# Check if the cluster name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cluster-name>"
    exit 1
fi

# Define variables
NAMESPACE="amazon-cloudwatch"
CLUSTER_NAME=$1
TARGET_METRIC="node_cpu_utilization"

echo "*************************************************************************"
echo "TestCase name: Observability addon: Verification of health and functionality."

# Check observability addon health
kubectl get pods -n $NAMESPACE > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "FAIL: Failed to get pods in namespace: $NAMESPACE"
    exit 1
fi

FAILED_PODS=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=amazon-cloudwatch-observability)
if [ -z "$FAILED_PODS" ]; then
  echo "FAIL : Observability addon has unhealthy pods."
  exit 1
fi

# Retrieve metrics from CloudWatch
METRICS=$(aws cloudwatch list-metrics --namespace ContainerInsights --dimensions Name=ClusterName,Value=$CLUSTER_NAME --output json | jq -r '.Metrics[].MetricName' | sort | uniq)
if [ -z "$METRICS" ]; then
    echo "No metrics found in namespace: $NAMESPACE"
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