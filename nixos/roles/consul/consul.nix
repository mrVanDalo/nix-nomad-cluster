{ config, machines, lib, pkgs, toplevelDomain, ... }:
let
  consulMachines = builtins.filter ({ role, id, ... }: role == "consul") machines;
in
{

  services.nginx = {
    enable = true;
    virtualHosts = {
      ${config.networking.hostName} = {
        default = true;
        locations."/" = {
          proxyPass = "http://localhost:8500";
        };
      };
    };
  };

  services.consul = {
    enable = true;
    #package = pkgs.unstable.consul;

    webUi = true;

    # makes nomad run as root user
    # dropPrivileges = false;

    extraConfig = {
      server = true;
      bind_addr = "0.0.0.0";
      client_addr = "0.0.0.0";

      bootstrap_expect = 1;

      retry_join = lib.flatten (map ({ name, ... }: "${name}.toplevelDomain") consulMachines);
      retry_max = 3;
      retry_interval = "10s";

      ui_config.enabled = true;
      ports.grpc = 8502;
      connect.enabled = true;

    };
  };

}
