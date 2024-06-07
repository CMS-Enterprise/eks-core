resource "aws_iam_role" "ebs_csi_driver" {
  name                 = "ebs-csi-driver-role-${module.eks.cluster_name}"
  permissions_boundary = data.aws_iam_policy.permissions_boundary.arn
  assume_role_policy   = data.aws_iam_policy_document.ebs-csi-driver.json
}

resource "aws_iam_role" "vpc" {
  name                 = "vpc-flow-logs"
  permissions_boundary = data.aws_iam_policy.permissions_boundary.arn

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
}

resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.vpc.name
  policy_arn = aws_iam_policy.vpc.arn
}