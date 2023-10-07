locals {
  #networks = ["eu-central", "us-east", "us-west"]
  networks = ["eu-central"]
  ip_range = "10.0.0.0/8"
}

# create network
# --------------
resource "hcloud_network" "network" {
  count    = length(local.networks)
  name     = "${local.environment_short}_network_${substr(local.networks[count.index], 0, 4)}"
  ip_range = cidrsubnet(local.ip_range, 12, count.index)
}

output "main_network" {
  value = hcloud_network.network[0].id
}

resource "hcloud_network_subnet" "availability_network" {
  count        = length(local.networks)
  network_id   = hcloud_network.network[count.index].id
  type         = "cloud"
  network_zone = local.networks[count.index]
  ip_range     = cidrsubnet(local.ip_range, 12, count.index)
}

# create gateway
# --------------
resource "hcloud_network_route" "internet-gateway" {
  network_id  = hcloud_network.network[0].id
  destination = "0.0.0.0/0"
  # todo : make variable
  gateway = "10.0.0.2"
}

resource "hcloud_server" "gateway" {
  name        = "${local.environment_short}-net-gateway"
  image       = "debian-11"
  server_type = "cx11"
  ssh_keys    = [var.main_key]
  network {
    network_id = hcloud_network.network[index(local.networks, "eu-central")].id
    # todo : make variable
    ip = "10.0.0.2"
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  labels = {
    role        = "gateway"
    environment = var.environment
  }
  lifecycle {
    ignore_changes = [network]
  }
}

module "gateway_host_file" {
  source           = "../../../modules/host_file"
  host             = hcloud_server.gateway
  to_relative_path = local.path_relative_to_include
  to_repo_path     = local.get_path_to_repo_root
}