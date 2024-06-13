resource "aws_iam_policy" "vpc" {
  name   = "${local.cluster_name}-vpc-flow-logs"
  path   = local.iam_path
  policy = data.aws_iam_policy_document.vpc.json
}

data "aws_iam_policy_document" "vpc" {
  statement {
    sid    = "VPCFlowLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
  statement {
    sid     = "VPCFlowLogsS3"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${module.s3_logs.s3_bucket_arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "fluent-bit" {
  statement {
    sid    = "fluentbitCloudwatch"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:putRetentionPolicy"
    ]
    resources = ["*"]
  }
  statement {
    sid     = "fluentbitSSM"
    effect  = "Allow"
    actions = ["ssm:GetParameter"]
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:*:*:parameter/AmazonCloudWatch-*"
    ]
  }
}


