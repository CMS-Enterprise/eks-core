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

  cluster_custom_name = "afaras-test"
  env                 = "impl"
  gold_image_date     = "2024-05"
  project             = "batcave"
}

output "container_subnets_by_zone" {
  description = "map of AZs to container subnet ids"
  value       = module.main-eks.container_subnets_by_zone
}
