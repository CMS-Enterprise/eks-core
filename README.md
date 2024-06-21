# Terraform EKS Module README

## Overview

This module provides a way to deploy an Amazon EKS (Elastic Kubernetes Service) cluster using Terraform.
The module includes configurations for IAM roles, KMS keys, VPC settings, and various EKS add-ons.

## Variables

Below is a table of the variables you can configure in this module, along with their types and default values.

|                       Variable Name                        |      Type      |                         Default Value                          |                                                                             Description                                                                             |
|:----------------------------------------------------------:|:--------------:|:--------------------------------------------------------------:|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------:|
|                      `custom_ami_id`                       |    `string`    |                              `""`                              |                                                             The custom AMI ID to use for the EKS nodes.                                                             |
|                           `env`                            |    `string`    |                            `"dev"`                             |                                                                        The environment name.                                                                        |
|                         `project`                          |    `string`    |                          `"batcave"`                           |                                                                          The project name.                                                                          |
|                 `subnet_lookup_overrides`                  | `map(string)`  |                              `{}`                              |   Some Subnets don't follow standard naming conventions. Use this map to override the query used for looking up Subnets. Ex: { private = "foo-west-nonpublic-*" }   |
|                  `create_s3_vpc_endpoint`                  |     `bool`     |                             `true`                             |                                                           Toggle on/off the creation of s3 VPC endpoint.                                                            |
|              `vpc_endpoint_lookup_overrides`               |    `string`    |                              `""`                              | Some VPC endpoints don't follow standard naming conventions. Use this map to override the query used for looking up Subnets. Ex: { private = "foo-west-nonpublic-*" |
|                   `vpc_lookup_override`                    |    `string`    |                              `""`                              |            Some VPCs don't follow standard naming conventions. Use this to override the query used to lookup VPC names. Accepts wildcard in form of '*'             |
|                     `gold_image_date`                      |    `string`    |                              `""`                              |                                                                 Gold Image Date in YYYY-MM format.                                                                  |
|                     `use_bottlerocket`                     |     `bool`     |                            `false`                             |                                                                 Use Bottlerocket AMI for EKS nodes.                                                                 |
|                   `cluster_custom_name`                    |    `string`    |                              N/A                               |                           The name of the EKS cluster. Must contain a '-'. Cluster name defaults to `main-test` if no value is provided.                            |
|                    `eks_access_entries`                    | `map(object)`  |                              `{}`                              |                                                           The access entries to apply to the EKS cluster.                                                           |
|                     `eks_cluster_tags`                     | `map(string)`  |                              `{}`                              |                                                                The tags to apply to the EKS cluster.                                                                |
|               `eks_main_nodes_desired_size`                |    `number`    |                              `3`                               |                                                            The desired size of the main EKS node group.                                                             |
|               `eks_main_node_instance_types`               | `list(string)` |                        `["c5.2xlarge"]`                        |                                                           The instance types for the main EKS node group.                                                           |
|                 `eks_main_nodes_max_size`                  |    `number`    |                              `6`                               |                                                              The max size of the main EKS node group.                                                               |
|                 `eks_main_nodes_min_size`                  |    `number`    |                              `3`                               |                                                              The min size of the main EKS node group.                                                               |
|                      `eks_node_tags`                       | `map(string)`  |                              `{}`                              |                                                                 The tags to apply to the EKS nodes.                                                                 |
|           `eks_security_group_additional_rules`            | `map(object)`  |                              `{}`                              |                                                       Additional rules to add to the EKS node security group.                                                       |
|                       `eks_version`                        |    `string`    |                            `"1.29"`                            |                                                                   The version of the EKS cluster.                                                                   |
|                       `node_labels`                        | `map(string)`  |                              `{}`                              |                                                                The labels to apply to the EKS nodes.                                                                |
|                       `node_taints`                        | `map(string)`  |                              `{}`                              |                                                                The taints to apply to the EKS nodes.                                                                |
|                    `lb_controller_tags`                    | `map(string)`  |                              `{}`                              |                                                         The tags to apply to the Load Balancer Controller.                                                          |
|                `enable_eks_pod_identities`                 |     `bool`     |                             `true`                             |                                                                     Enable EKS Pod Identities.                                                                      |
|                    `pod_identity_tags`                     | `map(string)`  |                              `{}`                              |                                                              The tags to apply to the Pod Identities.                                                               |
|                     `fb_chart_version`                     |    `string`    |                           `"0.1.33"`                           |                                                                   Fluent-bit helm chart version.                                                                    |
|                    `fb_log_encryption`                     |     `bool`     |                             `true`                             |                                                                  Enable Fluent-bit log encryption.                                                                  |
|                      `fb_log_systemd`                      |     `bool`     |                             `true`                             |                                                          Enable Fluent-bit cloudwatch logging for systemd.                                                          |
|                         `fb_tags`                          | `map(string)`  |                              `{}`                              |                                                           The tags to apply to the fluent-bit deployment.                                                           |
|                     `fb_log_retention`                     |    `number`    |                              `7`                               |                                                                   Days to retain Fluent-bit logs.                                                                   |
|                 `fb_system_log_retention`                  |    `number`    |                              `7`                               |                                                               Days to retain Fluent-bit systemd logs.                                                               |
|                    `fb_drop_namespaces`                    | `list(string)` |               `["kube-system", "cert-manager"]`                |                                                         Fluent-bit doesn't send logs for these namespaces.                                                          |
|                    `fb_kube_namespaces`                    | `list(string)` |                 `["kube.*", "cert-manager.*"]`                 |                                                                       Kubernetes namespaces.                                                                        |
|                      `fb_log_filters`                      | `list(string)` |      `["kube-probe", "health", "prometheus", "liveness"]`      |                                                  Fluent-bit doesn't send logs if message consists of these values.                                                  |
|                `fb_additional_log_filters`                 | `list(string)` | `["ELB-HealthChecker", "Amazon-Route53-Health-Check-Service"]` |                                                  Fluent-bit doesn't send logs if message consists of these values.                                                  |
|                     `kp_chart_version`                     |    `string`    |                           `"0.37.0"`                           |                                                                    Karpenter helm chart version.                                                                    |
|                   `kp_ec2nodeclass_name`                   |    `string`    |                          `"default"`                           |                                                                   The name of the EC2 Node Class.                                                                   |
|      `kp_ec2nodeclass_security_group_selector_terms`       |   `set(any)`   |                              `[]`                              |                                 The security group selector terms for the EC2 Node Class. Defaults to the EKS node security group.                                  |
|          `kp_ec2nodeclass_subnet_selector_terms`           |   `set(any)`   |                              `[]`                              |                                           The subnet selector terms for the EC2 Node Class. Defaults to private subnets.                                            |
|                   `kp_ec2nodeclass_tags`                   | `map(string)`  |                              `{}`                              |                                                                  The tags for the EC2 Node Class.                                                                   |
|                 `kp_nodepool_annotations`                  | `map(string)`  |                              `{}`                              |                                                            The annotations for the Karpenter node pool.                                                             |
|                  `kp_nodepool_disruption`                  |   `map(any)`   |                              `{}`                              |                                                  The disruption consolidation policy for the Karpenter node pool.                                                   |
|                   `kp_nodepool_kubelet`                    |   `map(any)`   |                              `{}`                              |                                                         The kubelet arguments for the Karpenter node pool.                                                          |
|                    `kp_nodepool_labels`                    | `map(string)`  |                              `{}`                              |                                                               The labels for the Karpenter node pool.                                                               |
|                    `kp_nodepool_limits`                    | `map(string)`  |                              `{}`                              |                                                               The limits for the Karpenter node pool.                                                               |
|                    `kp_nodepool_weight`                    |    `number`    |                              `10`                              |                                             The weight for the Karpenter node pool. Higher number means more priority.                                              |
|                     `kp_nodepool_name`                     |    `string`    |                          `"default"`                           |                                                                The name of the Karpenter node pool.                                                                 |
|                 `kp_nodepool_requirements`                 | `map(string)`  |                              `{}`                              |                                                            The requirements for the Karpenter node pool.                                                            |
|                `kp_nodepool_startup_taints`                | `map(string)`  |                              `{}`                              |                                                           The startup taints for the Karpenter node pool.                                                           |
|                    `kp_nodepool_taints`                    | `map(string)`  |                              `{}`                              |                                                               The taints for the Karpenter node pool.                                                               |
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
|                   `efs_throughput_mode`                    |    `string`    |                           `bursting`                           |                                                                  The throughput mode for the EFS.                                                                   |

