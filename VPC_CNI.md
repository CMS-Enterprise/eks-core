# Efficient Use of IPv4 Address Space in Kubernetes with VPC CNI

## Table of Contents
1. **Overview**
2. **Importance of Secondary Unroutable CIDR Blocks**
3. **Primary and Secondary IP Address Ranges**
4. **Pod IP Allocation Strategy**
5. **Configuration Files for CNI**
6. **Identifying and Resolving Primary vs. Secondary IP Address Assignment Issues**
7. **Troubleshooting IP Address Exhaustion**
8. **Practical Examples**
9. **References**

---

## 1. Overview

Efficient use of IPv4 address space is critical in modern cloud environments due to the limited availability of IPv4 addresses. Effective management ensures optimal resource utilization, minimizes IP exhaustion, and enhances network performance. The Amazon VPC CNI plugin for Kubernetes helps manage IP address assignments for pods within a VPC, supporting both primary and secondary CIDR blocks.

## 2. Importance of Secondary Unroutable CIDR Blocks

Secondary unroutable CIDR blocks are essential for:
- **Conserving Primary IP Addresses**: Frees up primary IP addresses for other critical services.
- **Enhanced Security**: Pods using secondary CIDR blocks cannot be reached directly from the internet.
- **Improved Scalability**: Helps manage large numbers of pods without exhausting the primary IP space.

## 3. Primary and Secondary IP Address Ranges

### Definition:
- **Primary IP Range**: The main CIDR block associated with the VPC. Routable and used for core infrastructure and services.
- **Secondary IP Range**: Additional, often unroutable, CIDR blocks used specifically for pods, reducing pressure on the primary range.

### Examples:
- **Primary IP Range**: `10.0.0.0/16`
- **Secondary IP Range**: `172.20.0.0/16` (unroutable for internal use only)

## 4. Pod IP Allocation Strategy

### Usage:
- **Primary IP Range**: Generally assigned to nodes, services, and critical infrastructure components.
- **Secondary IP Range**: Allocated to Kubernetes pods to isolate pod traffic and conserve primary IP addresses.

## 5. Configuration Files for CNI

### Location:
- The primary configuration file is located at `/etc/cni/net.d/10-aws.conflist`.

### Description:
- **10-aws.conflist**: Contains settings for IPAM (IP Address Management) and network interface configurations.

## 6. Identifying and Resolving Primary vs. Secondary IP Address Assignment Issues

### Step-by-Step Process:

1. **Verify Current Configuration**
   - Check the config map for IP allocation settings.
     ```sh
     kubectl get configmap aws-node -n kube-system -o yaml
     ```

2. **Inspect CNI Logs for Allocation Errors**
   - SSH into nodes and review logs.
     ```sh
     sudo cat /var/log/aws-routed-eni/ipamd.log
     sudo cat /var/log/aws-routed-eni/plugin.log
     ```

3. **Review Pod IP Assignments**
   - List pods with IP addresses.
     ```sh
     kubectl get pods -o wide
     ```

4. **Check Secondary CIDR Allocation**
   - Ensure secondary CIDR blocks are configured correctly in the VPC.

5. **Update CNI Configuration**
   - Edit the CNI configuration to ensure secondary IP ranges are preferred for pod allocation.
     ```sh
     kubectl edit configmap aws-node -n kube-system
     ```


## 7. Troubleshooting IP Address Exhaustion

### Steps:
1. **Monitor IP Address Usage**
   - Check available IP addresses.
     ```sh
     kubectl describe nodes | grep PodCIDR
     ```

2. **Increase IP Pool Size**
   - Edit the VPC CNI config map.
     ```sh
     kubectl edit configmap aws-node -n kube-system
     ```

3. **Scale Cluster or Add Secondary CIDRs**
   - Add secondary CIDR blocks to the VPC if needed.

4. **Check for IP Leaks**
   - Ensure terminated pods release their IP addresses properly.

## 8. Practical Examples

### Example 1: Configuring Secondary CIDR Blocks
1. Add secondary CIDR to VPC.
   ```sh
   aws ec2 associate-vpc-cidr-block --vpc-id <vpc-id> --cidr-block 172.20.0.0/16
   ```

### Example 2: Debugging IP Assignment
1. Check pod IP range.
   ```sh
   kubectl get pods -o jsonpath='{.items[*].status.podIP}'
   ```

## 9 References

- [AWS VPC CNI Plugin Documentation](https://docs.aws.amazon.com/eks/latest/userguide/pod-networking.html)
- [Kubernetes Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [Troubleshooting EKS Networking](https://aws.amazon.com/premiumsupport/knowledge-center/eks-troubleshoot-pods/)

---

This documentation outlines a comprehensive approach to efficiently manage IPv4 address space in a Kubernetes environment using the Amazon VPC CNI plugin, with practical steps for configuration, troubleshooting, and validation.