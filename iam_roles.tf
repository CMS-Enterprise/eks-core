resource "aws_iam_role" "vpc" {
  name                 = "${local.cluster_name}-vpc-flow-logs"
  path                 = local.iam_path
  permissions_boundary = local.permissions_boundary_arn

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : "vpc-flow-logs.amazonaws.com"
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })

  tags = local.tags_for_all_resources
}

resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.vpc.name
  policy_arn = aws_iam_policy.vpc.arn
}
