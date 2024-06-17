resource "aws_iam_policy" "vpc" {
  name   = "${local.cluster_name}-vpc-flow-logs"
  path   = local.iam_path
  policy = data.aws_iam_policy_document.vpc.json
}

data "aws_iam_policy_document" "fluentbit_trust" {
  statement {
    sid     = "AllowEKSForFluentbit"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:${local.fluentbit_namespace}:${local.fluentbit_service_account_name}"]
      variable = "${module.eks.oidc_provider}:sub"
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "${module.eks.oidc_provider}:aud"
    }
  }
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


