module "cloudtrail_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.0.0"

  aliases                            = ["cloudtrail"]
  bypass_policy_lockout_safety_check = false
  create                             = true
  deletion_window_in_days            = 7
  description                        = "Encrypt and decrypt data for cloudtrail"
  enable_default_policy              = true
  enable_key_rotation                = true
  is_enabled                         = true
  key_administrators                 = [local.role_to_assume] # Needs to change to the specific need-to-know roles
  key_owners                         = [local.role_to_assume]
  rotation_period_in_days            = 90

  key_statements = {
    statement = {
      sid     = "Enable CloudTrail Permissions"
      actions = ["kms:GenerateDataKey*", "kms:DescribeKey"]
      principals = {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }
      resources = ["*"]
      condition = {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:cloudtrail:arn"
        values = [
          "arn:aws:cloudtrail:${local.aws_region}:${data.aws_caller_identity.current.account_id}:trail/*"
        ]
      }
    },
    statement = {
      sid     = "Enable users to decrypt"
      actions = ["kms:Decrypt"]
      principals = {
        type        = "AWS"
        identifiers = ["*"]
      }
      resources = [module.s3_logs.s3_bucket_arn]
      condition = {
        test     = "Null"
        variable = "kms:EncryptionContext:aws:cloudtrail:arn"
        values   = ["false"]
      }
    }
  }

  tags = {
    Name = "CloudTrail"
  }
}

module "cloudwatch_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.0.0"

  aliases                            = ["cloudwatch"]
  bypass_policy_lockout_safety_check = false
  create                             = true
  deletion_window_in_days            = 7
  description                        = "Encrypt and decrypt data for cloudwatch"
  enable_default_policy              = true
  enable_key_rotation                = true
  is_enabled                         = true
  key_administrators                 = [local.role_to_assume] # Needs to change to the specific need-to-know roles
  key_owners                         = [local.role_to_assume]
  key_usage                          = "ENCRYPT_DECRYPT"
  rotation_period_in_days            = 90

  key_statements = {
    statement = {
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
      principals = {
        type        = "Service",
        identifiers = ["logs.${local.aws_region}.amazonaws.com"]
      }
    }
  }

  tags = {
    Name = "CloudWatch"
  }
}

module "ebs_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.0.0"

  aliases                            = ["ebs"]
  bypass_policy_lockout_safety_check = false
  create                             = true
  deletion_window_in_days            = 7
  description                        = "Encrypt and decrypt data for EBS"
  enable_default_policy              = true
  enable_key_rotation                = true
  is_enabled                         = true
  key_administrators                 = [local.role_to_assume] # Needs to change to the specific need-to-know roles
  key_owners                         = [local.role_to_assume]
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

  aliases                            = ["s3"]
  bypass_policy_lockout_safety_check = false
  create                             = true
  deletion_window_in_days            = 7
  description                        = "Encrypt and decrypt data for S3"
  enable_default_policy              = true
  enable_key_rotation                = true
  is_enabled                         = true
  key_administrators                 = [local.role_to_assume] # Needs to change to the specific need-to-know roles
  key_owners                         = [local.role_to_assume]
  key_service_users                  = ["*"]
  key_usage                          = "ENCRYPT_DECRYPT"
  key_users                          = ["*"]
  rotation_period_in_days            = 90

  tags = {
    Name = "S3"
  }
}

module "secretsmanager_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.0.0"

  aliases                            = ["secretsmanager"]
  bypass_policy_lockout_safety_check = false
  create                             = true
  deletion_window_in_days            = 7
  description                        = "Encrypt and decrypt data for Secrets Manager"
  enable_default_policy              = true
  enable_key_rotation                = true
  is_enabled                         = true
  key_administrators                 = [local.role_to_assume] # Needs to change to the specific need-to-know roles
  key_owners                         = [local.role_to_assume]
  key_usage                          = "ENCRYPT_DECRYPT"
  key_users                          = ["*"]
  rotation_period_in_days            = 90

  tags = {
    Name = "SecretsManager"
  }
}

module "ssm_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.0.0"

  aliases                            = ["ssm"]
  bypass_policy_lockout_safety_check = false
  create                             = true
  deletion_window_in_days            = 7
  description                        = "Encrypt and decrypt data for SSM"
  enable_default_policy              = true
  enable_key_rotation                = true
  is_enabled                         = true
  key_administrators                 = [local.role_to_assume] # Needs to change to the specific need-to-know roles
  key_owners                         = [local.role_to_assume]
  key_service_users                  = ["*"]
  key_usage                          = "ENCRYPT_DECRYPT"
  key_users                          = ["*"]
  rotation_period_in_days            = 90

  tags = {
    Name = "SSM"
  }
}