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
# set up gateway
nix run .#apps.init.core_network_cor-net-gateway
# create ssh tunnel 
nix run .#apps.sshuttle.core_network_cor-net-gateway

# set up cache
nix run .#apps.init.development_core_dev-cache
nix run .#apps.update-cache.development_core_dev-cache
nix run .#apps.build-kexec.development_core_dev-cache

# set up monitor system
nix run .#apps.init.development_core_dev-monitor
```

Now you can `init` all the other machines.

# Todos

- find a nice way to run init in parallel
  - something like `parallel screen -md nix run .#apps.init.{1} ::: development_....`
  - make sure new ssh keys properly handled
- make cache dynamic => it takes forever if the wrong cache is used.
- ssh key management is a bit annoying at the moment

# Goals

- Follow clean and easy way of nixinate
- flake blueprint to create and manage a cluster (nomad, kubernetes, ... )
  - with private cache to speed up deployments on scale
  - with montoring already set up
  - with nat gateway, if not provided by hardware or cloud provider
