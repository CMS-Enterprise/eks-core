################################# Main Variables #################################
variable "custom_ami_id" {
  description = "The custom AMI ID to use for the EKS nodes"
  type        = string
  default     = ""
}

variable "env" {
  description = "The environment name"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "The project name"
  type        = string
  default     = "batcave"
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
  default     = 6
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

variable "pod_identity_tags" {
  description = "The tags to apply to the Pod Identities"
  type        = map(string)
  default     = {}
}

################################# Fluent-bit #################################
variable "fb_chart_verison" {
  description = "Fluent-bit helm chart version"
  type        = string
  default     = "0.1.33"
}

variable "fb_log_encryption" {
  description = "Enable Fluent-bit log encryption"
  type        = bool
  default     = true
}

variable "fb_log_systemd" {
  description = "Enable Fluent-bit cloudwatch logging for systemd"
  type        = bool
  default     = true
}

variable "fb_tags" {
  description = "The tags to apply to the fluent-bit deployment"
  type        = map(string)
  default     = {}
}

variable "fb_log_retention" {
  description = "Days to retain Fluent-bit logs"
  type        = number
  default     = 7
}

variable "fb_system_log_retention" {
  description = "Days to retain Fluent-bit systemd logs"
  type        = number
  default     = 7
}

variable "drop_namespaces" {
  type = list(string)
  default = [
    "kube-system",
    "cert-manager"
  ]
  description = "Fluent-bit doesn't send logs for these namespaces"
}

variable "kube_namespaces" {
  type = list(string)
  default = [
    "kube.*",
    "cert-manager.*"
  ]
  description = "Kubernetes namespaces"
}

variable "log_filters" {
  type = list(string)
  default = [
    "kube-probe",
    "health",
    "prometheus",
    "liveness"
  ]
  description = "Fluent-bit doesn't send logs if message consists of these values"
}

variable "additional_log_filters" {
  type = list(string)
  default = [
    "ELB-HealthChecker",
    "Amazon-Route53-Health-Check-Service",
  ]
  description = "Fluent-bit doesn't send logs if message consists of these values"
}

################################# Karpenter Variables #################################
variable "kp_chart_verison" {
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
