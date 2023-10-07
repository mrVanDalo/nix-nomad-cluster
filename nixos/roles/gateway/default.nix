{ modulesPath, config, lib, pkgs, ... }:
{
  imports = [
    ./disk-config.nix
  ];

  networking.hostName = lib.mkDefault "gateway";

  # gateway
  components.network.hetzner.enable = false;
  networking.nat = {
    enable = true;
    internalIPs = [ "10.0.0.0/24" ];
  };

  system.stateVersion = "23.11";
}
