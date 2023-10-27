include "root" {
  path = find_in_parent_folders()
}

dependency "keys" {
  config_path = "../../core/keys"
}
dependency "network" {
  config_path = "../../core/network"
}
generate "dependencies" {
  path      = "_generated_dependency_inputs.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "main_key" {}
variable "main_network" {}
variable "nameserver" {}
variable "default_gateway" {}
EOF
}

inputs = {
  main_key        = dependency.keys.outputs.main_key
  main_network    = dependency.network.outputs.main_network
  nameserver      = dependency.network.outputs.nameserver
  default_gateway = dependency.network.outputs.default_gateway
  environment     = "development"
}
