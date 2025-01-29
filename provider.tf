provider "aws" {
  access_key = "${var.AWS_ACCESS_KEY_ID}"
  secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
  region = "us-east-1"
}
/*
provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "terraform-user"
}
*/