{ config, pkgs, lib, machine, ... }:
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

    networking.firewall.enable = true;
    networking.firewall.allowedTCPPortRanges = [{ from = 0; to = 65535; }];
    networking.firewall.allowedUDPPortRanges = [{ from = 0; to = 65535; }];

    networking.useDHCP = false;
    networking.dhcpcd.enable = false;

    # todo: move this to `components.hetzner.network`
    systemd.network.enable = true;
    systemd.network.networks."10-private-hetzner" = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "ipv4";
      routes = [
        # create default routes for IPv4
        { routeConfig.Gateway = machine.default_gateway; }
      ];
      #
      dns = [
        # todo find out if this works
        #"8.8.8.8"
        #"1.1.1.1"
        machine.nameserver
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
