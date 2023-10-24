{ pkgs, lib, dns, system, machines, toplevelDomain, ... }:
with lib;
{

  imports = [
    # fixme: ugly hack for now this should be handled by knot
    {
      services.unbound.settings.server = {
        local-zone = [ ''"nomad" static'' ];
        local-data = [
          ''"traefik.nomad IN A 10.0.0.5"''
          ''"app.nomad IN A 10.0.0.5"''
        ];
      };
    }
  ];

  # not needed for sshuttle --dns at the moment
  #networking.firewall.allowedTCPPorts = [ 53 ];
  #networking.firewall.allowedUDPPorts = [ 53 ];

  services.unbound = {
    enable = true;
    settings = {
      server = {

        use-syslog = true;
        verbosity = 2;
        log-queries = true;

        access-control = [ "10.0.0.0/8 allow" ];
        interface = [ "0.0.0.0" ];

        #domain-insecure = ''"${toplevelDomain}."'';
        #domain-insecure = ''"${toplevelDomain}"'';
        #local-zone = ''"${toplevelDomain}." transparent'';
        #local-zone = ''"${toplevelDomain}" transparent'';

        # cluster zone
        # todo : wildcard does not work we need knot for that
        local-zone = [ ''"${toplevelDomain}" static'' ];
        local-data = map
          ({ name, private_ipv4, ... }: ''"${name}.${toplevelDomain} IN A ${private_ipv4}"'')
          machines;
      };

      # forward all unkown to google
      forward-zone = [
        {
          name = ''"."'';
          forward-addr = [
            "8.8.8.8"
            "1.1.1.1"
          ];
        }
        #{
        #  name = ''"${toplevelDomain}"'';
        #  forward-addr = "127.0.0.1@52";
        #  forward-first = true;
        #  forward-no-cache = true;
        #}
      ];

      #stub-zone = {
      #    name = toplevelDomain;
      #    stub-addr = "127.0.0.1@52";
      #    stub-first = true;
      #  };

    };
  };
}
