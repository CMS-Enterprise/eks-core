output "container_subnets_by_zone" {
  description = "map of AZs to container subnet ids"
  value       = { for container in data.aws_subnet.container : container.availability_zone => container.id }
}