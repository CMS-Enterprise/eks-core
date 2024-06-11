################################# Main Variables #################################
variable "custom_ami_id" {
  description = "The custom AMI ID to use for the EKS nodes"
  type        = string
  default     = ""
}

variable "gold_image_date" {
  description = "Gold Image Date in YYYYMM format"
  type        = string
  default     = ""
  validation {
    condition     = can(regex("^\\d{4}(0[1-9]|1[0-2])$", var.gold_image_date)) || var.gold_image_date == ""
    error_message = "gold_image_date must be in the YYYYMM format."
  }
}

variable "use_bottlerocket" {
  description = "Use Bottlerocket AMI for EKS nodes"
  type        = bool
  default     = false
}

################################# EKS Variables #################################
variable "cluster_custom_name" {
  description = "The name of the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("-", var.cluster_custom_name))
    error_message = "The Cluster Name must contain a '-'. Example: 'name-test'"
  }
}

variable "eks_access_entries" {
  description = "The access entries to apply to the EKS cluster"
  type        = map(object({
    principal_arn        = string
    type                 = string
    policy_associations = map(object({
      policy_arn   = string
      access_scope = map(object({
        type = string
      }))
    }))
  }))
  default = {}
}

variable "eks_cluster_tags" {
  description = "The tags to apply to the EKS cluster"
  type        = map(string)
  default     = {}
}

variable "eks_node_tags" {
  description = "The tags to apply to the EKS nodes"
  type        = map(string)
  default     = {}
}

variable "eks_security_group_additional_rules" {
  description = "Additional rules to add to the EKS node security group"
  type = map(object({
    description                   = string
    protocol                      = string
    type                          = string
    from_port                     = number
    to_port                       = number
    source_cluster_security_group = bool
  }))
  default = {}
}

variable "eks_version" {
  description = "The version of the EKS cluster"
  type        = string
  default     = "1.29"
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

################################# Load Balancer Controller Variables #################################
variable "lb_controller_tags" {
  description = "The tags to apply to the Load Balancer Controller"
  type        = map(string)
  default     = {}
}

################################# Pod Identities #################################
variable "enable_eks_pod_identities" {
  type    = bool
  default = true
}

variable "ebs_encryption_key" {
  type    = string
  default = ""
}

variable "pod_identity_tags" {
  description = "The tags to apply to the Pod Identities"
  type        = map(string)
  default     = {}
}

################################# Karpenter Variables #################################
variable "karpenter_tags" {
  description = "The tags to apply to the Karpenter"
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
