resource "aws_iam_role" "fluentbit" {
  name                 = "${var.eks_cluster_name}-fluentbit"
  path                 = var.iam_path
  permissions_boundary = var.iam_permissions_boundary_arn
  assume_role_policy   = data.aws_iam_policy_document.fluentbit_trust.json
}

resource "aws_iam_role_policy_attachment" "fluentbit" {
  role       = aws_iam_role.fluentbit.name
  policy_arn = "arn:${var.aws_partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

data "aws_iam_policy_document" "fluentbit_trust" {
  statement {
    sid     = "AllowEKSForFluentbit"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.eks_oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:${local.fluentbit_namespace}:${local.fluentbit_service_account_name}"]
      variable = "${var.eks_oidc_provider}:sub"
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "${var.eks_oidc_provider}:aud"
    }
  }
}