locals {
  openapidocs_bucket_name = format("%sapidocs", var.app_name)
}


# S3 bucket for website.
resource "aws_s3_bucket" "openapidocs" {
  bucket = local.openapidocs_bucket_name
  acl    = "private"
  policy = templatefile("./templates/s3_policy.tpl.json", {
    bucket_name = local.openapidocs_bucket_name
    account_id  = data.aws_caller_identity.current.id
  })

}