terraform {
  backend "s3" {
    bucket = "eritheus-terraform-state"
    key    = "terraform-app"
    region = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
}
