{ modulesPath, config, lib, pkgs, machines, ... }:
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

  environment.etc."machines".text = builtins.toJSON machines;

  system.stateVersion = "23.11";
}
