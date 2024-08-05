data "aws_subnets" "container" {
  filter {
    name = "tag:Name"
    values = [
      try(var.subnet_lookup_overrides.container, "${var.ado}-*-${var.env}-unroutable-*")
    ]
  }
}

data "aws_subnet" "container" {
  for_each = toset(data.aws_subnets.container.ids)
  id       = each.value
}
