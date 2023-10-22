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

    networking.firewall.enable = false;
    networking.useDHCP = false;
    networking.dhcpcd.enable = false;

    # todo: move this to `components.hetzner.network`
    systemd.network.enable = true;
    systemd.network.networks."10-private-hetzner" = {
      matchConfig.Name = "ens*";
      networkConfig.DHCP = "ipv4";
      routes = [
        # create default routes for IPv4
        { routeConfig.Gateway = machine.default_gateway; }
      ];
      dns = [
        "8.8.8.8"
        "1.1.1.1"
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
