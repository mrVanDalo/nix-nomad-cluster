{ machine, config, ... }:
{

  networking.firewall.allowedTCPPorts = [
    config.services.grafana.settings.server.http_port
  ];

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
    provision.enable = true;
    provision.datasources.settings = {
      apiVersion = 1;
      datasources = [{
        name = "Prometheus";
        type = "prometheus";
        uid = "P1";
        url = "http://localhost:9090";
      }];
    };
    #provision.dashboards.path = ./grafana-dashboards;
    provision.dashboards.settings = {
      apiVersion = 1;
      providers = [{
        name = "default";
        #options.path = "/var/lib/grafana/dashboards";
        options.path = ./grafana-dashboards;
      }];
    };
  };
}
