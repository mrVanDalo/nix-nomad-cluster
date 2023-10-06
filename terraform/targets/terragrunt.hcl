
# Indicate what region to deploy the resources into
generate "provider" {
  path      = "_generated_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.44.1"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}
EOF
}

generate "meta" {
  path      = "_generated_meta.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# terragrunt functions
locals {
  path_relative_to_include   = "${path_relative_to_include()}"
  path_relative_from_include = "${path_relative_from_include()}"
  get_repo_root              = "${get_repo_root()}"
  get_path_to_repo_root      = "${get_path_to_repo_root()}"
  get_path_from_repo_root    = "${get_path_from_repo_root()}"
}
EOF
}



#remote_state {
#  backend = "s3"
#  generate = {
#    path      = "_generated_backend.tf"
#    if_exists = "overwrite"
#  }
#  config = {
#    key                          = "${path_relative_to_include()}/terraform.tfstate"
#    bucket                       = "nixos-cluster-terraform-states"
#    region                       = "home"
#    endpoint                     = "http://chungus.private:9000/"
#    skip_requesting_account_id   = true
#    skip_credentials_validation  = true
#    skip_get_ec2_platforms       = true
#    skip_metadata_api_check      = true
#    skip_region_validation       = true
#    disable_aws_client_checksums = true
#    skip_bucket_ssencryption     = true
#    skip_bucket_accesslogging    = true
#    skip_bucket_root_access      = true
#    force_path_style             = true
#  }
#}

inputs = {
  hcloud_token = run_cmd("--terragrunt-quiet", "pass", "development/hetzner.com/api-token")
}
