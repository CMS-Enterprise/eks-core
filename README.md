# Terraform EKS Module README

## Overview

This module provides a way to deploy an Amazon EKS (Elastic Kubernetes Service) cluster using Terraform.
The module includes configurations for IAM roles, KMS keys, VPC settings, and various EKS add-ons.

## Variables

Below is a table of the variables you can configure in this module, along with their types and default values.

|             Variable Name             |     Type      | Default Value |                                                  Description                                                   |
|:-------------------------------------:|:-------------:|:-------------:|:--------------------------------------------------------------------------------------------------------------:|
|            `custom_ami_id`            |   `string`    |     `""`      |                                  The custom AMI ID to use for the EKS nodes.                                   |
|           `gold_image_date`           |   `string`    |     `""`      |                         The date (YYYYMM) of the gold image to use for the EKS nodes.                          |
|          `use_bottlerocket`           |    `bool`     |    `false`    |                                 Whether to use bottlerocket for the EKS nodes.                                 |
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

### AMI Selection Logic

You must specify one of the following variables to declare what image to use for the EKS nodes:
- `gold_image_date`
- `custom_ami_id`
- `use_bottlerocket`

If more than one variable is set, they take precedence in the following order:
1. `gold_image_date`
2. `custom_ami_id`
3. `use_bottlerocket`

If none of these variables are set, the Terraform configuration will not proceed.

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

### Explanation:

1. **Terraform Configuration**:
   - The `image_var_validation` local variable checks if both `custom_ami_id` and `gold_image_date` are set, or if `use_bottlerocket` is set to `true` and either `custom_ami_id` or `gold_image_date` are set.
   - The `ami_id` local variable determines the AMI ID to use based on the precedence order: `gold_image_date`, `custom_ami_id`, `use_bottlerocket`.
   - The `null_resource.validate_vars` resource uses a `local-exec` provisioner to run a shell script that checks the `image_var_validation` condition and exits with an error if it is true.

2. **README.md**:
   - The README provides an overview of the module, a table of configurable variables, usage instructions, and details on the AMI selection logic.
   - The AMI selection logic section explains the requirements for setting the image variables and the precedence order if more than one variable is set.