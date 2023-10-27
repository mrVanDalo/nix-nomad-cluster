#resource "hcloud_server" "monitor" {
#  name        = "${local.environment_short}-monitor"
#  image       = "debian-11"
#  server_type = "cpx11"
#  ssh_keys    = [var.main_key]
#  network {
#    network_id = var.main_network
#  }
#  labels = {
#    role        = "monitor"
#    environment = var.environment
#    cost        = 5.18 # cpx11
#  }
#  public_net {
#    ipv4_enabled = false
#    ipv6_enabled = false
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
#
#module "monitor_host_file" {
#  source           = "../../../modules/host_file"
#  host             = hcloud_server.monitor
#  to_relative_path = local.path_relative_to_include
#  to_repo_path     = local.get_path_to_repo_root
#  volumes          = []
#  default_gateway  = var.default_gateway
#  nameserver       = var.nameserver
#  cidr             = var.cidr
#}

module "monitor" {
  source                = "../../../modules/hetzner_server"
  name                  = "${local.environment_short}-monitor"
  cost                  = 5.18
  server_type           = "cpx11"
  default_gateway       = var.default_gateway
  environment           = var.environment
  nameserver            = var.nameserver
  network_id            = var.main_network
  role                  = "monitor"
  ssh_keys              = [var.main_key]
  get_path_to_repo_root = local.get_path_to_repo_root
  to_relative_path      = local.path_relative_to_include
}
