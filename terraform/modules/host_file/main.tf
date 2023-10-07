locals {
  id = "${replace(var.to_relative_path, "/", "_")}_${var.host.name}"
}


variable "host" {}
variable "to_repo_path" {}
variable "to_relative_path" {}
variable "default_gateway" {}
variable "volumes" {
  type    = list(object({ name = string, linux_device = string, size = number }))
  default = []
}

# create host_json_file
resource "local_file" "host" {
  filename = "${var.to_repo_path}/machines/${local.id}.json"
  content = jsonencode({
    name            = var.host.name
    id              = local.id
    public_ipv6     = var.host.ipv6_address
    public_ipv4     = var.host.ipv4_address
    private_ipv4    = [for item in var.host.network : item.ip][0]
    tags            = var.host.labels
    role            = var.host.labels.role
    environment     = var.host.labels.environment
    default_gateway = var.default_gateway
    volumes = [for item in var.volumes :
      {
        name   = item.name
        size   = item.size
        device = item.linux_device
      }
    ]
  })
}
