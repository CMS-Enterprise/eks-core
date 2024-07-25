resource "aws_security_group" "alb" {
  name        = "alb-${local.cluster_name}"
  description = "Allow traffic for ALB"
  vpc_id      = data.aws_vpc.vpc.id

  tags = merge(local.tags_for_all_resources, {
    Name = "alb-${local.cluster_name}"
  })
}

resource "aws_security_group_rule" "alb" {
  for_each = local.alb_security_group_rules

  security_group_id = aws_security_group.alb.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  type              = each.value.type
  cidr_blocks       = each.value.cidr_blocks
}

# resource "time_sleep" "alb_propagation" {
#   # This is to allow time for the alb to be created by the lb controller in EKS for ArgoCD
#   create_duration = "1m"

#   triggers = {
#     argocd_sub_domain = module.eks_addons.argocd_sub_domain
#   }
