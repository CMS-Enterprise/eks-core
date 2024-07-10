data "aws_vpc" "vpc" {
  tags = {
    Name = coalesce(var.vpc_lookup_override, "${var.cluster_project}-*-${var.cluster_env}")
  }
}
# private subnets
data "aws_subnets" "private" {
  filter {
    name = "tag:Name"
    values = [
      try(var.subnet_lookup_overrides.private, "${var.cluster_project}-*-${var.cluster_env}-private-*")
    ]
  }
}
data "aws_security_groups" "eksworker" {
    tags = {
    Name = "eks-${var.cluster_name}-node-sg"
  }

}

data "aws_security_groups" "ekscluster" {
    tags = {
    Name = "eks-${var.cluster_name}-cluster-sg"
  }

}
