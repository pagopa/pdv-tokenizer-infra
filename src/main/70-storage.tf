locals {
  openapidocs_bucket_name = format("%%sapidocs", var.env_short, var.app_name)
}


# S3 bucket for website.
resource "aws_s3_bucket" "openapidocs" {
  bucket = local.openapidocs_bucket_name
}

resource "aws_s3_bucket_acl" "openapidocs" {
  bucket = aws_s3_bucket.openapidocs.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "openapidocs" {
  bucket = aws_s3_bucket.openapidocs.id
  policy = templatefile("./templates/s3_policy.tpl.json", {
    bucket_name = local.openapidocs_bucket_name
    account_id  = data.aws_caller_identity.current.id
  })
}