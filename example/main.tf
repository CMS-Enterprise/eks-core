provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Creator = "Terraform"
    }
  }
}

module "main-eks" {
  source = "git::https://github.com/CMS-Enterprise/Energon-Kube.git?ref=3.0.0"

  cluster_custom_name = "temp-test"
  env                 = "impl"
  gold_image_date     = "2024-05"
  project             = "batcave"
}
