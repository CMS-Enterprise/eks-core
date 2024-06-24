provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Creator = "Terraform"
    }
  }
}

module "main-eks" {
  source = "git::https://github.com/CMS-Enterprise/Energon-Kube.git?ref=feature/null_resource_fix"

  cluster_custom_name = "max-test"
  env                 = "impl"
  gold_image_date     = "2024-05"
  project             = "batcave"
}
