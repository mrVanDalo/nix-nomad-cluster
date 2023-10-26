locals {
  consul_server_count = 1
}
resource "hcloud_server" "consul" {
  count       = local.consul_server_count
  name        = "${local.environment_short}-consul-${count.index}"
  image       = "debian-11"
  server_type = "cpx11"
  ssh_keys    = [var.main_key]
  network {
    network_id = var.main_network
  }
  labels = {
    role        = "consul"
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
  - ip route add default via 10.0.0.1
  - echo nameserver 8.8.8.8 > /etc/resolv.conf
EOH
  lifecycle {
    ignore_changes = [network]
  }
}

module "consul_host_file" {
  count            = local.consul_server_count
  source           = "../../../modules/host_file"
  host             = hcloud_server.consul[count.index]
  to_relative_path = local.path_relative_to_include
  to_repo_path     = local.get_path_to_repo_root
  volumes          = []
  default_gateway  = "10.0.0.1"
}
