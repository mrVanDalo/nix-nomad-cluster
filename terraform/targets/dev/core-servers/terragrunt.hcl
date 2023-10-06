include "root" {
  path = find_in_parent_folders()
}

dependency "keys" {
  config_path = "../keys"
}
dependency "network" {
  config_path = "../network"
}
generate "dependencies" {
  path      = "_generated_dependency_inputs.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "main_key" {}
variable "main_network" {}
EOF
}

inputs = {
  main_key     = dependency.keys.outputs.main_key
  main_network = dependency.network.outputs.main_network
}