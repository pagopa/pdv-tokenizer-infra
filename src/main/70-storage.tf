locals {
  openapidocs_bucket_name = format("%sapidocs", var.app_name)
}


# S3 bucket for website.
resource "aws_s3_bucket" "openapidocs" {
  bucket = local.openapidocs_bucket_name
  acl    = "public-read"
  policy = templatefile("./templates/s3_policy.tpl.json", {
    bucket_name = local.openapidocs_bucket_name
    account_id  = data.aws_caller_identity.current.id
  })

  /*
  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET", ]
    allowed_origins = []
    max_age_seconds = 3000
  }
  */

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

}