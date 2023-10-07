locals {
  vault_server_count = 1
}
resource "hcloud_server" "vault" {
  count       = local.vault_server_count
  name        = "${var.environment}-core-vault-${count.index}"
  image       = "debian-11"
  server_type = "cx11"
  ssh_keys    = [var.main_key]
  network {
    network_id = var.main_network
  }
  labels = {
    role = "vault"
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

module "vault_host_file" {
  count            = local.vault_server_count
  source           = "../../../modules/host_file"
  host             = hcloud_server.vault[count.index]
  to_relative_path = local.path_relative_to_include
  to_repo_path     = local.get_path_to_repo_root
  volumes          = []
}