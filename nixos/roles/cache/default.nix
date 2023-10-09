{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    ./disk-config.nix

    ./cache.nix
    #./proxy.nix
    ./proxy2.nix
  ];

  networking.hostName = lib.mkDefault "cache";

  system.stateVersion = "23.11";

}
