# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
# terragrunt functions
locals {
  path_relative_to_include   = "core/network"
  path_relative_from_include = "../.."
  get_path_to_repo_root      = "../../../.."
  get_path_from_repo_root    = "terraform/targets/core/network"

  environment_short = substr(var.environment, 0, 3)
}

variable "environment" {}
