{ config, lib, pkgs, machines, ... }:
{
  imports = [
    ./disk-config.nix
    ./gateway.nix
    #./knot.nix
    ./unbound.nix
  ];

  components.network.hetzner.enable = false;
  # make sure fireall is working
  networking.firewall.enable = lib.mkForce true;

  networking.hostName = lib.mkDefault "gateway";

  system.stateVersion = "23.11";
}
