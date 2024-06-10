# Terraform EKS Module README

## Overview

This module provides a way to deploy an Amazon EKS (Elastic Kubernetes Service) cluster using Terraform.
The module includes configurations for IAM roles, KMS keys, VPC settings, and various EKS add-ons.

## Variables

Below is a table of the variables you can configure in this module, along with their types and default values.

|             Variable Name             |     Type      | Default Value |                                                  Description                                                   |
|:-------------------------------------:|:-------------:|:-------------:|:--------------------------------------------------------------------------------------------------------------:|
|            `custom_ami_id`            |   `string`    |     `""`      |                                  The custom AMI ID to use for the EKS nodes.                                   |
|         `cluster_custom_name`         |   `string`    |      N/A      | The name of the EKS cluster. Must contain a '-'. Cluster name defaults to `main-test` if no value is provided. |
|          `eks_cluster_tags`           | `map(string)` |     `{}`      |                                     The tags to apply to the EKS cluster.                                      |
|            `eks_node_tags`            | `map(string)` |     `{}`      |                                      The tags to apply to the EKS nodes.                                       |
| `eks_security_group_additional_rules` | `map(object)` |     `{}`      |                            Additional rules to add to the EKS node security group.                             |
|             `eks_version`             |   `string`    |   `"1.29"`    |                                        The version of the EKS cluster.                                         |
|             `node_labels`             | `map(string)` |     `{}`      |                                     The labels to apply to the EKS nodes.                                      |
|             `node_taints`             | `map(string)` |     `{}`      |                                     The taints to apply to the EKS nodes.                                      |
|         `lb_controller_tags`          | `map(string)` |     `{}`      |                               The tags to apply to the Load Balancer Controller.                               |
|      `enable_eks_pod_identities`      |    `bool`     |    `true`     |                                           Enable EKS Pod Identities.                                           |
|         `ebs_encryption_key`          |   `string`    |     `""`      |                                      The encryption key for EBS volumes.                                       |
|          `pod_identity_tags`          | `map(string)` |     `{}`      |                                    The tags to apply to the Pod Identities.                                    |
|           `karpenter_tags`            | `map(string)` |     `{}`      |                                        The tags to apply to Karpenter.                                         |
|          `main_bucket_tags`           | `map(string)` |     `{}`      |                                     The tags to apply to the main bucket.                                      |
|         `logging_bucket_tags`         | `map(string)` |     `{}`      |                                    The tags to apply to the logging bucket.                                    |

## Usage

To use this module, include it in your Terraform configuration as follows:

```hcl
module "eks" {
  source  = "git::https://github.com/CMS-Enterprise/Energon-Kube.git?ref=<release-version>"

  variable = value
}
```

## Steps to Import and Use the Module

1. **Add the Module to Your Terraform Configuration**

    Include the module in your Terraform configuration file as shown in the usage example above.
    Make sure to replace `github.com/<your-github-repo>/path-to-module` with the actual GitHub repository URL and path to the module,
    and specify the version you want to use.

2. **Initialize and Apply Terraform**

    Initialize and apply the Terraform configuration:

   ```bash
   terraform init
   terraform apply
   ```

## Conclusion

By following this guide, you should be able to deploy an EKS cluster using this Terraform module.
If you encounter any issues or have further questions, consult the Terraform and AWS documentation.