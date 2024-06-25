module "s3_main" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  allowed_kms_key_arn                   = module.s3_kms.key_arn
  attach_deny_insecure_transport_policy = true
  attach_policy                         = true
  block_public_acls                     = true
  block_public_policy                   = true
  bucket                                = "${local.cluster_name}-main-${random_string.s3.result}"
  create_bucket                         = true
  control_object_ownership              = true
  force_destroy                         = true
  ignore_public_acls                    = true
  object_ownership                      = "BucketOwnerEnforced"

  lifecycle_rule = []

  logging = {
    target_bucket = module.s3_logs.s3_bucket_id,
    target_prefix = "/"
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = merge(var.main_bucket_tags, {
    Name = "${local.cluster_name}-main"
  })

  versioning = {
    enabled = true
  }
}

module "s3_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  allowed_kms_key_arn                   = module.s3_kms.key_arn
  attach_access_log_delivery_policy     = true
  attach_deny_insecure_transport_policy = true
  attach_elb_log_delivery_policy        = true
  attach_lb_log_delivery_policy         = true
  attach_policy                         = true
  block_public_acls                     = true
  block_public_policy                   = true
  bucket                                = "${local.cluster_name}-logs-${random_string.s3.result}"
  create_bucket                         = true
  control_object_ownership              = true
  force_destroy                         = true
  ignore_public_acls                    = true
  object_ownership                      = "BucketOwnerEnforced"

  lifecycle_rule = [
    {
      id                                     = "main-logs"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7
      expiration = [
        {
          days                         = 365
          expired_object_delete_marker = true
        }
      ]
      transition = [
        {
          days          = 60
          storage_class = "STANDARD_IA"
        },
        {
          days          = 180
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      noncurrent_version_expiration = [
        {
          newer_noncurrent_versions = 25
          noncurrent_days           = 365
        }
      ]
      noncurrent_version_transition = [
        {
          newer_noncurrent_versions = 25
          noncurrent_days           = 60
          storage_class             = "STANDARD_IA"
        },
        {
          newer_noncurrent_versions = 25
          noncurrent_days           = 180
          storage_class             = "DEEP_ARCHIVE"
        }
      ]
    }
  ]
  # TODO: This will create recursive logging. Please disable this.
  logging = {}

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = merge(var.logging_bucket_tags, {
    Name = "${local.cluster_name}-Logs"
  })

  #TODO: please disable this
  versioning = {
    enabled = true
  }
}
