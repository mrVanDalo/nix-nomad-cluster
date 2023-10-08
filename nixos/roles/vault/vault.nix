{ machine, machines, lib, ... }:
let
  otherNomadMachines = builtins.filter ({ role, id, ... }: role == "nomad" && id != machine.id) machines;
  nomadMachines = builtins.filter ({ role, id, ... }: role == "nomad") machines;
  consulMachines = builtins.filter ({ role, id, ... }: role == "consul") machines;
in
{
  services.nginx = {
    enable = true;
    virtualHosts = {
      ${machine.name} = {
        locations."/" = {
          proxyPass = "http://localhost:8200";
        };
      };
    };
  };

  services.vault = {
    enable = true;
    dev = true;

    extraConfig = {
      ui = true;
    };

  };
}
