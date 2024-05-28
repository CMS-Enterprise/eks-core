terraform {
  backend "s3" {
    bucket         = "terraform-test"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.0"
    }
  }
}

provider "aws" {
  region = local.aws_region
  assume_role {
    role_arn     = local.role_to_assume
    session_name = "terraform"
  }
  default_tags {
    tags = {
      creator = "terraform"
    }
  }
}
