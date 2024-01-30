terraform {
  required_version = ">= 1.6.0"

  backend "s3" {}

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "5.20.0"
      configuration_aliases = [aws.alternate]
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "eu-central-1"
  region = "eu-central-1"

  default_tags {
    tags = merge(
      var.tags,
      {
        "awsApplication" = aws_servicecatalog_application.myapplication.applicationTag
    })
  }

}

locals {
  project = format("%s-%s", var.app_name, var.env_short)
}

data "aws_caller_identity" "current" {}

resource "aws_servicecatalog_application" "myapplication" {
  name = local.project
}
