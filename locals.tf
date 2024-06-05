locals {
  asg_names = module.main_nodes.node_group_autoscaling_group_names
  asg_arns  = [for name in local.asg_names : "arn:aws:autoscaling:${var.region}:${data.aws_caller_identity.current.account_id}:autoScalingGroupName/${name}"]
}
