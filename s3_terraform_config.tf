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
      kms_master_key_id = aws_kms_key.s3.id
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

resource "aws_s3_bucket_replication_configuration" "terraform" {
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.terraform]

  role   = aws_iam_role.s3_replication.arn
  bucket = data.aws_s3_bucket.terraform.id

  rule {
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    source_selection_criteria {
      replica_modifications {
        status = "Enabled"
      }
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = module.s3_replication.s3_bucket_arn
      storage_class = "GLACIER_IR"
      encryption_configuration {
        replica_kms_key_id = aws_kms_key.s3_replication.arn
      }
    }
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