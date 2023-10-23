{ pkgs, lib, dns, system, machines, toplevelDomain, ... }:
with lib;
with dns.lib.combinators;
let
  util = dns.util.${pkgs.system};
  dnsConfiguration = with dns.lib.combinators; {
    SOA = {
      nameServer = "ns.${toplevelDomain}.";
      adminEmail = "admin@yolo.${toplevelDomain}";
      serial = 2019030800;
    };

    subdomains =
      builtins.listToAttrs (map
        ({ private_ipv4, name, ... }: {
          inherit name;
          value = {
            A = [ private_ipv4 ];
            subdomains."*".A = [ private_ipv4 ];
          };
        })
        machines
      );
  };

in

{

  networking.firewall.allowedTCPPorts = [ 52 ];
  networking.firewall.allowedUDPPorts = [ 52 ];

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
          file: ${util.writeZone toplevelDomain dnsConfiguration}
    '';

  };
}
