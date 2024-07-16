provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Creator = "Terraform"
    }
  }
}

module "main-eks" {
  source              = "git@github.com:CMS-Enterprise/Energon-Kube.git?ref=arun-dev"

  cluster_custom_name = "a-test"
  env                 = "impl"
  gold_image_date     = "2024-05"
  ado                 = "batcave"
  program_office      = "batman"
}
