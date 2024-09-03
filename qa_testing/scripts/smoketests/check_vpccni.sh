#!/usr/bin/env bash

#######################################################################
# Script Name: check_vpccni.sh
# Purpose: This script verifies the health and functionality of the
#          VPC CNI Addon within an EKS cluster.
#
# The script performs the following checks:
#   1. Ensures subnets and security groups are correctly configured.
#   2. Validates that subnets cover all availability zones.
#   3. Confirms that pods are getting IPs from container subnets.
#   4. Ensures that pod IPs are within valid CIDR ranges.
#
#######################################################################

# Check if the cluster name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cluster-name>"
    exit 1
fi

CLUSTER_NAME=$1
FAILED=0

echo "TestCase name: VPC CNI Addon: Validate health & functionality"

# Sub-testcase 1: Verify that subnets and security groups are configured correctly

# Retrieve subnets for the specified cluster
SUBNETS=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query 'cluster.resourcesVpcConfig.subnetIds' --output text)
if [ -z "$SUBNETS" ]; then
    echo "FAIL: No subnets found for cluster: $CLUSTER_NAME"
    FAILED=1
else
    # Retrieve VPC ID for the cluster
    VPC_ID=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query 'cluster.resourcesVpcConfig.vpcId' --output text)

    # Get availability zones for the VPC
    EXPECTED_ZONES=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" --query 'Subnets[*].AvailabilityZone' --output text | sort | uniq)

    # Check if the subnets cover all zones
    SUBNET_ZONES=$(aws ec2 describe-subnets --subnet-ids $SUBNETS --query 'Subnets[*].AvailabilityZone' --output text | sort | uniq)

    # Compare the expected zones with the zones covered by subnets
    for zone in $EXPECTED_ZONES; do
        if ! echo "$SUBNET_ZONES" | grep -q "$zone"; then
            echo "FAIL: Not all availability zones are covered by subnets. Missing zone: $zone"
            FAILED=1
        fi
    done
fi

# Retrieve security groups for the specified cluster
SECURITY_GROUPS=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query 'cluster.resourcesVpcConfig.securityGroupIds' --output text)
if [ -z "$SECURITY_GROUPS" ]; then
    echo "FAIL: No security groups found for cluster: $CLUSTER_NAME"
    FAILED=1
fi

# Sub-testcase 2: Ensure pods are getting IPs from container subnets

# Get pods with the same IP as their nodes
POD_DETAILS=$(kubectl get pods -o wide --all-namespaces | awk '
NR>1 {
  pod_ip = $7
  node_dns = $8
  gsub(/ip-/, "", node_dns)
  gsub(/\..*/, "", node_dns)
  gsub(/-/, ".", node_dns)
  if (pod_ip == node_dns) {
    print "Namespace: " $1 ", Pod: " $2 ", Pod IP: " $7 ", Node IP: " $8
  }
}')

# Check if POD_DETAILS is empty
if [ -z "$POD_DETAILS" ]; then
    echo "FAIL: No pods found with the same IP as their nodes."
    FAILED=1
fi

# Sub-testcase 3: Ensure pod IPs are within valid CIDR ranges

# Function to get the list of Pod IPs
get_pod_ips() {
    kubectl get pods -A -o wide | awk 'NR>1 {print $7}'
}

# Function to get the list of CIDRs
get_cidrs() {
    aws ec2 describe-subnets --query "Subnets[?Tags[?Key=='Name' && contains(Value, 'unroutable')]].{CidrBlock:CidrBlock}" --output text
}

# Function to check if an IP is in a CIDR range
ip_in_cidr() {
    local ip="$1"
    local cidr="$2"

    # Use `ipcalc` to check if the IP is in the CIDR range
    ipcalc -c "$ip" "$cidr" &> /dev/null
}

# Collect Pod IPs
pod_ips=($(get_pod_ips))

# Collect CIDRs
cidrs=($(get_cidrs))

# Verify if Pod IPs are within CIDR ranges
for ip in "${pod_ips[@]}"; do
    ip_found=0
    for cidr in "${cidrs[@]}"; do
        if ip_in_cidr "$ip" "$cidr"; then
            ip_found=1
            break
        fi
    done
    if [ $ip_found -eq 0 ]; then
        FAILED=1
        echo "FAIL: Pod IP $ip is not within any CIDR range."
    fi
done

# Print final pass/fail message
if [ $FAILED -eq 0 ]; then
    echo "PASS: VPC CNI Addon testcase passed."
else
    echo "FAIL: VPC CNI Addon testcase failed."
    exit 1
fi