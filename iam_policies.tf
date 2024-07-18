resource "aws_iam_policy" "vpc" {
  name   = "${local.cluster_name}-vpc-flow-logs"
  path   = local.iam_path
  policy = data.aws_iam_policy_document.vpc.json

  tags = local.tags_for_all_resources
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
      "${data.aws_s3_bucket.logs.arn}/*"
    ]
  }
}


