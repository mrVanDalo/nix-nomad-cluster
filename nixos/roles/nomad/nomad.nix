{ machines, machine, lib, ... }:
let
  otherNomadMachines = builtins.filter ({ role, id, ... }: role == "nomad" && id != machine.id) machines;
  nomadMachines = builtins.filter ({ role, id, ... }: role == "nomad") machines;
  consulMachines = builtins.filter ({ role, id, ... }: role == "consul") machines;
  vaultMachines = builtins.filter ({ role, id, ... }: role == "vault") machines;
in
{

  networking.firewall.allowedTCPPorts = [ 4646 4647 4648 80 ];

  services.nginx = {
    enable = true;
    virtualHosts = {
      ${machine.name} = {
        locations."/" = {
          proxyPass = "http://localhost:4646";
        };
      };
    };
  };

  services.nomad = {
    enable = true;
    enableDocker = true;

    # makes nomad run as root user
    # dropPrivileges = false;

    settings = {
      client = {
        enabled = true;
        server_join = {
          start_join = lib.flatten (map ({ private_ipv4, ... }: private_ipv4) nomadMachines);
          retry_max = 3;
          retry_interval = "10s";
        };
      };
      server = {
        enabled = true;
        bootstrap_expect = 3;
        server_join = {
          start_join = lib.flatten (map ({ private_ipv4, ... }: private_ipv4) nomadMachines);
          retry_max = 3;
          retry_interval = "10s";
        };
      };
      consul.address = "127.0.0.1:8500";
      ui = {
        enabled = true;
        consul.ui_url = "http://${(builtins.head consulMachines).private_ipv4}/ui";
        vault.ui_url = "http://${(builtins.head vaultMachines).private_ipv4}/ui";
      };
    };
  };

  # local consul to talk to everyone
  services.consul = {
    enable = true;

    extraConfig = {
      server = false;
      retry_join = lib.flatten (map ({ private_ipv4, ... }: private_ipv4) consulMachines);
      retry_max = 3;
      retry_interval = "10s";
      ports.grpc = 8502;
      connect.enabled = true;
    };
  };
}