## Usage

To use this module, include it in your Terraform configuration as follows:

You can also view the example usage in the `main.tf` file in the `example` directory.

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

1. **Use Terraform Workspaces**

   Use Terraform workspaces to manage multiple environments (e.g., dev, staging, production) with the same configuration.
   This allows you to create separate state files for each environment and avoid conflicts between them.
   To create a new workspace, use the following command:

   ```bash
   terraform workspace new <workspace-name>
   ```

   To switch between workspaces, use:

   ```bash
   terraform workspace select <workspace-name>
   ```
   
2. **Use S3 and DynamoDB for State Management**

   Store the Terraform state file in an S3 bucket and use DynamoDB for state locking.
   This ensures that the state file is stored securely and can be accessed by multiple team members.
   To configure remote state storage, add the following block to your Terraform configuration:

   ```hcl
   terraform {
     backend "s3" {
       bucket         = "<bucket-name>"
       key            = "<path-to-state-file>"
       region         = "<region>"
       dynamodb_table = "<dynamodb-table-name>"
     }
   }
   ```

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

3. What options are available for the `eks_access_entries` variable?

   Here is an example of the `eks_access_entries` variable:

```hcl
eks_access_entries = {
    techAdmin = {
      principal_arn = "arn:aws:iam::123456789012:role/techadmin"
      type          = "STANDARD"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    },
    readOnly = {
      kubernetes_groups = []
      principal_arn = "arn:aws:iam::123456789012:role/readonly"
      type          = "STANDARD"
      policy_associations = {
        readonly = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            namespaces = ["default", "kube-system"]
            type = "namespace"
          }
        }
      }
    }
}
```

