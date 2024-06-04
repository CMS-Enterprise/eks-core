resource "aws_s3_bucket_ownership_controls" "terraform" {
  bucket = data.aws_s3_bucket.terraform.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_logging" "terraform" {
  bucket        = data.aws_s3_bucket.terraform.id
  target_bucket = module.s3_logs.s3_bucket_id
  target_prefix = "terraform/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform" {
  bucket = data.aws_s3_bucket.terraform.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = module.s3_kms.key_id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "terraform" {
  bucket = data.aws_s3_bucket.terraform.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "terraform" {
  bucket = local.terraform_bucket_name

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "AllowSSLRequestsOnly",
        Effect : "Deny",
        Principal : "*"
        Action : "s3:*"
        Resource : [
          "${data.aws_s3_bucket.terraform.arn}/*",
          data.aws_s3_bucket.terraform.arn
        ]
        Condition : {
          Bool : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  })
}