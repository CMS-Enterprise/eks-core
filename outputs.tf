#################################################################################
###################################### EKS ######################################
#################################################################################

output "eks_access_entries" {
  description = "EKS access entries"
  value       = module.eks.access_entries
}

output "eks_access_policy_associations" {
  description = "EKS access policy associations"
  value       = module.eks.access_policy_associations
}

output "eks_autoscaling_group_schedule_arns" {
  description = "EKS autoscaling group schedule ARNs"
  value       = module.main_nodes.autoscaling_group_schedule_arns
}

output "eks_cloudwatch_log_group_arn" {
  description = "EKS CloudWatch log group ARN"
  value       = module.eks.cloudwatch_log_group_arn
}

output "eks_cloudwatch_log_group_name" {
  description = "EKS CloudWatch log group name"
  value       = module.eks.cloudwatch_log_group_name
}

output "eks_cluster_addons" {
  description = "EKS cluster addons"
  value       = module.eks.cluster_addons
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "eks_cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_iam_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = module.eks.cluster_iam_role_arn
}

output "eks_cluster_iam_role_name" {
  description = "EKS cluster IAM role name"
  value       = module.eks.cluster_iam_role_name
}

output "eks_cluster_iam_role_unique_id" {
  description = "EKS cluster IAM role unique ID"
  value       = module.eks.cluster_iam_role_unique_id
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_identity_providers" {
  description = "EKS cluster identity providers"
  value       = module.eks.cluster_identity_providers
}

output "eks_cluster_ip_family" {
  description = "EKS cluster IP family"
  value       = module.eks.cluster_ip_family
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  value       = module.eks.cluster_oidc_issuer_url
}

output "eks_cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = module.eks.cluster_platform_version
}

output "eks_cluster_primary_security_group_id" {
  description = "EKS cluster primary security group ID"
  value       = module.eks.cluster_primary_security_group_id
}

