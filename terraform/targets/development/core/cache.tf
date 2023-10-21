
resource "hcloud_server" "cache" {
  name        = "${local.environment_short}-cache"
  image       = "debian-11"
  server_type = "cx21"
  ssh_keys    = [var.main_key]
  network {
    network_id = var.main_network
  }
  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
  labels = {
    role        = "cache"
    environment = var.environment
  }
  user_data = <<EOH
#cloud-config
runcmd:
  - ip route add default via 10.0.0.1
  - echo nameserver 8.8.8.8 > /etc/resolv.conf
EOH
  lifecycle {
    ignore_changes = [network]
  }
}

resource "hcloud_volume" "cache" {
  name      = hcloud_server.cache.name
  size      = 200
  server_id = hcloud_server.cache.id
  automount = true
  format    = "ext4"
}

module "cache_host_file" {
  source           = "../../../modules/host_file"
  host             = hcloud_server.cache
  to_relative_path = local.path_relative_to_include
  to_repo_path     = local.get_path_to_repo_root
  volumes          = [hcloud_volume.cache]
  default_gateway  = "10.0.0.1"
}
