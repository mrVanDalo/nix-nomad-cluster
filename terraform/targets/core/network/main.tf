locals {
  main_cidr  = "10.220.230.0/24"
  nat_ip     = cidrhost(local.main_cidr, 3)
  gateway_ip = cidrhost(local.main_cidr, 1)
}

# create network
# --------------
resource "hcloud_network" "network" {
  name     = "${local.environment_short}_network_eu"
  ip_range = local.main_cidr
}

output "main_network" {
  value = hcloud_network.network.id
}

output "nameserver_ip" {
  value = local.nat_ip
}

resource "hcloud_network_subnet" "availability_network" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = local.main_cidr
}

# create gateway
# --------------
resource "hcloud_network_route" "nat_gateway" {
  network_id  = hcloud_network.network.id
  destination = "0.0.0.0/0"
  gateway     = local.nat_ip
}

resource "hcloud_server" "nat_gateway" {
  name        = "${local.environment_short}-net-gateway"
  image       = "debian-11"
  server_type = "cpx11"
  ssh_keys    = [var.main_key]
  network {
    network_id = hcloud_network.network.id
    ip         = local.nat_ip
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  labels = {
    role        = "gateway"
    environment = var.environment
    cost        = 5.18 # cpx11
  }
  lifecycle {
    ignore_changes = [network]
  }
  depends_on = [hcloud_network_subnet.availability_network]
}

module "gateway_host_file" {
  source           = "../../../modules/host_file"
  host             = hcloud_server.nat_gateway
  to_relative_path = local.path_relative_to_include
  to_repo_path     = local.get_path_to_repo_root
  default_gateway  = local.gateway_ip
  nameserver       = local.nat_ip
}