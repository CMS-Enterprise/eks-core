variable "account_num" {
  description = "The account number to use for the resources"
  type        = string
}

variable "ado" {
  description = "The ADO to deploy into"
  type        = string
}

variable "alb_security_group_id" {
  description = "The ID of the security group to use for the ALB"
  type        = string
}

variable "argocd_chart_version" {
  description = "The version of the ArgoCD chart to use"
  type        = string
}

variable "argocd_use_sso" {
  description = "Enable SSO for ArgoCD"
  type        = bool
  default     = false
}

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

variable "domain_name" {
  description = "The domain name to use for DNS"
  type        = string
}

variable "efs_file_system_id" {
  description = "EFS file system ID"
  type        = string
}

variable "efs_directory_permissions" {
  description = "EFS directory permissions"
  type        = string
}

variable "eks_gp3_reclaim_policy" {
  description = "EKS gp3 reclaim policy"
  type        = string
}

variable "eks_gp3_volume_binding_mode" {
  description = "EKS gp3 volume binding mode"
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

variable "env" {
  description = "The environment to deploy into"
  type        = string
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

variable "is_prod_cluster" {
  description = "Whether the cluster is a production cluster"
  type        = bool
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

variable "k8s_alb_name" {
  description = "The name of the ALB for the Kubernetes cluster"
  type        = string
}

variable "main_nodes_iam_role_arn" {
  description = "The ARN of the IAM role to use for the main nodes"
  type        = string
}

variable "okta_client_id" {
  description = "Okta Client ID for Setting up SSO for ArgoCD"
  type        = string
  sensitive   = true
  default     = ""
}

variable "okta_client_secret" {
  description = "Okta Client Secret for Setting up SSO for ArgoCD"
  type        = string
  sensitive   = true
  default     = ""
}

variable "okta_issuer" {
  description = "Okta OIDC Issuer for Setting up SSO for ArgoCD"
  type        = string
  default     = ""
}

variable "post_bootstrap_user_data" {
  description = "User data to run after the bootstrap script"
  type        = string
}

variable "pre_bootstrap_user_data" {
  description = "User data to run before the bootstrap script"
  type        = string
}

variable "region_name" {
  description = "The name of the region to deploy into"
  type        = string
}

variable "subnet_lookup_overrides" {
  description = "Some Subnets don't follow standard naming conventions.  Use this map to override the query used for looking up Subnets.  Ex: { private = \"foo-west-nonpublic-*\" }"
  default     = {}
  type        = map(string)
}

