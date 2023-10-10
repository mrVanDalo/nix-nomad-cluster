{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    ./disk-config.nix

    ./loki.nix
    ./prometheus.nix
    ./thanos.nix
    ./grafana.nix
  ];

  networking.hostName = lib.mkDefault "monitor";

  system.stateVersion = "23.11";

}
