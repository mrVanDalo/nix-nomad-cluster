terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.44.1"
    }
  }
}

#locals {
#  costs_raw = jsondecode(file("${path.module}/pricing.json"))
#}
variable "server_type" {
  default = "cpx11"
}
variable "ssh_keys" {
  type = list(string)
}
variable "network_id" {}
variable "environment" {}
variable "role" {}
variable "default_gateway" {}
variable "name" {}
variable "cost" {}
variable "to_relative_path" {}
variable "get_path_to_repo_root" {}
variable "nameserver" {}


resource "hcloud_server" "this" {
  name        = var.name
  image       = "debian-11"
  server_type = var.server_type
  ssh_keys    = var.ssh_keys
  network {
    network_id = var.network_id
  }
  labels = {
    role        = var.role
    environment = var.environment
    cost        = var.cost
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

output "server_id" {
  value = hcloud_server.this.id
}

output "server_name" {
  value = hcloud_server.this.name
}

data "hcloud_network" "network" {
  id = var.network_id
}

module "gateway_host_file" {
  source           = "../host_file"
  host             = hcloud_server.this
  to_relative_path = var.to_relative_path
  to_repo_path     = var.get_path_to_repo_root
  default_gateway  = var.default_gateway
  nameserver       = var.nameserver
  cidr             = data.hcloud_network.network.ip_range
}
