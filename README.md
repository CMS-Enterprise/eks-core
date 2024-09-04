# Terraform EKS Module

## Overview

This module provides a way to deploy an Amazon EKS (Elastic Kubernetes Service) cluster using Terraform.
The module includes configurations for IAM roles, KMS keys, VPC settings, and various EKS add-ons.

## Required Variables

|     Variable Name     |   Type   | Default Value |          Description           |
|:---------------------:|:--------:|:-------------:|:------------------------------:|
|         `ado`         | `string` |      N/A      |         The ado name.          |
| `cluster_custom_name` | `string` |      N/A      |  The name of the EKS cluster.  |
|         `env`         | `string` |      N/A      |     The environment name.      |
|   `program_office`    | `string` |      N/A      |    The program office name.    |
|     `domain_name`     | `string` |      N/A      | The domain name to use for DNS |

## Optional Variables

|                       Variable Name                        |      Type      |     Default Value      |                                                                              Description                                                                              |
|:----------------------------------------------------------:|:--------------:|:----------------------:|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------:|
|                   `argocd_chart_version`                   |    `string`    |        `7.3.6`         |                                                                 The version of the ArgoCD helm chart.                                                                 |
|                      `argocd_use_sso`                      |   `boolean`    |        `false`         |                                                                   Enable SSO for ArgoCD using Okta.                                                                   |
|                      `custom_ami_id`                       |    `string`    |          `""`          |                                                                 The custom AMI ID to use for the EKS                                                                  |
|                `efs_availability_zone_name`                |    `string`    |          `""`          |                                                                  The availability zone for the EFS.                                                                   |
|                `efs_directory_permissions`                 |    `string`    |         `0700`         |                                                                The directory permissions for the EFS.                                                                 |
|                  `efs_encryption_enabled`                  |     `bool`     |         `true`         |                                                                    Enable encryption for the EFS.                                                                     |
|        `efs_lifecycle_policy_transition_to_archive`        |    `string`    |    `AFTER_180_DAYS`    |                                                             The transition to archive policy for the EFS.                                                             |
|          `efs_lifecycle_policy_transition_to_ia`           |    `string`    |    `AFTER_90_DAYS`     |                                                               The transition to IA policy for the EFS.                                                                |
| `efs_lifecycle_policy_transition_to_primary_storage_class` |    `string`    |    `AFTER_1_ACCESS`    |                                                      The transition to primary storage class policy for the EFS.                                                      |
|                   `efs_performance_mode`                   |    `string`    |    `generalPurpose`    |                                                                   The performance mode for the EFS.                                                                   |
|           `efs_protection_replication_overwrite`           |    `string`    |       `DISABLED`       |                                                           The replication overwrite protection for the EFS.                                                           |
|           `efs_provisioned_throughput_in_mibps`            |    `number`    |          `0`           |                                                                The provisioned throughput for the EFS.                                                                |
|                         `efs_tags`                         | `map(string)`  |          `{}`          |                                                                     The tags to apply to the EFS.                                                                     |
|                   `efs_throughput_mode`                    |    `string`    |       `bursting`       |                                                                   The throughput mode for the EFS.                                                                    |
|                    `eks_access_entries`                    | `map(object)`  |          `{}`          |                                                            The access entries to apply to the EKS cluster.                                                            |
|                     `eks_cluster_tags`                     | `map(string)`  |          `{}`          |                                                                 The tags to apply to the EKS cluster.                                                                 |
|                  `eks_gp3_reclaim_policy`                  |    `string`    |        `Retain`        |                                                              The reclaim policy for the EKS gp3 volumes.                                                              |
|               `eks_gp3_volume_binding_mode`                |    `string`    | `WaitForFirstConsumer` |                                                           The volume binding mode for the EKS gp3 volumes.                                                            |
|               `eks_main_node_instance_types`               | `list(string)` |    `["c5.2xlarge"]`    |                                                            The instance types for the main EKS node group.                                                            |
|               `eks_main_nodes_desired_size`                |    `number`    |          `3`           |                                                             The desired size of the main EKS node group.                                                              |
|                 `eks_main_nodes_max_size`                  |    `number`    |          `6`           |                                                               The max size of the main EKS node group.                                                                |
|                 `eks_main_nodes_min_size`                  |    `number`    |          `3`           |                                                               The min size of the main EKS node group.                                                                |
|                      `eks_node_tags`                       | `map(string)`  |          `{}`          |                                                                  The tags to apply to the EKS nodes.                                                                  |
|           `eks_security_group_additional_rules`            | `map(object)`  |          `{}`          |                                                        Additional rules to add to the EKS node security group.                                                        |
|                       `eks_version`                        |    `string`    |        `"1.29"`        |                                                                    The version of the EKS cluster.                                                                    |
|                `enable_eks_pod_identities`                 |     `bool`     |         `true`         |                                                                      Enable EKS Pod Identities.                                                                       |
|                     `gold_image_date`                      |    `string`    |          `""`          |                                                   Gold Image Date in YYYY-MM format. Must be in the YYYY-MM format.                                                   |
|                     `is_prod_cluster`                      |     `bool`     |        `false`         |                                  Whether the cluster is a production cluster. You can only have one production cluster per account.                                   |
|                      `karpenter_tags`                      | `map(string)`  |          `{}`          |                                                            The tags to apply to the Karpenter deployment.                                                             |
|                     `kp_chart_version`                     |    `string`    |       `"0.37.0"`       |                                                                     Karpenter helm chart version.                                                                     |
|                   `logging_bucket_tags`                    | `map(string)`  |          `{}`          |                                                               The tags to apply to the logging bucket.                                                                |
|                     `main_bucket_tags`                     | `map(string)`  |          `{}`          |                                                                 The tags to apply to the main bucket.                                                                 |
|                      `okta_client_id`                      |    `string`    |          `""`          |                                                             Okta Client ID for setting up SSO for ArgoCD.                                                             |
|                    `okta_client_secret`                    |    `string`    |          `""`          |                                                           Okta Client Secret for setting up SSO for ArgoCD.                                                           |
|                       `okta_issuer`                        |    `string`    |          `""`          |                                                            Okta OIDC Issuer for setting up SSO for ArgoCD.                                                            |
|                `node_bootstrap_extra_args`                 |    `string`    |          `""`          |                                                Any extra arguments to pass to the bootstrap script for the EKS nodes.                                                 |
|                       `node_labels`                        | `map(string)`  |          `{}`          |                                                                 The labels to apply to the EKS nodes.                                                                 |
|                `node_post_bootstrap_script`                |    `string`    |          `""`          |                                                          The post-bootstrap script to run on the EKS nodes.                                                           |
|                `node_pre_bootstrap_script`                 |    `string`    |          `""`          |                                                           The pre-bootstrap script to run on the EKS nodes.                                                           |
|                       `node_taints`                        | `map(string)`  |          `{}`          |                                                                 The taints to apply to the EKS nodes.                                                                 |
|                    `pod_identity_tags`                     | `map(string)`  |          `{}`          |                                                               The tags to apply to the Pod Identities.                                                                |
|                 `subnet_lookup_overrides`                  | `map(string)`  |          `{}`          |    Some Subnets don't follow standard naming conventions. Use this map to override the query used for looking up Subnets. Ex: { private = "foo-west-nonpublic-*" }    |
|              `vpc_endpoint_lookup_overrides`               |    `string`    |          `""`          | Some VPC endpoints don't follow standard naming conventions. Use this map to override the query used for looking up Subnets. Ex: { private = "foo-west-nonpublic-*" } |
|                   `vpc_lookup_override`                    |    `string`    |          `""`          |             Some VPCs don't follow standard naming conventions. Use this to override the query used to lookup VPC names. Accepts wildcard in form of '*'              |

