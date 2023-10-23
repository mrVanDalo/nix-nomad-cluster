{ config, pkgs, lib, ... }:
with lib;
with types;
{
  options.components.monitoring.netdata = {
    enable = mkOption {
      type = bool;
      default = config.components.monitoring.enable;
    };
  };

  config = mkIf config.components.monitoring.netdata.enable {

    networking.firewall.allowedTCPPorts = [ 19999 ];

    services.netdata = {
      enable = lib.mkDefault true;
      # https://docs.netdata.cloud/daemon/config/
      config = {
        global = {
          "memory mode" = "ram";
        };
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "netdata.*" = {
          locations."/" = {
            proxyWebsockets = true;
            recommendedProxySettings = true;
            proxyPass = "http://localhost:19999";
          };
        };
      };
    };

  };
}
