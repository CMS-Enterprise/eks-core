resource "aws_kms_key" "cloudwatch" {
  description         = "Encrypt and decrypt data for cloudwatch"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.cloudwatch_kms.json

  tags = {
    Name = "CloudWatch"
  }
}

resource "aws_kms_key" "cloudtrail" {
  description         = "Encrypt and decrypt data for cloudtrail"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.cloudtrail_kms.json

  tags = {
    Name = "Cloudtrail"
  }
}

resource "aws_kms_key" "ebs" {
  description         = "Encrypt and decrypt data for EBS"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.ebs_kms.json
  tags = {
    Name = "EBS"
  }
}

resource "aws_kms_key" "ecr" {
  description         = "Encrypt and decrypt data for ECR"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.ecr_kms.json

  tags = {
    Name = "ECR"
  }
}

resource "aws_kms_key" "s3" {
  description         = "Encrypt and decrypt data for S3"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.s3.json

  tags = {
    Name = "S3"
  }
}

resource "aws_kms_key" "ssm" {
  description         = "Encrypt and decrypt data for SSM"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.ssm_kms.json

  tags = {
    Name = "SSM"
  }
}

resource "aws_kms_key" "sqs" {
  description         = "Encrypt and decrypt data for SQS"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.sqs_kms.json

  tags = {
    Name = "SQS"
  }
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/cloudtrail"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/cloudwatch"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/ecr"
  target_key_id = aws_kms_key.ecr.key_id
}

resource "aws_kms_alias" "s3" {
  name          = "alias/s3"
  target_key_id = aws_kms_key.s3.key_id
}

resource "aws_kms_alias" "ssm" {
  name          = "alias/ssm"
  target_key_id = aws_kms_key.ssm.key_id
}

resource "aws_kms_alias" "sqs" {
  name          = "alias/sqs"
  target_key_id = aws_kms_key.sqs.key_id
}