output "eks_cluster_security_group_arn" {
  description = "EKS cluster security group ARN"
  value       = module.eks.cluster_security_group_arn
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "eks_cluster_service_cidr" {
  description = "EKS cluster service CIDR"
  value       = module.eks.cluster_service_cidr
}

output "eks_cluster_status" {
  description = "EKS cluster status"
  value       = module.eks.cluster_status
}

output "eks_cluster_tls_certificate_sha1_fingerprint" {
  description = "EKS cluster TLS certificate SHA-1 fingerprint"
  value       = module.eks.cluster_tls_certificate_sha1_fingerprint
}

output "eks_cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}

output "eks_iam_role_arn" {
  description = "EKS IAM role ARN"
  value       = module.main_nodes.iam_role_arn
}

output "eks_iam_role_name" {
  description = "EKS IAM role name"
  value       = module.main_nodes.iam_role_name
}

output "eks_iam_role_unique_id" {
  description = "EKS IAM role unique ID"
  value       = module.main_nodes.iam_role_unique_id
}

output "eks_kms_key_arn" {
  description = "EKS KMS key ARN"
  value       = module.eks.kms_key_arn
}

output "eks_kms_key_id" {
  description = "EKS KMS key ID"
  value       = module.eks.kms_key_id
}

output "eks_kms_key_policy" {
  description = "EKS KMS key policy"
  value       = module.eks.kms_key_policy
}

output "eks_launch_template_arn" {
  description = "EKS launch template ARN"
  value       = module.main_nodes.launch_template_arn
}

output "eks_launch_template_id" {
  description = "EKS launch template ID"
  value       = module.main_nodes.launch_template_id
}

output "eks_launch_template_latest_version" {
  description = "EKS launch template latest version"
  value       = module.main_nodes.launch_template_latest_version
}

output "eks_launch_template_name" {
  description = "EKS launch template name"
  value       = module.main_nodes.launch_template_name
}

output "eks_node_group_arn" {
  description = "EKS node group ARN"
  value       = module.main_nodes.node_group_arn
}

output "eks_node_group_autoscaling_group_names" {
  description = "EKS node group autoscaling group names"
  value       = module.main_nodes.node_group_autoscaling_group_names
}

output "eks_node_group_id" {
  description = "EKS node group ID"
  value       = module.main_nodes.node_group_id
}

output "eks_node_group_labels" {
  description = "EKS node group labels"
  value       = module.main_nodes.node_group_labels
}

output "eks_node_group_resources" {
  description = "EKS node group resources"
  value       = module.main_nodes.node_group_resources
}

output "eks_node_group_status" {
  description = "EKS node group status"
  value       = module.main_nodes.node_group_status
}

output "eks_node_group_taints" {
  description = "EKS node group taints"
  value       = module.main_nodes.node_group_taints
}

output "eks_node_security_group_arn" {
  description = "EKS node security group ARN"
  value       = module.eks.node_security_group_arn
}

output "eks_node_security_group_id" {
  description = "EKS node security group ID"
  value       = module.eks.node_security_group_id
}

output "eks_oidc_provider" {
  description = "EKS OIDC provider"
  value       = module.eks.oidc_provider
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "eks_platform_version" {
  description = "EKS Nodes platform"
  value       = module.main_nodes.platform
}

#################################################################################
###################################### KMS ######################################
#################################################################################

output "cloudtrail_kms_aliases" {
  description = "CloudTrail KMS aliases"
  value       = module.cloudtrail_kms.aliases
}

output "cloudtrail_kms_external_key_expiration_model" {
  description = "CloudTrail external key expiration model"
  value       = module.cloudtrail_kms.external_key_expiration_model
}

output "cloudtrail_kms_external_key_state" {
  description = "CloudTrail external key state"
  value       = module.cloudtrail_kms.external_key_state
}

output "cloudtrail_kms_external_key_usage" {
  description = "CloudTrail external key usage"
  value       = module.cloudtrail_kms.external_key_usage
}

output "cloudtrail_kms_grants" {
  description = "CloudTrail KMS grants"
  value       = module.cloudtrail_kms.grants
}

output "cloudtrail_kms_key_arn" {
  description = "CloudTrail KMS key ARN"
  value       = module.cloudtrail_kms.key_arn
}

output "cloudtrail_kms_key_id" {
  description = "CloudTrail KMS key ID"
  value       = module.cloudtrail_kms.key_id
}

output "cloudtrail_kms_key_policy" {
  description = "CloudTrail KMS key policy"
  value       = module.cloudtrail_kms.key_policy
}

output "cloudwatch_kms_aliases" {
  description = "CloudWatch KMS aliases"
  value       = module.cloudwatch_kms.aliases
}

output "cloudwatch_kms_external_key_expiration_model" {
  description = "CloudWatch external key expiration model"
  value       = module.cloudwatch_kms.external_key_expiration_model
}

output "cloudwatch_kms_external_key_state" {
  description = "CloudWatch external key state"
  value       = module.cloudwatch_kms.external_key_state
}

output "cloudwatch_kms_external_key_usage" {
  description = "CloudWatch external key usage"
  value       = module.cloudwatch_kms.external_key_usage
}

output "cloudwatch_kms_grants" {
  description = "CloudWatch KMS grants"
  value       = module.cloudwatch_kms.grants
}

output "cloudwatch_logs_kms_arn" {
  description = "CloudWatch logs KMS key ARN"
  value       = module.cloudwatch_kms.key_arn
}

output "cloudwatch_kms_key_id" {
  description = "CloudWatch KMS key ID"
  value       = module.cloudwatch_kms.key_id
}

output "cloudwatch_kms_key_policy" {
  description = "CloudWatch KMS key policy"
  value       = module.cloudwatch_kms.key_policy
}

output "ebs_kms_aliases" {
  description = "EBS KMS aliases"
  value       = module.ebs_kms.aliases
}

output "ebs_kms_external_key_expiration_model" {
  description = "EBS external key expiration model"
  value       = module.ebs_kms.external_key_expiration_model
}

output "ebs_kms_external_key_state" {
  description = "EBS external key state"
  value       = module.ebs_kms.external_key_state
}

output "ebs_kms_external_key_usage" {
  description = "EBS external key usage"
  value       = module.ebs_kms.external_key_usage
}

output "ebs_kms_grants" {
  description = "EBS KMS grants"
  value       = module.ebs_kms.grants
}

output "ebs_kms_key_arn" {
  description = "EBS KMS key ARN"
  value       = module.ebs_kms.key_arn
}

output "ebs_kms_key_id" {
  description = "EBS KMS key ID"
  value       = module.ebs_kms.key_id
}

output "ebs_kms_key_policy" {
  description = "EBS KMS key policy"
  value       = module.ebs_kms.key_policy
}

output "efs_kms_aliases" {
  description = "EFS KMS aliases"
  value       = module.efs_kms.aliases
}

output "efs_kms_external_key_expiration_model" {
  description = "EFS external key expiration model"
  value       = module.efs_kms.external_key_expiration_model
}

output "efs_kms_external_key_state" {
  description = "EFS external key state"
  value       = module.efs_kms.external_key_state
}

output "efs_kms_external_key_usage" {
  description = "EFS external key usage"
  value       = module.efs_kms.external_key_usage
}

output "efs_kms_grants" {
  description = "EFS KMS grants"
  value       = module.efs_kms.grants
}

output "efs_kms_key_arn" {
  description = "EFS KMS key ARN"
  value       = module.efs_kms.key_arn
}

output "efs_kms_key_id" {
  description = "EFS KMS key ID"
  value       = module.efs_kms.key_id
}

output "efs_kms_key_policy" {
  description = "EFS KMS key policy"
  value       = module.efs_kms.key_policy
}

output "s3_kms_aliases" {
  description = "S3 KMS aliases"
  value       = module.s3_kms.aliases
}

output "s3_kms_external_key_expiration_model" {
  description = "S3 external key expiration model"
  value       = module.s3_kms.external_key_expiration_model
}

output "s3_kms_external_key_state" {
  description = "S3 external key state"
  value       = module.s3_kms.external_key_state
}

output "s3_kms_external_key_usage" {
  description = "S3 external key usage"
  value       = module.s3_kms.external_key_usage
}

output "s3_kms_grants" {
  description = "S3 KMS grants"
  value       = module.s3_kms.grants
}

output "s3_kms_key_arn" {
  description = "S3 KMS key ARN"
  value       = module.s3_kms.key_arn
}

output "s3_kms_key_id" {
  description = "S3 KMS key ID"
  value       = module.s3_kms.key_id
}

output "s3_kms_key_policy" {
  description = "S3 KMS key policy"
  value       = module.s3_kms.key_policy
}

output "ssm_kms_aliases" {
  description = "SSM KMS aliases"
  value       = module.ssm_kms.aliases
}

output "ssm_kms_external_key_expiration_model" {
  description = "SSM external key expiration model"
  value       = module.ssm_kms.external_key_expiration_model
}

output "ssm_kms_external_key_state" {
  description = "SSM external key state"
  value       = module.ssm_kms.external_key_state
}

output "ssm_kms_external_key_usage" {
  description = "SSM external key usage"
  value       = module.ssm_kms.external_key_usage
}

output "ssm_kms_grants" {
  description = "SSM KMS grants"
  value       = module.ssm_kms.grants
}

output "ssm_kms_key_arn" {
  description = "SSM KMS key ARN"
  value       = module.ssm_kms.key_arn
}

output "ssm_kms_key_id" {
  description = "SSM KMS key ID"
  value       = module.ssm_kms.key_id
}

output "ssm_kms_key_policy" {
  description = "SSM KMS key policy"
  value       = module.ssm_kms.key_policy
}

############################################################################################
###################################### Pod Identities ######################################
############################################################################################

output "cloudwatch_observability_pod_identity_associations" {
  description = "CloudWatch observability pod identity associations"
  value       = var.enable_eks_pod_identities ? module.aws_cloudwatch_observability_pod_identity[0].associations : {}
}

output "cloudwatch_observability_pod_identity_iam_policy_arn" {
  description = "CloudWatch observability pod identity IAM policy ARN"
  value       = var.enable_eks_pod_identities ? module.aws_cloudwatch_observability_pod_identity[0].iam_policy_arn : ""
}

output "cloudwatch_observability_pod_identity_iam_policy_id" {
  description = "CloudWatch observability pod identity IAM policy ID"
  value       = var.enable_eks_pod_identities ? module.aws_cloudwatch_observability_pod_identity[0].iam_policy_id : ""
}

output "cloudwatch_observability_pod_identity_iam_policy_name" {
  description = "CloudWatch observability pod identity IAM policy name"
  value       = var.enable_eks_pod_identities ? module.aws_cloudwatch_observability_pod_identity[0].iam_policy_name : ""
}

output "cloudwatch_observability_pod_identity_iam_role_arn" {
  description = "CloudWatch observability pod identity IAM role ARN"
  value       = var.enable_eks_pod_identities ? module.aws_cloudwatch_observability_pod_identity[0].iam_role_arn : ""
}

output "cloudwatch_observability_pod_identity_iam_role_name" {
  description = "CloudWatch observability pod identity IAM role name"
  value       = var.enable_eks_pod_identities ? module.aws_cloudwatch_observability_pod_identity[0].iam_role_name : ""
}

output "cloudwatch_observability_pod_identity_iam_role_path" {
  description = "CloudWatch observability pod identity IAM role path"
  value       = var.enable_eks_pod_identities ? module.aws_cloudwatch_observability_pod_identity[0].iam_role_path : ""
}

output "cloudwatch_observability_pod_identity_iam_role_unique_id" {
  description = "CloudWatch observability pod identity IAM role unique ID"
  value       = var.enable_eks_pod_identities ? module.aws_cloudwatch_observability_pod_identity[0].iam_role_unique_id : ""
}

output "ebs_csi_pod_identity_associations" {
  description = "EBS CSI pod identity associations"
  value       = var.enable_eks_pod_identities ? module.aws_ebs_csi_pod_identity[0].associations : {}
}

output "ebs_csi_pod_identity_iam_policy_arn" {
  description = "EBS CSI pod identity IAM policy ARN"
  value       = var.enable_eks_pod_identities ? module.aws_ebs_csi_pod_identity[0].iam_policy_arn : ""
}

output "ebs_csi_pod_identity_iam_policy_id" {
  description = "EBS CSI pod identity IAM policy ID"
  value       = var.enable_eks_pod_identities ? module.aws_ebs_csi_pod_identity[0].iam_policy_id : ""
}

output "ebs_csi_pod_identity_iam_policy_name" {
  description = "EBS CSI pod identity IAM policy name"
  value       = var.enable_eks_pod_identities ? module.aws_ebs_csi_pod_identity[0].iam_policy_name : ""
}

output "ebs_csi_pod_identity_iam_role_arn" {
  description = "EBS CSI pod identity IAM role ARN"
  value       = var.enable_eks_pod_identities ? module.aws_ebs_csi_pod_identity[0].iam_role_arn : ""
}

output "ebs_csi_pod_identity_iam_role_name" {
  description = "EBS CSI pod identity IAM role name"
  value       = var.enable_eks_pod_identities ? module.aws_ebs_csi_pod_identity[0].iam_role_name : ""
}

output "ebs_csi_pod_identity_iam_role_path" {
  description = "EBS CSI pod identity IAM role path"
  value       = var.enable_eks_pod_identities ? module.aws_ebs_csi_pod_identity[0].iam_role_path : ""
}

output "ebs_csi_pod_identity_iam_role_unique_id" {
  description = "EBS CSI pod identity IAM role unique ID"
  value       = var.enable_eks_pod_identities ? module.aws_ebs_csi_pod_identity[0].iam_role_unique_id : ""
}

output "efs_csi_pod_identity_associations" {
  description = "EFS CSI pod identity associations"
  value       = var.enable_eks_pod_identities ? module.aws_efs_csi_pod_identity[0].associations : {}
}

output "efs_csi_pod_identity_iam_policy_arn" {
  description = "EFS CSI pod identity IAM policy ARN"
  value       = var.enable_eks_pod_identities ? module.aws_efs_csi_pod_identity[0].iam_policy_arn : ""
}

output "efs_csi_pod_identity_iam_policy_id" {
  description = "EFS CSI pod identity IAM policy ID"
  value       = var.enable_eks_pod_identities ? module.aws_efs_csi_pod_identity[0].iam_policy_id : ""
}

output "efs_csi_pod_identity_iam_policy_name" {
  description = "EFS CSI pod identity IAM policy name"
  value       = var.enable_eks_pod_identities ? module.aws_efs_csi_pod_identity[0].iam_policy_name : ""
}

output "efs_csi_pod_identity_iam_role_arn" {
  description = "EFS CSI pod identity IAM role ARN"
  value       = var.enable_eks_pod_identities ? module.aws_efs_csi_pod_identity[0].iam_role_arn : ""
}

output "efs_csi_pod_identity_iam_role_name" {
  description = "EFS CSI pod identity IAM role name"
  value       = var.enable_eks_pod_identities ? module.aws_efs_csi_pod_identity[0].iam_role_name : ""
}

output "efs_csi_pod_identity_iam_role_path" {
  description = "EFS CSI pod identity IAM role path"
  value       = var.enable_eks_pod_identities ? module.aws_efs_csi_pod_identity[0].iam_role_path : ""
}

output "efs_csi_pod_identity_iam_role_unique_id" {
  description = "EFS CSI pod identity IAM role unique ID"
  value       = var.enable_eks_pod_identities ? module.aws_efs_csi_pod_identity[0].iam_role_unique_id : ""
}

output "lb_controller_pod_identity_associations" {
  description = "LB controller pod identity associations"
  value       = var.enable_eks_pod_identities ? module.aws_lb_controller_pod_identity[0].associations : {}
}

output "lb_controller_pod_identity_iam_policy_arn" {
  description = "LB controller pod identity IAM policy ARN"
  value       = var.enable_eks_pod_identities ? module.aws_lb_controller_pod_identity[0].iam_policy_arn : ""
}

output "lb_controller_pod_identity_iam_policy_id" {
  description = "LB controller pod identity IAM policy ID"
  value       = var.enable_eks_pod_identities ? module.aws_lb_controller_pod_identity[0].iam_policy_id : ""
}

output "lb_controller_pod_identity_iam_policy_name" {
  description = "LB controller pod identity IAM policy name"
  value       = var.enable_eks_pod_identities ? module.aws_lb_controller_pod_identity[0].iam_policy_name : ""
}

output "lb_controller_pod_identity_iam_role_arn" {
  description = "LB controller pod identity IAM role ARN"
  value       = var.enable_eks_pod_identities ? module.aws_lb_controller_pod_identity[0].iam_role_arn : ""
}

output "lb_controller_pod_identity_iam_role_name" {
  description = "LB controller pod identity IAM role name"
  value       = var.enable_eks_pod_identities ? module.aws_lb_controller_pod_identity[0].iam_role_name : ""
}

output "lb_controller_pod_identity_iam_role_path" {
  description = "LB controller pod identity IAM role path"
  value       = var.enable_eks_pod_identities ? module.aws_lb_controller_pod_identity[0].iam_role_path : ""
}

output "lb_controller_pod_identity_iam_role_unique_id" {
  description = "LB controller pod identity IAM role unique ID"
  value       = var.enable_eks_pod_identities ? module.aws_lb_controller_pod_identity[0].iam_role_unique_id : ""
}

#################################################################################
###################################### VPC ######################################
#################################################################################

output "container_subnet_ids" {
  description = "Container subnet IDs"
  value       = data.aws_subnets.container.ids
}

output "container_subnets_by_zone" {
  description = "map of AZs to container subnet ids"
  value       = { for container in data.aws_subnet.container : container.availability_zone => container.id }
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = data.aws_subnets.private.ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = data.aws_subnets.public.ids
}

output "vpc_arn" {
  description = "VPC ARN"
  value       = data.aws_vpc.vpc.arn
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = data.aws_vpc.vpc.cidr_block
}

output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.vpc.id
}

#################################################################################
###################################### EFS ######################################
#################################################################################

output "efs_file_system_arn" {
  description = "EFS file system ARN"
  value       = aws_efs_file_system.main.arn
}

output "efs_file_system_availability_zone" {
  description = "EFS file system availability zone"
  value       = aws_efs_file_system.main.availability_zone_name
}

output "efs_file_system_dns_name" {
  description = "EFS file system DNS name"
  value       = aws_efs_file_system.main.dns_name
}

output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.main.id
}

