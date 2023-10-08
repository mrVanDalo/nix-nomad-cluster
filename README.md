## Buzzwords

- Hetzner
  - Other provider possible, just create them in terraform folder
- NixOS store
- Private network
- Nomad
- Vault
- Consul
- monitoring
  - loki
  - prometheus
  - thanos

## How to set up whole infra

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

# Todos

- find a nice way to run init in parallel
  - something like `parallel screen -md nix run .#apps.init.{1} ::: development_....`
  - make sure new ssh keys properly handled
- make cache dynamic => it takes forever if the wrong cache is used.
