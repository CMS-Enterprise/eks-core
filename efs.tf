resource "aws_efs_file_system" "main" {
  availability_zone_name          = var.efs_availability_zone_name == "" ? null : var.efs_availability_zone_name
  creation_token                  = "efs-${module.eks.cluster_name}"
  encrypted                       = var.efs_encryption_enabled
  kms_key_id                      = var.efs_encryption_enabled ? module.efs_kms.key_arn : null
  performance_mode                = var.efs_performance_mode
  provisioned_throughput_in_mibps = var.efs_throughput_mode == "provisioned" ? var.efs_provisioned_throughput_in_mibps : null
  throughput_mode                 = var.efs_throughput_mode

  dynamic "lifecycle_policy" {
    for_each = var.efs_throughput_mode == "elastic" ? [1] : []

    content {
      transition_to_archive               = var.efs_throughput_mode == "elastic" ? var.efs_lifecycle_policy_transition_to_archive : null
      transition_to_ia                    = var.efs_throughput_mode == "elastic" ? var.efs_lifecycle_policy_transition_to_ia : null
      transition_to_primary_storage_class = var.efs_throughput_mode == "elastic" ? var.efs_lifecycle_policy_transition_to_primary_storage_class : null
    }
  }

  protection {
    replication_overwrite = var.efs_protection_replication_overwrite
  }

  tags = merge(var.efs_tags, local.tags_for_all_resources, { "Name" = "efs-${module.eks.cluster_name}" })
}

resource "aws_efs_mount_target" "main" {
  for_each        = toset(local.all_private_subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = each.value
  security_groups = [module.eks.node_security_group_id]
}