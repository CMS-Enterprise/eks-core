#VPC
variable "env" {
  default = "dev"
}

variable "project" {
  default = "batcave"
}

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
