module "cloudtrail_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.0.0"

  aliases                            = ["${local.cluster_name}-cloudtrail"]
  bypass_policy_lockout_safety_check = false
  create                             = true
  deletion_window_in_days            = 7
  description                        = "Encrypt and decrypt data for cloudtrail"
  enable_default_policy              = true
  enable_key_rotation                = true
  is_enabled                         = true
  key_administrators                 = [data.aws_caller_identity.current.arn] # Needs to change to the specific need-to-know roles
  key_owners                         = [data.aws_caller_identity.current.arn]
  rotation_period_in_days            = 90

  key_statements = [
    {
      sid     = "Enable CloudTrail Permissions"
      actions = ["kms:GenerateDataKey*", "kms:DescribeKey"]
      principals = [
        {
          type = "Service"
          identifiers = ["cloudtrail.amazonaws.com"]
        }
      ]
      resources = ["*"]
      condition = [
        {
          test     = "StringLike"
          variable = "kms:EncryptionContext:aws:cloudtrail:arn"
          values = [
            "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/*"
          ]
        }
      ]
    },
    {
      sid     = "Enable users to decrypt"
      actions = ["kms:Decrypt"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      resources = [module.s3_logs.s3_bucket_arn]
      condition = [
        {
          test     = "Null"
          variable = "kms:EncryptionContext:aws:cloudtrail:arn"
          values   = ["false"]
        }
      ]
    }
  ]

  tags = {
    Name = "CloudTrail"
  }
}

module "cloudwatch_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.0.0"

  aliases                            = ["${local.cluster_name}-cloudwatch"]
  bypass_policy_lockout_safety_check = false
  create                             = true
  deletion_window_in_days            = 7
  description                        = "Encrypt and decrypt data for cloudwatch"
  enable_default_policy              = true
  enable_key_rotation                = true
  is_enabled                         = true
  key_administrators                 = [data.aws_caller_identity.current.arn] # Needs to change to the specific need-to-know roles
  key_owners                         = [data.aws_caller_identity.current.arn]
  key_usage                          = "ENCRYPT_DECRYPT"
  rotation_period_in_days            = 90

  key_statements = [
    {
      sid    = "AllowCloudwatchLogging",
      effect = "Allow",
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      resources = ["*"],
      principals = [
        {
          type        = "Service",
          identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
        }
      ]
    }
  ]

  tags = {
    Name = "CloudWatch"
  }
}

module "ebs_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.0.0"

  aliases                            = ["${local.cluster_name}-ebs"]
  bypass_policy_lockout_safety_check = false
  create                             = true
  deletion_window_in_days            = 7
  description                        = "Encrypt and decrypt data for EBS"
  enable_default_policy              = true
  enable_key_rotation                = true
  is_enabled                         = true
  key_administrators                 = [data.aws_caller_identity.current.arn] # Needs to change to the specific need-to-know roles
  key_owners                         = [data.aws_caller_identity.current.arn]
  key_usage                          = "ENCRYPT_DECRYPT"
  key_users                          = ["*"]
  rotation_period_in_days            = 90

  tags = {
    Name = "EBS"
  }
}

module "s3_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.0.0"

  aliases                            = ["${local.cluster_name}-s3"]
  bypass_policy_lockout_safety_check = false
  create                             = true
  deletion_window_in_days            = 7
  description                        = "Encrypt and decrypt data for S3"
  enable_default_policy              = true
  enable_key_rotation                = true
  is_enabled                         = true
  key_administrators                 = [data.aws_caller_identity.current.arn] # Needs to change to the specific need-to-know roles
  key_owners                         = [data.aws_caller_identity.current.arn]
  key_service_users                  = ["*"]
  key_usage                          = "ENCRYPT_DECRYPT"
  key_users                          = ["*"]
  rotation_period_in_days            = 90

  tags = {
    Name = "S3"
  }
}

module "ssm_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.0.0"

  aliases                            = ["${local.cluster_name}-ssm"]
  bypass_policy_lockout_safety_check = false
  create                             = true
  deletion_window_in_days            = 7
  description                        = "Encrypt and decrypt data for SSM"
  enable_default_policy              = true
  enable_key_rotation                = true
  is_enabled                         = true
  key_administrators                 = [data.aws_caller_identity.current.arn] # Needs to change to the specific need-to-know roles
  key_owners                         = [data.aws_caller_identity.current.arn]
  key_service_users                  = ["*"]
  key_usage                          = "ENCRYPT_DECRYPT"
  key_users                          = ["*"]
  rotation_period_in_days            = 90

  tags = {
    Name = "SSM"
  }
}