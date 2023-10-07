{ machines, machine, lib, ... }:
let
  otherNomadMachines = builtins.filter ({ role, id, ... }: role == "nomad" && id != machine.id) machines;
in
{
  services.nomad = {
    enable = true;
    enableDocker = true;

    # makes nomad run as root user
    # dropPrivileges = false;

    settings = {
      server.enabled = true;
      bootstrap_expected = 2;
      server_join = {
        retry_join = lib.flatten (map ({ private_ipv4, ... }: private_ipv4) otherNomadMachines);
        retry_max = 3;
        retry_interval = "60s";
      };
    };

  };
}
