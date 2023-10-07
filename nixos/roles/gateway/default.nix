{ config, lib, pkgs, machines, ... }:
{
  imports = [
    ./disk-config.nix
    ./gateway.nix
  ];

  networking.hostName = lib.mkDefault "gateway";

  environment.etc."machines".text = builtins.toJSON machines;

  system.stateVersion = "23.11";
}
