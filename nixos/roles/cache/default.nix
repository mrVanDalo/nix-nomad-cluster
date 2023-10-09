{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    ./disk-config.nix

    ./cache.nix
    ./proxy.nix
  ];

  networking.hostName = lib.mkDefault "cache";

  system.stateVersion = "23.11";

}
