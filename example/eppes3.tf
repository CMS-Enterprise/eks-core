module eppe_s3 {
    source  = "git@github.com:CMS-Enterprise/batcave-tf-buckets.git//.?ref=0.5.0"
    s3_bucket_names = [
    "${var.cluster_name}-splunk",
  ]
    force_destroy = true
    sse_algorithm = "AES256"
    tags = {
    cluster_name   = var.cluster_name
    project-number = var.cluster_project
    Environment    = var.cluster_env
  }

    
}