## Usage

To use this module, include it in your Terraform configuration as follows:

```hcl
module "eks" {
  source  = "git::https://github.com/CMS-Enterprise/Energon-Kube.git?ref=<release-version>"

  variable = value
}
```

### AMI Variable Precedence

1. `gold_image_date`
2. `custom_ami_id`

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
- There is a known issue with volume affinity on some workloads (EBS volumes tied to specific AZ).
If you want to solve this problem you will need to use node taints/tolerations.
You can find more information on how to do this [here](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/).

## Conclusion

By following this guide, you should be able to deploy an EKS cluster using this Terraform module.
If you encounter any issues or have further questions, consult the Terraform and AWS documentation.

## Questions

1. How long does this script normally take to execute?
   The script generally takes anywhere from 20 to 45 minutes to create.
   It is vastly dependent upon the VPN connection and the traffic on the AWS API.
   The node rotation that occurs at the end of the script generally takes about 5–10 minutes for all nodes to cycle.
   This will increase as you increase the `desired_value` for the auto-scaling group.

2. What does the error below mean?

```bash
Error: no matching EC2 VPC found
```

This means that you probably have an incorrect value being passed in your module call. You need to set both the `env` and `ado` variables to the correct values. For example:

```hcl
env = "dev"
project = "batcave"
```

3. I am seeing the following error, what does it mean?

```bash
[error] [aws_client] connection initialization error
[error] [output:cloudwatch_logs:cloudwatch_logs.1] Failed to create log stream
[error] [output:cloudwatch_logs:cloudwatch_logs.1] Failed to send events
```

You will see this error on initial stand up of the fluentbit pod(s).
This error should eventually resolve itself as the fluentbit pod(s) come up and start sending logs to CloudWatch.
Look for the following cloudwatch log groups to validate that logs are being sent to cloudwatch as expected:

- `/aws/containerinsights/<cluster_name>/application`
- `/aws/containerinsights/<cluster_name>/dataplane`
- `/aws/containerinsights/<cluster_name>/performance`
- `/aws/containerinsights/<cluster_name>/host`

4. Where is the admin password for ArgoCD?

The admin password for ArgoCD is stored in the `argocd-initial-admin-secret` secret in the `argocd` namespace.

5. I am seeing errors for route53, what does this mean?

If you are seeing errors related to the data block of the route53 zone, this means that you have not specified the `domain_name` variable.

6. Why is the EKS Node Security Group not properly being destroyed?

We have seen this issue arise when the autoscaling group nodes are rotated and then a `terraform destroy` is run very shortly afterwards.
Give the nodes at least 10 minutes after the rotation to ensure that they are properly terminated before running a `terraform destroy`.

### Explanation:

1. **Terraform Configuration**:

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

7. How do I configure SSO for ArgoCd?

To set up SSO for ArgoCD using Okta, you need to add specific variables when calling the main EKS module. You need to ensure that the Okta variables are provided when SSO is enabled. For example:
```hcl
module "main-eks" {
  source = "git::https://github.com/CMS-Enterprise/Energon-Kube.git?ref=<release-version>"

  cluster_custom_name = "temp-test"
  env                 = "impl"
  gold_image_date     = "2024-06"
  ado                 = "batcave"
  program_office      = "batman"
  argocd_use_sso      = true
  okta_issuer         = "OKTA Issuer URL"
  okta_client_id      = "OKTA client ID"
  okta_client_secret  = "OKTA client secret"
}
```

### Notes:
- This EKS core module was co-developed with other IUSG cloud engineering contractors such as Leidos and Samtek.
