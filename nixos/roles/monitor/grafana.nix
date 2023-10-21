{ machine, config, ... }:
{

  networking.firewall.allowedTCPPorts = [
    config.services.grafana.settings.server.http_port
  ];

  # Open Grafana in browser as default
  services.nginx = {
    enable = true;
    virtualHosts = {
      ${machine.name} = {
        locations."/" = {
          proxyWebsockets = true;
          recommendedProxySettings = true;
          proxyPass = "http://localhost:3000";
        };
      };
    };
  };

  services.grafana = {
    enable = true;
    settings = {

      # darktheme is for trolls :D
      users.default_theme = "light";

      server = {
        # Listening Address
        http_addr = "0.0.0.0";
        # and Port
        http_port = 3000;
        # Grafana needs to know on which domain and URL it's running
        #domain = "your.domain";
        #root_url = "https://your.domain/grafana/"; # Not needed if it is `https://your.domain/`
      };

    };


    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Thanos";
            type = "prometheus";
            uid = "Thanos1";
            url = "http://localhost:10912";
          }
          {
            name = "Loki";
            type = "loki";
            uid = "Loki1";
            url = "http://localhost:3100";
          }
        ];
      };
      dashboards.settings = {
        apiVersion = 1;
        providers = [{
          name = "default";
          options.path = ./grafana-dashboards;
        }];
      };
    };
  };
}
