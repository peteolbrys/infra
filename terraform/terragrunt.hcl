# Base configuation for state
locals {
  # Auto-load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  aws_profile  = local.account_vars.locals.aws_profile_name
}

terraform {
  extra_arguments "aws_profile" {
    env_vars = {
      AWS_PROFILE = "${local.aws_profile}"
    }
  }
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket = "terraform-state"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = "us-east-1"

    encrypt = true
    dynamodb_table = "terraform-state-lock"

    profile = "${local.aws_profile}"
  }
}
