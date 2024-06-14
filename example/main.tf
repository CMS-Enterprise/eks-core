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

  cluster_custom_name = "howard-test"
  env                 = "impl"
  gold_image_date     = "2024-05"
  project             = "batcave"
}
