
#resource "hcloud_server" "cache" {
#  name        = "${local.environment_short}-cache"
#  image       = "debian-11"
#  server_type = "cpx11"
#  ssh_keys    = [var.main_key]
#  network {
#    network_id = var.main_network
#  }
#  public_net {
#    ipv4_enabled = false
#    ipv6_enabled = false
#  }
#  labels = {
#    role        = "cache"
#    environment = var.environment
#    cost        = 5.18 + 10.47 # cpx11 + volume
#  }
#  user_data = <<EOH
##cloud-config
#runcmd:
#  - ip route add default via ${var.default_gateway}
#  - echo nameserver 8.8.8.8 > /etc/resolv.conf
#EOH
#  lifecycle {
#    ignore_changes = [network]
#  }
#}


#module "cache_host_file" {
#  source           = "../../../modules/host_file"
#  host             = hcloud_server.cache
#  to_relative_path = local.path_relative_to_include
#  to_repo_path     = local.get_path_to_repo_root
#  volumes          = [hcloud_volume.cache]
#  default_gateway  = var.default_gateway
#  nameserver       = var.nameserver
#  cidr             = var.cidr
#}

module "cache" {
  source                = "../../../modules/hetzner_server"
  name                  = "${local.environment_short}-cache"
  cost                  = 5.18 + 10.47 #
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
