include "root" {
  path = find_in_parent_folders()
}

dependency "keys" {
  config_path = "../keys"
}
generate "dependencies" {
  path      = "_generated_dependency_inputs.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "main_key" {
  description = "main key to be used"
}
EOF
}

inputs = {
  main_key    = dependency.keys.outputs.main_key
  environment = "core"
}