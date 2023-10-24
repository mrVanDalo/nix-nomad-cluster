{ config, pkgs, lib, machines, machine, ... }:
let
  nomadMachines = builtins.filter ({ role, id, ... }: role == "nomad") machines;
  consulMachines = builtins.filter ({ role, id, ... }: role == "consul") machines;
in
{


  networking.firewall.allowedTCPPorts = [ 9090 ];

  services.prometheus = {
    checkConfig = "syntax-only";
    enable = true;
    # keep data for 30 days
    extraFlags = [ "--storage.tsdb.retention.time=90d" ];

    ruleFiles = [
      (pkgs.writeText "prometheus-rules.yml" (builtins.toJSON {
        groups = [
          {
            name = "core";
            rules = [
              {
                alert = "InstanceDown";
                expr = "up == 0";
                for = "5m";
                labels.severity = "page";
                annotations = {
                  summary = "Instance {{ $labels.instance }} down";
                  description = "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes.";
                };
              }
            ];
          }
        ];
      }))
    ];

    scrapeConfigs = [
      {
        job_name = "netdata";
        metrics_path = "/api/v1/allmetrics";
        params.format = [ "prometheus" ];
        scrape_interval = "5s";
        static_configs = [
          {
            targets = map (ip: "${ip}:19999")
              (lib.flatten (map ({ private_ipv4, ... }: private_ipv4) machines));
            labels = {
              service = "netdata";
              environment = machine.environment;
            };
          }
        ];
      }
      {
        job_name = "telegraf";
        metrics_path = "/metrics";
        scrape_interval = "5s";
        static_configs = [
          {
            targets = map (ip: "${ip}:9273")
              (lib.flatten (map ({ private_ipv4, ... }: private_ipv4) machines));

            labels = {
              service = "telegraf";
            };
          }
        ];
      }
      #{
      #  job_name = "nomad";
      #  scrape_interval = "5s";
      #  nomad_sd_configs = [{
      #    server = lib.head (map ({ private_ipv4, ... }: private_ipv4) nomadMachines);
      #  }];
      #}

      {
        job_name = "consul";
        scrape_interval = "5s";
        consul_sd_configs = [{
          server = lib.head (map ({ private_ipv4, ... }: "${private_ipv4}:8500") consulMachines);
        }];
      }
    ];
  };
}
