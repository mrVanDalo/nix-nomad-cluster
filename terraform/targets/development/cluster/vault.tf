locals {
  vault_server_count = 1
}

module "vault" {
  count                 = local.vault_server_count
  source                = "../../../modules/hetzner_server"
  name                  = "${local.environment_short}-vault-${count.index}"
  cost                  = 5.18
  server_type           = "cpx11"
  default_gateway       = var.default_gateway
  environment           = var.environment
  nameserver            = var.nameserver
  network_id            = var.main_network
  role                  = "vault"
  ssh_keys              = [var.main_key]
  get_path_to_repo_root = local.get_path_to_repo_root
  to_relative_path      = local.path_relative_to_include
}
