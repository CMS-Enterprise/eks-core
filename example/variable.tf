variable "cluster_name" {
    type = string

}

variable "cluster_project" {
    type = string

}

variable "cluster_env" {
    type = string

}
variable "vpc_lookup_override" {
  description = "Some VPCs don't follow standard naming conventions.  Use this to override the query used to lookup VPC names.  Accepts wildcard in form of '*'"
  default     = ""
  type        = string

}

variable "subnet_lookup_overrides" {
  description = "Some Subnets don't follow standard naming conventions.  Use this map to override the query used for looking up Subnets.  Ex: { private = \"foo-west-nonpublic-*\" }"
  default     = {}
  type        = map(string)
}