{ config, pkgs, lib, ... }:
with lib;
with types;
{
  options.components.network.hetzner = {
    enable = mkOption {
      type = bool;
      description = "configure private network setup in hetzner machines";
      default = config.components.network.enable;
    };
  };

  config = mkIf config.components.network.hetzner.enable {

    networking.nameservers = [
      "8.8.8.8"
      "1.1.1.1"
    ];

    # todo: move this to `components.hetzner.network`
    networking.defaultGateway = "10.0.0.1";

    systemd.network.enable = true;
    systemd.network.networks."10-private-hetzner" = {
      matchConfig.Name = "*";
      networkConfig.DHCP = "ipv4";
      routes = [
        # create default routes for IPv4
        { routeConfig.Gateway = "10.0.0.1"; }
      ];
      # make the routes on this interface a dependency for network-online.target
      linkConfig.RequiredForOnline = "routable";
    };


    # todo: move this to `components.hetzner.boot`
    boot.loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };

  };
}
