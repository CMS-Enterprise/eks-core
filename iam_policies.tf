resource "aws_iam_policy" "aws_node_termination_handler" {
  name   = "${local.node_termination_handler_name}-policy"
  policy = data.aws_iam_policy_document.aws_node_termination_handler.json
}

resource "aws_iam_policy" "vpc" {
  name   = "vpc-flow-logs"
  policy = data.aws_iam_policy_document.vpc.json
}

data "aws_iam_policy_document" "aws_node_termination_handler" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeTags",
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage"
    ]
    resources = [module.aws_node_termination_handler_sqs.queue_arn]
  }
}

data "aws_iam_policy_document" "aws_node_termination_handler_sqs" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:${local.aws_region}:${data.aws_caller_identity.current.account_id}:${local.node_termination_handler_name}"]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sqs.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "ebs-csi-driver" {
  statement {
    sid = "AllowEKS"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks.cluster_oidc_issuer_url}"]
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
