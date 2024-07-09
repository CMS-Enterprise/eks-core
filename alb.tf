resource "aws_security_group" "alb_sg" {
  name        = "${local.cluster_name}-ALB-SG"
  description = "Allow HTTP & HTTPS Traffic from CMS cloudVPN and Zscaler"
  vpc_id      = data.aws_vpc.vpc.id

  tags = merge(var.eks_cluster_tags,
    {
      Name = "${local.cluster_name}-ALB-SG"
  })
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = local.cluster_security_group_prefix_list_ids
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  prefix_list_ids   = local.cluster_security_group_prefix_list_ids
  security_group_id = aws_security_group.alb_sg.id
}
