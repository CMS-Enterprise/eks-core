provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Creator = "Terraform"
    }
  }
}

module "main-eks" {
  source = "git@github.com:CMS-Enterprise/Energon-Kube.git?ref=3.1.2"

  cluster_custom_name = "temp-test"
  env                 = "impl"
  gold_image_date     = "2024-07"
  ado                 = "batcave"
  program_office      = "batman"
}
