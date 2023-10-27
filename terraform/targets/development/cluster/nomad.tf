locals {
  nomad_server_count = 3
}
resource "hcloud_server" "nomad" {
  count       = local.nomad_server_count
  name        = "${local.environment_short}-nomad-${count.index}"
  image       = "debian-11"
  server_type = "cpx11"
  ssh_keys    = [var.main_key]
  network {
    network_id = var.main_network
  }
  labels = {
    role        = "nomad"
    environment = var.environment
    cost        = 5.18 # cpx11
  }
  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
  user_data = <<EOH
#cloud-config
runcmd:
  - ip route add default via ${var.default_gateway}
  - echo nameserver 8.8.8.8 > /etc/resolv.conf
EOH
  lifecycle {
    ignore_changes = [network]
  }
}

module "nomad_host_file" {
  count            = local.nomad_server_count
  source           = "../../../modules/host_file"
  host             = hcloud_server.nomad[count.index]
  to_relative_path = local.path_relative_to_include
  to_repo_path     = local.get_path_to_repo_root
  volumes          = []
  default_gateway  = var.default_gateway
  cidr             = var.cidr
  nameserver       = var.nameserver
}
