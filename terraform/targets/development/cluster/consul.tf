locals {
  consul_server_count = 1
}

module "consul" {
  count                 = local.consul_server_count
  source                = "../../../modules/hetzner_server"
  name                  = "${local.environment_short}-consul-${count.index}"
  cost                  = 5.18
  server_type           = "cpx11"
  default_gateway       = var.default_gateway
  environment           = var.environment
  nameserver            = var.nameserver
  network_id            = var.main_network
  role                  = "consul"
  ssh_keys              = [var.main_key]
  get_path_to_repo_root = local.get_path_to_repo_root
  to_relative_path      = local.path_relative_to_include
}
