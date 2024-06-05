variable "cluster_custom_name" {
  description = "The name of the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("-", var.cluster_custom_name))
    error_message = "The Cluster Name must contain a '-'. Example: 'name-test'"
  }
}

variable "custom_ami_id" {
  description = "The custom AMI ID to use for the EKS nodes"
  type        = string
  default     = ""
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

variable "tags" {
  type    = map(any)
  default = {}
}

#EKS Pod Identities
variable "enable_eks_pod_identities" {
  type    = bool
  default = true
}

variable "ebs_encryption_key" {
  type    = string
  default = ""
}

variable "node_termination_handler_sqs_arns" {
  type    = list(any)
  default = []
}
