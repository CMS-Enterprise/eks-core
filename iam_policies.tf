resource "aws_iam_policy" "vpc" {
  name   = "vpc-flow-logs"
  path   = "/delegatedadmin/developer/"
  policy = data.aws_iam_policy_document.vpc.json
}

data "aws_iam_policy_document" "ebs-csi-driver" {
  statement {
    sid    = "AllowEKS"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type        = "Federated"
      identifiers = ["arn:${data.aws_caller_identity.current.provider}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks.cluster_oidc_issuer_url}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${module.eks.cluster_oidc_issuer_url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
    condition {
      test     = "StringEquals"
      variable = "${module.eks.cluster_oidc_issuer_url}:aud"
      values   = ["sts.amazonaws.com"]
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

data "aws_iam_policy_document" "fluent-bit" {
  statement {
    sid    = "Fluentbit Cloudwatch"
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
    sid     = "Fluentbit SSM"
    effect  = "Allow"
    actions = ["ssm:GetParameter"]
    resources = [
      "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
    ]
  }
}


