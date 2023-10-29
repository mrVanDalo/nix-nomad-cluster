{ config, pkgs, lib, machines, toplevelDomain, ... }:
with lib;
with types;
let
  lokiServers = filter ({ role, ... }: role == "monitor") machines;
in
{
  options.components.monitoring.promtail = {
    enable = mkOption {
      type = bool;
      default = config.components.monitoring.enable;
    };
  };

  config = mkIf config.components.monitoring.promtail.enable {

    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 28183;
          grpc_listen_port = 0;
        };
        positions.filename = "/tmp/positions.yaml";
        clients = map
          ({ name, ... }:
            { url = "http://${name}.${toplevelDomain}:3100/loki/api/v1/push"; }
          )
          lokiServers;

        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = config.networking.hostName;
              };
            };
            relabel_configs = [
              {
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }
              {
                source_labels = [ "__journal__transport" ];
                target_label = "transport";
              }
            ];
          }
        ];
      };

    };

  };
}
