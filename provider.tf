terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.4.6"
}

/*
provider "aws" {
  access_key = "${var.AWS_ACCESS_KEY_ID}"
  secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
  region = "us-east-1"
}
*/
provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "terraform-user"
}