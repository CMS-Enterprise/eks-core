# Terraform EKS Module

## Overview

This module provides a way to deploy an Amazon EKS (Elastic Kubernetes Service) cluster using Terraform.
The module includes configurations for IAM roles, KMS keys, VPC settings, and various EKS add-ons.

## Variables

## Variables

|                       Variable Name                        |      Type      |                         Default Value                          |                                                                             Description                                                                             |
|:----------------------------------------------------------:|:--------------:|:--------------------------------------------------------------:|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------:|
|                           `env`                            |    `string`    |                            `"dev"`                             |                                                                        The environment name.                                                                        |
|                         `project`                          |    `string`    |                          `"batcave"`                           |                                                                          The project name.                                                                          |
|                 `subnet_lookup_overrides`                  | `map(string)`  |                              `{}`                              |   Some Subnets don't follow standard naming conventions. Use this map to override the query used for looking up Subnets. Ex: { private = "foo-west-nonpublic-*" }   |
|                  `create_s3_vpc_endpoint`                  |     `bool`     |                             `true`                             |                                                           Toggle on/off the creation of s3 VPC endpoint.                                                            |
|                   `cluster_custom_name`                    |    `string`    |                              N/A                               |                           The name of the EKS cluster. Must contain a '-'. Cluster name defaults to `main-test` if no value is provided.                            |
|                    `eks_access_entries`                    | `map(object)`  |                              `{}`                              |                                                           The access entries to apply to the EKS cluster.                                                           |
|                     `eks_cluster_tags`                     | `map(string)`  |                              `{}`                              |                                                                The tags to apply to the EKS cluster.                                                                |
|               `eks_main_nodes_desired_size`                |    `number`    |                              `3`                               |                                                            The desired size of the main EKS node group.                                                             |
|                 `eks_main_nodes_max_size`                  |    `number`    |                              `6`                               |                                                              The max size of the main EKS node group.                                                               |
|                 `eks_main_nodes_min_size`                  |    `number`    |                              `3`                               |                                                              The min size of the main EKS node group.                                                               |
|                      `eks_node_tags`                       | `map(string)`  |                              `{}`                              |                                                                 The tags to apply to the EKS nodes.                                                                 |
|           `eks_security_group_additional_rules`            | `map(object)`  |                              `{}`                              |                                                       Additional rules to add to the EKS node security group.                                                       |
|                       `eks_version`                        |    `string`    |                            `"1.29"`                            |                                                                   The version of the EKS cluster.                                                                   |
|                       `node_labels`                        | `map(string)`  |                              `{}`                              |                                                                The labels to apply to the EKS nodes.                                                                |
|                       `node_taints`                        | `map(string)`  |                              `{}`                              |                                                                The taints to apply to the EKS nodes.                                                                |
|                `enable_eks_pod_identities`                 |     `bool`     |                             `true`                             |                                                                     Enable EKS Pod Identities.                                                                      |
|                    `pod_identity_tags`                     | `map(string)`  |                              `{}`                              |                                                              The tags to apply to the Pod Identities.                                                               |
|                     `fb_chart_verison`                     |    `string`    |                           `"0.30.3"`                           |                                                                   Fluent-bit helm chart version.                                                                    |
|                    `fb_log_encryption`                     |     `bool`     |                             `true`                             |                                                                  Enable Fluent-bit log encryption.                                                                  |
|                      `fb_log_systemd`                      |     `bool`     |                             `true`                             |                                                          Enable Fluent-bit cloudwatch logging for systemd.                                                          |
|                         `fb_tags`                          | `map(string)`  |                              `{}`                              |                                                           The tags to apply to the fluent-bit deployment.                                                           |
|                     `fb_log_retention`                     |    `number`    |                              `7`                               |                                                                   Days to retain Fluent-bit logs.                                                                   |
|                 `fb_system_log_retention`                  |    `number`    |                              `7`                               |                                                               Days to retain Fluent-bit systemd logs.                                                               |
|                     `drop_namespaces`                      | `list(string)` |               `["kube-system", "cert-manager"]`                |                                                         Fluent-bit doesn't send logs for these namespaces.                                                          |
|                     `kube_namespaces`                      | `list(string)` |                 `["kube.*", "cert-manager.*"]`                 |                                                                       Kubernetes namespaces.                                                                        |
|                       `log_filters`                        | `list(string)` |      `["kube-probe", "health", "prometheus", "liveness"]`      |                                                  Fluent-bit doesn't send logs if message consists of these values.                                                  |
|                  `additional_log_filters`                  | `list(string)` | `["ELB-HealthChecker", "Amazon-Route53-Health-Check-Service"]` |                                                  Fluent-bit doesn't send logs if message consists of these values.                                                  |
|                     `kp_chart_verison`                     |    `string`    |                           `"0.37.0"`                           |                                                                    Karpenter helm chart version.                                                                    |
|                      `karpenter_tags`                      | `map(string)`  |                              `{}`                              |                                                           The tags to apply to the Karpenter deployment.                                                            |
|                     `main_bucket_tags`                     | `map(string)`  |                              `{}`                              |                                                                The tags to apply to the main bucket.                                                                |
|                   `logging_bucket_tags`                    | `map(string)`  |                              `{}`                              |                                                              The tags to apply to the logging bucket.                                                               |
|                `efs_availability_zone_name`                |    `string`    |                              `""`                              |                                                                 The availability zone for the EFS.                                                                  |
|                  `efs_encryption_enabled`                  |     `bool`     |                             `true`                             |                                                                   Enable encryption for the EFS.                                                                    |
|        `efs_lifecycle_policy_transition_to_archive`        |    `string`    |                        `AFTER_180_DAYS`                        |                                                            The transition to archive policy for the EFS.                                                            |
|          `efs_lifecycle_policy_transition_to_ia`           |    `string`    |                        `AFTER_90_DAYS`                         |                                                              The transition to IA policy for the EFS.                                                               |
| `efs_lifecycle_policy_transition_to_primary_storage_class` |    `string`    |                        `AFTER_1_ACCESS`                        |                                                     The transition to primary storage class policy for the EFS.                                                     |
|           `efs_provisioned_throughput_in_mibps`            |    `number`    |                              `0`                               |                                                               The provisioned throughput for the EFS.                                                               |
|                   `efs_performance_mode`                   |    `string`    |                        `generalPurpose`                        |                                                                  The performance mode for the EFS.                                                                  |
|           `efs_protection_replication_overwrite`           |    `string`    |                           `DISABLED`                           |                                                          The replication overwrite protection for the EFS.                                                          |
|                         `efs_tags`                         | `map(string)`  |                              `{}`                              |                                                                    The tags to apply to the EFS.                                                                    |
|                   `efs_throughput_mode`                    |    `string`    |                           `bursting`                           |                                                                  The throughput mode for the EFS.                                                                    |

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
   
