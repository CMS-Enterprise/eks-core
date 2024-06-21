# terraform {
#   backend "s3" {
#     bucket = "eks-core-dev-terraform"
#     key    = "terraform.tfstate"
#     region = "us-east-1"
#
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
#
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = ">= 4.20.0"
#     }
#   }
# }

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Creator = "Terraform"
    }
  }
}

module "main-eks" {
  source = "../"

  cluster_custom_name = "eks-core-dev"
  env                 = "dev"
  gold_image_date     = "2024-05"
  project             = "eks-core"
}
