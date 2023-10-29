# Remote state managed by Terraform so Terragrunt can use it

provider "aws" {
  region  = "us-east-1"
  profile = "base"
}