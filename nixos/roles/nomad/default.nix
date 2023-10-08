{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    ./disk-config.nix

    ./nomad.nix
  ];

  networking.hostName = lib.mkDefault "nomad";

  system.stateVersion = "23.11";

}
