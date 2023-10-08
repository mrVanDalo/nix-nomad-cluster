{ config, lib, pkgs, machines, ... }:
{
  imports = [
    ./disk-config.nix
    ./gateway.nix
  ];

  networking.hostName = lib.mkDefault "gateway";

  system.stateVersion = "23.11";
}
