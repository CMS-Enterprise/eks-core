################################# Main Variables #################################
variable "custom_ami_id" {
  description = "The custom AMI ID to use for the EKS nodes"
  type        = string
  default     = ""
}

variable "env" {
  default = "dev"
}

variable "project" {
  default = "batcave"
}

################################# VPC Variables #################################

variable "subnet_lookup_overrides" {
  description = "Some Subnets don't follow standard naming conventions.  Use this map to override the query used for looking up Subnets.  Ex: { private = \"foo-west-nonpublic-*\" }"
  default     = {}
  type        = map(string)
}

variable "create_s3_vpc_endpoint" {
  type        = bool
  description = "toggle on/off the creation of s3 vpc endpoint"
  default     = true
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

################################# Fluentbit #################################
variable "fb_chart_verison" {
  description = "Fluentbit Helm Chart Version"
  type        = string
  default     = "0.30.3"
}

variable "fb_log_group_name" {
  description = "Fluentbit Log group name"
  type        = string
  default     = "fluent-bit-cloudwatch"
}

variable "fb_log_system_group_name" {
  description = "Fluentbit systemD Log group name"
  type        = string
  default     = "fluent-bit-cloudwatch"
}

variable "fb_log_encryption" {
  description = "Enable Fluentbit Log Encryption"
  type        = bool
  default     = false
}

variable "fb_log_systemd" {
  description = "Enable Fluentbit Log Encryption"
  type        = bool
  default     = true
}

variable "fb_kms_key_id" {
  description = "Fluentbit Log Encryption KMS Key ID"
  type        = string
  default     = ""
}

variable "fb_tags" {
  description = "The tags to apply to the Fluentbit"
  type        = map(string)
  default     = {}
}

variable "fb_log_retention" {
  description = "Days to retain Fluentbit logs"
  type        = number
  default     = 7
}

variable "fb_system_log_retention" {
  description = "Days to retain Fluentbit systemD logs"
  type        = number
  default     = 7
}

variable "drop_namespaces" {
  type = list(string)
  default = [
    "kube-system",
    "cert-manager"
  ]
  description = "Flunt bit doesn't send logs for this namespaces"
}

variable "kube_namespaces" {
  type = list(string)
  default = [
    "kube.*",
    "cert-manager.*"
  ]
  description = "Kubernates namespaces"
}

variable "log_filters" {
  type = list(string)
  default = [
    "kube-probe",
    "health",
    "prometheus",
    "liveness"
  ]
  description = "Fluent bit doesn't send logs if message consists of this values"
}

variable "additional_log_filters" {
  type = list(string)
  default = [
    "ELB-HealthChecker",
    "Amazon-Route53-Health-Check-Service",
  ]
  description = "Fluent bit doesn't send logs if message consists of this values"
}

################################# Karpenter Variables #################################
variable "kp_chart_verison" {
  description = "Karpenter Helm Chart Version"
  type        = string
  default     = "0.37.0"
}

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
