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
  cluster_custom_name = "mowery-test"
  env                 = "impl"
  gold_image_date     = "2024-07"
  ado                 = "batcave"
  program_office      = "batman"
}
