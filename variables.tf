################################# Required Variables #################################
variable "cluster_custom_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "custom_ami_id" {
  description = "The custom AMI ID to use for the EKS nodes"
  type        = string
  default     = ""
}

variable "env" {
  description = "The environment name"
  type        = string
}

variable "ado" {
  description = "The ado name"
  type        = string
}

variable "program_office" {
  description = "The program office name"
  type        = string
}

################################# VPC Variables #################################

variable "subnet_lookup_overrides" {
  description = "Some Subnets don't follow standard naming conventions.  Use this map to override the query used for looking up Subnets.  Ex: { private = \"foo-west-nonpublic-*\" }"
  default     = {}
  type        = map(string)
}

variable "vpc_endpoint_lookup_overrides" {
  description = "Some vpc endpoints don't follow standard naming conventions.  Use this map to override the query used for looking up Subnets.  Ex: { private = \"foo-west-nonpublic-*\" }"
  default     = ""
  type        = string
}

variable "vpc_lookup_override" {
  description = "Some VPCs don't follow standard naming conventions.  Use this to override the query used to lookup VPC names.  Accepts wildcard in form of '*'"
  default     = ""
  type        = string

}
variable "gold_image_date" {
  description = "Gold Image Date in YYYY-MM format"
  type        = string
  default     = ""
  validation {
    condition     = can(regex("^\\d{4}-(0[1-9]|1[0-2])$", var.gold_image_date)) || var.gold_image_date == ""
    error_message = "gold_image_date must be in the YYYY-MM format."
  }
}

################################# EKS Variables #################################

variable "eks_access_entries" {
  description = "The access entries to apply to the EKS cluster"
  type = map(object({
    principal_arn = string
    type          = string
    policy_associations = map(object({
      policy_arn = string
      access_scope = map(object({
        type = string
      }))
    }))
  }))
  default = {}

  validation {
    condition     = !contains(keys(var.eks_access_entries), "cluster_creator")
    error_message = "The access entry name 'cluster_creator' is not allowed"
  }
}

variable "eks_cluster_tags" {
  description = "The tags to apply to the EKS cluster"
  type        = map(string)
  default     = {}
}

variable "eks_gp3_reclaim_policy" {
  description = "The reclaim policy for the EKS gp3 volumes"
  type        = string
  default     = "Retain"
}

variable "eks_gp3_volume_binding_mode" {
  description = "The volume binding mode for the EKS gp3 volumes"
  type        = string
  default     = "WaitForFirstConsumer"
}

variable "eks_main_nodes_desired_size" {
  description = "The desired size of the main EKS node group"
  type        = number
  default     = 3
}

variable "eks_main_node_instance_types" {
  description = "The instance types for the main EKS node group"
  type        = list(string)
  default     = ["c5.2xlarge"]
}

variable "eks_main_nodes_max_size" {
  description = "The max size of the main EKS node group"
  type        = number
  default     = 3
}

variable "eks_main_nodes_min_size" {
  description = "The min size of the main EKS node group"
  type        = number
  default     = 3
}

variable "eks_node_tags" {
  description = "The tags to apply to the EKS nodes"
  type        = map(string)
  default     = {}
}

variable "eks_security_group_additional_rules" {
  description = "Additional rules to add to the EKS node security group"
  type = map(object({
    description                   = optional(string)
    protocol                      = string
    type                          = string
    from_port                     = number
    to_port                       = number
    cidr_blocks                   = optional(list(string))
    ipv6_cidr_blocks              = optional(list(string))
    prefix_list_ids               = optional(list(string))
    source_cluster_security_group = optional(bool)
    self                          = optional(bool)
  }))
  default = {}
}

variable "eks_version" {
  description = "The version of the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "node_bootstrap_extra_args" {
  description = "Any extra arguments to pass to the bootstrap script for the EKS nodes"
  type        = string
  default     = ""
}

variable "node_pre_bootstrap_script" {
  description = "The pre-bootstrap script to run on the EKS nodes"
  type        = string
  default     = ""
}

variable "node_post_bootstrap_script" {
  description = "The post-bootstrap script to run on the EKS nodes"
  type        = string
  default     = ""
}

variable "node_labels" {
  description = "The labels to apply to the EKS nodes"
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "The taints to apply to the EKS nodes"
  type        = map(string)
  default     = {}
}

################################# EFS Variables #################################
variable "efs_availability_zone_name" {
  description = "The availability zone for the EFS"
  type        = string
  default     = ""
}

variable "efs_directory_permissions" {
  description = "The directory permissions for the EFS"
  type        = string
  default     = "0700"
}

variable "efs_encryption_enabled" {
  description = "Enable encryption for the EFS"
  type        = bool
  default     = true
}

variable "efs_lifecycle_policy_transition_to_archive" {
  description = "The transition to archive policy for the EFS"
  type        = string
  default     = "AFTER_180_DAYS"
}

variable "efs_lifecycle_policy_transition_to_ia" {
  description = "The transition to IA policy for the EFS"
  type        = string
  default     = "AFTER_90_DAYS"
}

variable "efs_lifecycle_policy_transition_to_primary_storage_class" {
  description = "The transition to primary storage class policy for the EFS"
  type        = string
  default     = "AFTER_1_ACCESS"
}

variable "efs_provisioned_throughput_in_mibps" {
  description = "The provisioned throughput for the EFS"
  type        = number
  default     = 0
}

variable "efs_performance_mode" {
  description = "The performance mode for the EFS"
  type        = string
  default     = "generalPurpose"
}

variable "efs_protection_replication_overwrite" {
  description = "The replication overwrite protection for the EFS"
  type        = string
  default     = "DISABLED"
}

variable "efs_tags" {
  description = "The tags to apply to the EFS"
  type        = map(string)
  default     = {}
}

variable "efs_throughput_mode" {
  description = "The throughput mode for the EFS"
  type        = string
  default     = "bursting"
}

################################# Pod Identities #################################
variable "enable_eks_pod_identities" {
  type    = bool
  default = true
}

variable "pod_identity_tags" {
  description = "The tags to apply to the Pod Identities"
  type        = map(string)
  default     = {}
}

################################# Karpenter Variables #################################
variable "kp_chart_version" {
  description = "Karpenter helm chart version"
  type        = string
  default     = "0.37.0"
}

variable "karpenter_tags" {
  description = "The tags to apply to the Karpenter deployment"
  type        = map(string)
  default     = {}
}

################################# S3 Variables #################################
variable "main_bucket_tags" {
  description = "The tags to apply to the main bucket"
  type        = map(string)
  default     = {}
}

variable "logging_bucket_tags" {
  description = "The tags to apply to the logging bucket"
  type        = map(string)
  default     = {}
}
