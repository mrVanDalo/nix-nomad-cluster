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
- ssh host key management is a bit annoying at the moment
- add ./user to manage users, public ssh keys, gpg keys and other types of information
- make ./machines a flake (optional)
- set up openvpn and including dns configuration against unbound
- make unbound also handle wildcard dns entries (by forwarding to knot for example)
- nomad and vault don't restart after `nix flake update`

# Goals

- Follow clean and easy way of nixinate
- flake blueprint to create and manage a cluster (nomad, kubernetes, ... )
  - with private cache to speed up deployments on scale
  - with montoring already set up
  - with nat gateway, if not provided by hardware or cloud provider

# Features

- Monitoring infrastructure already in place
  - Logs, Metrics, Telemetry

# Pros

- Provider-agnostic: you could even manage "real" machines, by just creating `./machines/<name>.json`
- Using vanilla nixos flake
  - Only terraform and nix language is required to understand the project.
  - DevOP-client-agnostic: they only need nix to be installed. Everything else comes will be shipped, without calling sudo and installing gpg or tls keys in your trust chain.
- Very adaptive to new situations
- No Database for machines is needed, everything can be managed by this git repository (you should use a s3 bucket for terraform though)
- Easy adaptable to CI deployment workflows (the terraform part sadly isn't)

# Cons

- A limited amount of machines can be handled like this (I guess not more than 400)
- Machine-ids could be no-uniq
