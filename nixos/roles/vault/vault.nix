{ config, machine, machines, lib, pkgs, ... }:
let
  otherNomadMachines = builtins.filter ({ role, id, ... }: role == "nomad" && id != machine.id) machines;
  nomadMachines = builtins.filter ({ role, id, ... }: role == "nomad") machines;
  consulMachines = builtins.filter ({ role, id, ... }: role == "consul") machines;
in
{
  services.nginx = {
    enable = true;
    virtualHosts = {
      ${config.networking.hostName} = {
        serverAliases = [ "${config.networking.hostName}.*" ];
        default = true;
        locations."/" = {
          proxyPass = "http://localhost:8200";
        };
      };
    };
  };

  services.vault = {
    #package = pkgs.unstable.vault-bin;
    package = pkgs.vault-bin;
    enable = true;
    dev = true;
    devRootTokenID = "test-key";
    extraConfig = ''
      ui = true
    '';

  };
}
