provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Creator = "Terraform"
    }
  }
}

variable "cluster_custom_name" {
  type    = string
  default = "cms-eks-core"
}

variable "env" {
  type    = string
  default = "impl"
}

variable "gold_image_date" {
  type    = string
  default = "2024-05"
}

variable "project" {
  type    = string
  default = "CMS-Enterprise"
}

module "main-eks" {
  source = "../"

  cluster_custom_name = var.cluster_custom_name
  env                 = var.env
  gold_image_date     = var.gold_image_date
  project             = var.project
}
