terraform {
  required_version = ">= 1.1.5"

  backend "s3" {
    bucket         = "terraform-backend-5480"
    key            = "uat/devops/tfstate"
    region         = "eu-south-1"
    dynamodb_table = "terraform-lock"
    profile        = "ppa-tokenizer-data-vault-uat"
  }

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "= 0.1.8"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63.0"
    }

  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias   = "prod"
  profile = "ppa-tokenizer-data-vault-prod"
  region  = var.aws_region
}