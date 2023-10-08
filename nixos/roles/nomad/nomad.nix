{ machines, machine, lib, ... }:
let
  otherNomadMachines = builtins.filter ({ role, id, ... }: role == "nomad" && id != machine.id) machines;
  nomadMachines = builtins.filter ({ role, id, ... }: role == "nomad") machines;
in
{

  networking.firewall.allowedTCPPorts = [ 4646 4647 4648 ];

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
      ui = {
        enabled = true;
        #consul.ui_url = "write me";
        #vault.ui_url = "write me";
      };
    };

  };
}
