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

resource "aws_iam_role" "role" {
  name = "secret_hasan_test"
  path = "/delegatedadmin/developer/"

  permissions_boundary = "arn:aws:iam::111594127594:policy/cms-cloud-admin/ct-ado-poweruser-permissions-boundary-policy"
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::111594127594:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/94473F8E41C46EB15639C5BDE258482B"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-east-1.amazonaws.com/id/94473F8E41C46EB15639C5BDE258482B:aud": "sts.amazonaws.com",
                    "oidc.eks.us-east-1.amazonaws.com/id/94473F8E41C46EB15639C5BDE258482B:sub": [
                        "system:serviceaccount:default:app-test-secret-store-sa"
                    ]
                }
            }
        }
    ]
  })
}


# IAM policy
resource "aws_iam_policy" "policy" {
  name   = "secret_hasan_test"
  path   = "/delegatedadmin/developer/"
  policy = data.aws_iam_policy_document.policy.json
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid = "secretsdriver"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      "arn:aws:secretsmanager:*:*:secret:impl/*", # This configuration enables the service account to only be able to access secrets that prefix with impl/
    ]
    effect = "Allow"
  }
}


# policy attachment
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
  


