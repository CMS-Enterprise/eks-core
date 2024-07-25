# resource "aws_route53_record" "argocd" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "${time_sleep.alb_propagation.triggers["argocd_sub_domain"]}.${data.aws_route53_zone.main.name}"
#   type    = "A"

#   alias {
#     name                   = data.aws_lb.k8s_alb.dns_name
#     zone_id                = data.aws_lb.k8s_alb.zone_id
#     evaluate_target_health = true
#   }
# }