# Overview

- Hetzner
- NixOS store
- Private network
- Nomad
- Vault
- Consul

# Terraform

- create instances
- create flake.nix config for instances.

# How to set up whole infra

```shell
cd terraform/targets/dev/core
terragrunt run-all init
terragrunt run-all apply
```

```shell
cd <repo-root>
git add .
nix flake show
```

```shell
nix run .#apps.override.dev_network_gateway
```
