data "aws_iam_policy_document" "cloudtrail_kms" {
  statement {
    sid       = "Allow all kms access to terraform role"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [local.role_to_assume]
    }
  }
  statement {
    sid     = "Enable CloudTrail Permissions"
    actions = ["kms:GenerateDataKey*", "kms:DescribeKey"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = [
        "arn:aws:cloudtrail:${local.aws_region}:${data.aws_caller_identity.current.account_id}:trail/*"
      ]
    }
  }
  statement {
    sid     = "Enable users to decrypt"
    actions = ["kms:Decrypt"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [module.s3_logs.s3_bucket_arn]
    condition {
      test     = "Null"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_kms" {
  statement {
    sid       = "Allow all kms access to terraform role"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [local.role_to_assume]
    }
  }
  statement {
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    principals {
      type        = "Service"
      identifiers = ["logs.${local.aws_region}.amazonaws.com"]
    }
    resources = ["*"]
  }
  statement {
    actions = [
      "kms:Decrypt*"
    ]
    principals {
      type        = "Service"
      identifiers = ["glue.${local.aws_region}.amazonaws.com"]
    }
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ebs_kms" {
  statement {
    sid       = "Allow all kms access to terraform role"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [local.role_to_assume]
    }
  }
  statement {
    sid = "Allow use of the key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "s3" {
  statement {
    sid       = "Allow all kms access to admins"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [local.role_to_assume]
    }
  }
  statement {
    sid = "Allow use of the key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
  }
  statement {
    sid = "Allow attachment of the resources"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["false"]
    }
  }
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ssm_kms" {
  statement {
    sid       = "Allow all kms access to admins"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [local.role_to_assume]
    }
  }
  statement {
    sid = "Allow use of the key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
  }
  statement {
    sid = "Allow attachment of the resources"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "sqs_kms" {
  statement {
    sid       = "Allow all kms access to admins"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [local.role_to_assume]
    }
  }
  statement {
    sid = "Allow use of the key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
  }
  statement {
    sid = "Allow attachment of the resources"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["false"]
    }
  }
  statement {
    actions = [
      "kms:Decrypt*"
    ]
    principals {
      type        = "Service"
      identifiers = ["glue.${local.aws_region}.amazonaws.com"]
    }
    resources = ["*"]
  }
}
