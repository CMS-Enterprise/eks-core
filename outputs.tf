output "container_subnets_by_zone" {
  description = "map of AZs to container subnet ids"
  value       = { for container in data.aws_subnet.container : container.availability_zone => container.id }
}

output "alb_sg_id" {
  description = "The Security Group ID for ALB"
  value       = aws_security_group.alb_sg.id
}