output "efs_file_system_number_of_mount_targets" {
  description = "EFS file system number of mount targets"
  value       = aws_efs_file_system.main.number_of_mount_targets
}

output "efs_file_system_owner_id" {
  description = "EFS file system owner ID"
  value       = aws_efs_file_system.main.owner_id
}

output "efs_file_system_tags_all" {
  description = "EFS file system tags"
  value       = aws_efs_file_system.main.tags_all
}

output "efs_mount_target_availability_zone_ids" {
  description = "EFS mount target availability zone IDs"
  value       = [ for resource in aws_efs_mount_target.main : resource.availability_zone_id ]
}

output "efs_mount_target_availability_zone_names" {
  description = "EFS mount target availability zone names"
  value       = [ for resource in aws_efs_mount_target.main : resource.availability_zone_name ]
}

output "efs_mount_target_dns_names" {
  description = "EFS mount target DNS names"
  value       = [ for resource in aws_efs_mount_target.main : resource.dns_name ]
}

output "efs_mount_target_file_system_ids" {
  description = "EFS mount target file system IDs"
  value       = [ for resource in aws_efs_mount_target.main : resource.file_system_id ]
}

output "efs_mount_target_ids" {
  description = "EFS mount target IDs"
  value       = [ for resource in aws_efs_mount_target.main : resource.id ]
}

output "efs_mount_target_file_system_arns" {
  description = "EFS mount target file system ARNs"
  value       = [ for resource in aws_efs_mount_target.main : resource.file_system_arn ]
}

output "efs_mount_target_network_interface_ids" {
  description = "EFS mount target network interface IDs"
  value       = [ for resource in aws_efs_mount_target.main : resource.network_interface_id ]
}

output "efs_mount_target_owner_ids" {
  description = "EFS mount target owner IDs"
  value       = [ for resource in aws_efs_mount_target.main : resource.owner_id ]
}