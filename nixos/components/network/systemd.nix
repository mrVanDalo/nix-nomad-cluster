{ config, pkgs, lib, ... }:
with lib;
with types;
{
  options.components.network.systemd = {
    enable = mkOption {
      type = bool;
      default = config.components.network.enable;
    };
  };

  config = mkIf config.components.network.systemd.enable {

    systemd.network.enable = true;
    systemd.network.networks."10-wan" = {
      matchConfig.Name = "ens3"; # either ens3 (amd64) or enp1s0 (arm64)
      networkConfig.DHCP = "ipv4";
      routes = [
        { routeConfig.Gateway = "10.0.0.1"; }
      ];
    };

  };
}
