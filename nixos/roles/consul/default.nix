{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    ./disk-config.nix

    ./consul.nix
  ];

  networking.hostName = lib.mkDefault "consul";

  system.stateVersion = "23.11";

}
