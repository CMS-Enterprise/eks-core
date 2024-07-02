variable "available_availability_zones" {
  description = "The available availability zones"
  type        = list(string)
}

variable "aws_partition" {
  description = "The AWS partition to deploy into"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy into"
  type        = string
}

variable "bootstrap_extra_args" {
  description = "Extra arguments to pass to the bootstrap script"
  type        = string
}

variable "cluster_ca_data" {
  description = "The CA data for the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  type        = string
}

variable "cloudwatch_kms_key_arn" {
  description = "The ARN of the KMS key to use for encrypting log data"
  type        = string
}

variable "custom_ami" {
  description = "The ID of the custom AMI to use for the nodes"
  type        = string
  default     = ""
}

variable "deploy_env" {
  description = "The environment to deploy into"
  type        = string
}

variable "deploy_project" {
  description = "The project to deploy"
  type        = string
}

variable "ebs_kms_key_id" {
  description = "The ID of the KMS key to use for EBS volumes"
  type        = string
}

variable "eks_cluster_cidr" {
  description = "The CIDR block to use for the EKS cluster"
  type        = string
}

variable "eks_cluster_ip_family" {
  description = "The IP family to use for the EKS cluster"
  type        = string
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "eks_cluster_security_group_id" {
  description = "The ID of the security group to use for the EKS cluster"
  type        = string
}

variable "eks_launch_template_name" {
  description = "The name of the launch template for the EKS nodes"
  type        = string
}

variable "eks_node_iam_role_arn" {
  description = "The ARN of the IAM role to use for the EKS nodes"
  type        = string
}

variable "eks_node_iam_role_name" {
  description = "The ARN of the IAM name to use for the EKS nodes"
  type        = string
}

variable "eks_node_security_group_id" {
  description = "The ID of the security group to use for the EKS nodes"
  type        = string
}

variable "eks_oidc_provider" {
  description = "The OIDC provider URL for the EKS cluster"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "The ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "enable_bootstrap_user_data" {
  description = "Whether to enable the bootstrap user data"
  type        = bool
}

variable "fluentbit_additional_log_filters" {
  description = "Additional log filters to use for Fluentbit"
  type        = list(string)
}

variable "fluentbit_chart_version" {
  description = "The version of the Fluentbit chart to use"
  type        = string
}

variable "fluentbit_drop_namespaces" {
  description = "Namespaces to drop from Fluentbit logs"
  type        = list(string)
}

variable "fluentbit_kube_namespaces" {
  description = "Kubernetes namespaces to use for Fluentbit"
  type        = list(string)
}

variable "fluentbit_log_encryption" {
  description = "Whether to encrypt Fluentbit logs"
  type        = bool
}

variable "fluentbit_log_filters" {
  description = "Log filters to use for Fluentbit"
  type        = list(string)
}

variable "fluentbit_log_retention" {
  description = "The number of days to retain Fluentbit logs"
  type        = number
}

variable "fluentbit_log_systemd" {
  description = "Whether to log systemd messages with Fluentbit"
  type        = bool
}

variable "fluentbit_system_log_retention" {
  description = "The number of days to retain Fluentbit systemd logs"
  type        = number
}

variable "fluentbit_tags" {
  description = "The tags to use for Fluentbit"
  type        = map(string)
}

variable "gold_image_ami_id" {
  description = "The AMI ID to use for the gold image"
  type        = string
  default     = ""
}

variable "iam_path" {
  description = "The path to use for IAM resources"
  type        = string
}

variable "iam_permissions_boundary_arn" {
  description = "The ARN of the permissions boundary to use for IAM roles"
  type        = string
}

variable "karpenter_base_tags" {
  description = "The base tags to use for Karpenter"
  type        = map(string)
}

variable "karpenter_chart_version" {
  description = "The version of the Karpenter chart to use"
  type        = string
}

variable "karpenter_ec2nodeclass_name" {
  description = "The name of the Karpenter EC2 node class"
  type        = string
  default     = ""
}

variable "karpenter_nodepool_name" {
  description = "The name of the Karpenter node pool"
  type        = string
  default     = ""
}

variable "karpenter_nodepool_taints" {
  description = "The taints to use for the Karpenter node pool"
  type        = map(string)
  default     = {}
}

variable "main_nodes_iam_role_arn" {
  description = "The ARN of the IAM role to use for the main nodes"
  type        = string
}

variable "post_bootstrap_user_data" {
  description = "User data to run after the bootstrap script"
  type        = string
}

variable "pre_bootstrap_user_data" {
  description = "User data to run before the bootstrap script"
  type        = string
}