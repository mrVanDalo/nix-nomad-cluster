{ pkgs, lib, dns, system, machines, toplevelDomain, ... }:
with lib;
with dns.lib.combinators;
let
  util = dns.util.${pkgs.system};
  dnsConfigurationRaw = ''
    $TTL 60

    @ IN SOA cluster. ns1.cluster. (2023102500 86400 600 864000 60)
    @ IN NS ns1

    ns1 IN A 10.0.0.2

    cor-net-gateway IN A 10.0.0.2
    *.cor-net-gateway IN A 10.0.0.2
    dev-cache IN A 10.0.0.3
    *.dev-cache IN A 10.0.0.3
    dev-consul-0 IN A 10.0.0.9
    *.dev-consul-0 IN A 10.0.0.9
    dev-monitor IN A 10.0.0.4
    *.dev-monitor IN A 10.0.0.4
    dev-nomad-0 IN A 10.0.0.5
    *.dev-nomad-0 IN A 10.0.0.5
    dev-nomad-1 IN A 10.0.0.7
    *.dev-nomad-1 IN A 10.0.0.7
    dev-nomad-2 IN A 10.0.0.8
    *.dev-nomad-2 IN A 10.0.0.8
    dev-vault-0 IN A 10.0.0.6
    *.dev-vault-0 IN A 10.0.0.6

  '';
  dnsConfiguration = with dns.lib.combinators; {

    NS = [ "ns.${toplevelDomain}" ];

    SOA = {
      nameServer = "ns.${toplevelDomain}.";
      adminEmail = "admin@yolo.${toplevelDomain}";
      serial = 2023102500;
    };

    subdomains = { ns.A = [ "10.0.0.2" ]; } //
      (builtins.listToAttrs (map
        ({ private_ipv4, name, ... }: {
          inherit name;
          value = {
            A = [ private_ipv4 ];
            subdomains."*".A = [ private_ipv4 ];
          };
        })
        machines
      ));
  };

in

{

  #networking.firewall.allowedTCPPorts = [ 52 ];
  #networking.firewall.allowedUDPPorts = [ 52 ];

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
          file: ${pkgs.writeText "cluster.zone" dnsConfigurationRaw}
    '';

  };
}
