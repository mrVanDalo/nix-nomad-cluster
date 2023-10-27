
module "cache" {
  source                = "../../../modules/hetzner_server"
  name                  = "${local.environment_short}-cache"
  cost                  = 5.18 + 10.47
  server_type           = "cpx11"
  default_gateway       = var.default_gateway
  environment           = var.environment
  nameserver            = var.nameserver
  network_id            = var.main_network
  role                  = "cache"
  ssh_keys              = [var.main_key]
  get_path_to_repo_root = local.get_path_to_repo_root
  to_relative_path      = local.path_relative_to_include
}

resource "hcloud_volume" "cache" {
  name      = module.cache.server_name
  size      = 200
  server_id = module.cache.server_id
  automount = true
  format    = "ext4"
}
