{ pkgs, lib, system, machine, machines, toplevelDomain, ... }:
with lib;
{

  # putting the zone configuration in /etc/zones/ makes it easier to debug
  environment.etc."zones/${toplevelDomain}.zone".text = ''
    $TTL 60

    @ IN SOA ${toplevelDomain}. ns1.${toplevelDomain}. (2023102500 86400 600 864000 60)
    @ IN NS ns1

    ns1 IN A ${machine.private_ipv4}

    ${concatStringsSep "\n" (map ({private_ipv4, name, ...}: ''
    ${name} IN A ${private_ipv4}
    *.${name} IN A ${private_ipv4}
    '') machines)}
  '';

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
