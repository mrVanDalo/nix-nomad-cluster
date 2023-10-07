{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    ./disk-config.nix
  ];

  networking.hostName = lib.mkDefault "vault";

  system.stateVersion = "23.11";

}
