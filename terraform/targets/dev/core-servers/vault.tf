locals {
  vault_server_count = 3
}
resource "hcloud_server" "vault" {
  count       = local.vault_server_count
  name        = "vault-${count.index}"
  image       = "debian-11"
  server_type = "cx41"
  network {
    network_id = var.main_network
  }
  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
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
