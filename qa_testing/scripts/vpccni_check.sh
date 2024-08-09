#!/bin/bash

# Check if the cluster name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cluster-name>"
    exit 1
fi

CLUSTER_NAME=$1
FAILED=0

#echo "**************************************************************"
echo "TestCase name: VPC CNI Addon: Validate health & functionality"

# "*****************************************************************************************"
# Sub-testcase1: verify whether security group, and subnet are populating for all three zones.

# Retrieve subnets for the specified cluster
SUBNETS=$(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.resourcesVpcConfig.subnetIds' --output text)
if [ -z "$SUBNETS" ]; then
    echo "FAIL: No subnets found for cluster: $CLUSTER_NAME"
    FAILED=1
else
    # Retrieve VPC ID for the cluster
    VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.resourcesVpcConfig.vpcId' --output text)

    # Get availability zones for the VPC
    EXPECTED_ZONES=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID --query 'Subnets[*].AvailabilityZone' --output text | sort | uniq)

    # Check if the subnets cover all zones
    SUBNET_ZONES=$(aws ec2 describe-subnets --subnet-ids $SUBNETS --query 'Subnets[*].AvailabilityZone' --output text | sort | uniq)

    # Convert the output to arrays for comparison
    IFS=$'\t' read -r -a expected_zones <<< "$EXPECTED_ZONES"
    IFS=$'\t' read -r -a subnet_zones <<< "$SUBNET_ZONES"

    # Loop through each expected zone and check if it's covered
    for zone in "${expected_zones[@]}"; do
        zone_found=0
        for subnet_zone in "${subnet_zones[@]}"; do
            if [ "$zone" == "$subnet_zone" ]; then
                zone_found=1
                break
            fi
        done

        if [ "$zone_found" -eq 0 ]; then
            echo "FAIL: Not all availability zones are covered by subnets. Missing zone: $zone"
            FAILED=1
        fi
    done
fi

# Retrieve security groups for the specified cluster
SECURITY_GROUPS=$(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.resourcesVpcConfig.securityGroupIds' --output text)
if [ -z "$SECURITY_GROUPS" ]; then
    echo "FAIL: No security groups found for cluster: $CLUSTER_NAME"
    FAILED=1
fi

# "*****************************************************************************************"
# Sub-testcase2: Ensure pods are getting IP's from the container subnets

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

# "*****************************************************************************************"
# Sub-testcase3: Ensure pods have the same IP as the node they sit on

# Function to get the list of Pod IPs
function get_pod_ips() {
    kubectl get pods -A -o wide | awk 'NR>1 {print $7}'
}

# Function to get the list of CIDRs
function get_cidrs() {
    aws ec2 describe-subnets --query "Subnets[?Tags[?Key=='Name' && contains(Value, 'unroutable')]].{CidrBlock:CidrBlock}" --output text
}

# Function to check if an IP is in a CIDR range
function ip_in_cidr() {
    local ip="$1"
    local cidr="$2"

    # Use ipcalc to check if the IP is in the CIDR range
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
fi