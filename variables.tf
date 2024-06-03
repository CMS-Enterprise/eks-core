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

variable "secrets" {
  description = "The secrets to store in AWS Secrets Manager"
  type        = map(string)
  default     = {}
}