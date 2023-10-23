{ config, pkgs, lib, ... }:
with lib;
with types;
{
  options.components.monitoring.telegraf = {
    enable = mkOption {
      type = bool;
      default = config.components.monitoring.enable;
    };
  };

  config = mkIf config.components.monitoring.telegraf.enable {

    # open ports for to collect metrics
    networking.firewall.allowedTCPPorts = [ 9273 ];

    services.telegraf = {
      enable = lib.mkDefault true;
      extraConfig = {
        outputs.prometheus_client = {
          listen = ":9273";
          metric_version = 2;
        };
        # https://github.com/influxdata/telegraf/tree/master/plugins/inputs < all them plugins
        inputs = {
          cpu = { };
          disk = { };
          diskio = { };
          processes = { };
          system = { };
          systemd_units = { };
        };
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "telegraf.*" = {
          locations."/" = {
            proxyWebsockets = true;
            recommendedProxySettings = true;
            proxyPass = "http://localhost:9273";
          };
        };
      };
    };

  };
}
