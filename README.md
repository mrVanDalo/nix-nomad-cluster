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

# update gateway
nix run .#apps.apply.core_network_cor-net-gateway

# set up monitor system
nix run .#apps.init.development_core_dev-monitor
```

## Troubleshooting

- disable DNSSEC if `*.apps.cluster` not working.

Now you can `init` all the other machines.

# Todos

- find a nice way to run init in parallel
  - something like `parallel screen -md nix run .#apps.init.{1} ::: development_....`
  - make sure new ssh keys properly handled
- ssh host key management is a bit annoying at the moment
- add ./user to manage users, public ssh keys, gpg keys and other types of information
- make ./machines a flake (optional)
- set up openvpn and including dns configuration against unbound
- nomad and vault don't restart after `nix flake update`
- deploy jaeger ui in nomad cluster
- install opentelemetry-collector in monitoring instance
- integrate [systemd-vault](https://github.com/numtide/systemd-vaultd) for secret management
  - unlock vault initially by WebUI
  - Dependencies are than :
    - gateway <- vault <- consul <- nomad / everything nixos managed
- Encrypt disks by default
  - How to unlock disks? TPM?
- Use TPM https://www.freedesktop.org/software/systemd/man/latest/systemd-cryptenroll.html to unlook vault eventually.
- Adjust Blocksize of nix-store on cache instance to improve spead
- use role/<name>/configuration.nix to include the disko-configuration and the default to configure everything not hardware related.
- properly configure DNSSEC

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