4. What options are available for the `kp_nodepool` variables?

    You can find the documentation from Karpenter to help you understand the `kp_nodepool` variables [here](https://karpenter.sh/docs/concepts/nodepools/).
    The `kp_nodepool` variables expect the following values to be passed as a map:
    - `kp_nodepool_annotations`
    - `kp_nodepool_disruption`
    - `kp_nodepool_labels`
    - `kp_nodepool_requirements`
    - `kp_nodepool_startup_taints`
    - `kp_nodepool_taints`

    Here is an example of the `kp_nodepool_requirements` variable:
```hcl
kp_nodepool_requirements = [
  {
    key = "karpenter.k8s.aws/instance-category"
    operator = "In"
    values = ["c", "r", "m"]
    minValues = 1
  },
  {
    key = "karpenter.k8s.aws/instance-family"
    operator = "In"
    values = ["m5", "m5d", "c5", "c5d", "r5", "r5d"]
    minValues = 3
  },
  {
    key = "karpenter.sh/instance-cpu"
    operator = "Gt"
    values = ["4"]
  },
  {
    key = "topology.kubernetes.io/zone"
    operator = "In"
    values = ["us-east-1a", "us-east-1b", "us-east-1c"]
  }
]
```

## Conclusion

By following this guide, you should be able to deploy an EKS cluster using this Terraform module.
If you encounter any issues or have further questions, consult the Terraform and AWS documentation.
    
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