### Recommendations

- Remove, or alter, the existing storage class for gp2 volumes.
If you want to keep the gp2 storage class, you can remove the annotation on it that specifies it as the default storage class.
This will prevent a conflict with the gp3 storage class, which is the updated default storage class for EKS nodes.

## Conclusion

By following this guide, you should be able to deploy an EKS cluster using this Terraform module.
If you encounter any issues or have further questions, consult the Terraform and AWS documentation.

## Questions

1. How long does this script normally take to execute?
   The script can take anywhere from 10 to 30 minutes to create.
   It is vastly dependent upon the VPN connection and the traffic on the AWS API.

2. What does the error below mean?

```bash
Error: no matching EC2 VPC found
```

This means that you probably have an incorrect value being passed in your module call. You need to set both the `env` and `project` variables to the correct values. For example:

```hcl
env = "dev"
project = "batcave"
```

### Explanation:

1. **Terraform Configuration**:

   - The `image_var_validation` local variable checks if both `custom_ami_id` and `gold_image_date` are set, or if `use_bottlerocket` is set to `true` and either `custom_ami_id` or `gold_image_date` are set.
   - The `ami_id` local variable determines the AMI ID to use based on the precedence order: `gold_image_date`, `custom_ami_id`, `use_bottlerocket`.
   - The `null_resource.validate_vars` resource uses a `local-exec` provisioner to run a shell script that checks the `image_var_validation` condition and exits with an error if it is true.
   - The following environment variables need to be configured:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
     - `AWS_DEFAULT_REGION`
     - `AWS_SESSION_TOKEN` (if using temporary credentials)
      OR
     - `AWS_PROFILE` (if using named profile)
2. **README.md**:

   - The README provides an overview of the module, a table of configurable variables, usage instructions, and details on the AMI selection logic.
   - The AMI selection logic section explains the requirements for setting the image variables and the precedence order if more than one variable is set.
3. **Execution**:

   - You will see that after the cluster and nodes have come up, and all addons are deployed, the nodes will destroy. This is intended behavior as the nodes are cycled to assure they are utilizing the latest VPC CNI configuration.
