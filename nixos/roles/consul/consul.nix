{ machines, machine, lib, ... }:
let
  consulMachines = builtins.filter ({ role, id, ... }: role == "consul") machines;
in
{

  services.nginx = {
    enable = true;
    virtualHosts = {
      ${machine.name} = {
        locations."/" = {
          proxyPass = "http://localhost:8500";
        };
      };
    };
  };

  services.consul = {
    enable = true;

    webUi = true;

    # makes nomad run as root user
    # dropPrivileges = false;

    extraConfig = {
      server = true;
      bind_addr = "0.0.0.0";

      bootstrap_expect = 1;

      retry_join = lib.flatten (map ({ private_ipv4, ... }: private_ipv4) consulMachines);
      retry_max = 3;
      retry_interval = "10s";

      ui_config.enabled = true;
      client_addr = "0.0.0.0";
      ports.grpc = 8502;
      connect.enabled = true;

    };
  };

}
