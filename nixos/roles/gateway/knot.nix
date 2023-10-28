{ pkgs, lib, system, machine, machines, toplevelDomain, ... }:
with lib;
let
  nomadMachines = builtins.filter ({ role, id, ... }: role == "nomad") machines;
  nomadMachine = head nomadMachines;

  zoneConfiguration = pkgs.writeText "${toplevelDomain}.zone" ''
    $TTL 60

    @ IN SOA ${toplevelDomain}. ns1.${toplevelDomain}. (2023102500 86400 600 864000 60)
    @ IN NS ns1

    ;; ns1 IN A ${machine.private_ipv4}
    ns1 IN A 127.0.0.1

    ;; cluster machines
    ${concatStringsSep "\n" (map ({private_ipv4, name, ...}: ''
    ${name} IN A ${private_ipv4}
    *.${name} IN A ${private_ipv4}
    '') machines)}

    ;; nomad apps
    ${concatStringsSep "\n" (map ({private_ipv4, ...}: "*.apps IN A ${private_ipv4}") nomadMachines)}
  '';
in
{


  environment.etc."zones/${toplevelDomain}.zone".source = zoneConfiguration;

  # putting the zone configuration in /etc/zones/ makes it easier to debug

  systemd.services.knot.restartTriggers = [ zoneConfiguration ];

  services.knot = {
    enable = true;

    extraConfig = ''
      server:
        listen: [ "0.0.0.0@52", "::@52" ]

      log:
        - target: syslog
          any: info

      zone:
        - domain: ${toplevelDomain}
          file: /etc/zones/${toplevelDomain}.zone
    '';

  };
}
