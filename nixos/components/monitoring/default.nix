{ config, pkgs, lib, ... }:
with lib;
with types;
{
  options.components.monitoring = {
    enable = mkOption {
      type = bool;
      default = true;
    };
  };

  config = mkIf config.components.monitoring.enable {

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

    services.netdata = {
      enable = lib.mkDefault true;
      # https://docs.netdata.cloud/daemon/config/
      config = {
        global = {
          "memory mode" = "ram";
        };
      };
    };

    # open ports for to collect metrics
    networking.firewall.allowedTCPPorts = [ 19999 9273 ];

    # todo : push logs to loki
  };
}
