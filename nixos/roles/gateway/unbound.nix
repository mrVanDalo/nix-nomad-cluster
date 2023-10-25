{ pkgs, lib, dns, system, machines, toplevelDomain, ... }:
with lib;
{

  imports = [
    # fixme: ugly hack for now this should be handled by knot
    #{
    #  services.unbound.settings.server = {
    #    local-zone = [ ''"nomad" static'' ];
    #    local-data = [
    #      ''"traefik.nomad IN A 10.0.0.5"''
    #      ''"app.nomad IN A 10.0.0.5"''
    #    ];
    #  };
    #}
  ];

  # not needed for sshuttle --dns at the moment
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  services.unbound = {
    enable = true;
    settings = {
      server = {

        port = 53;

        use-syslog = true;
        verbosity = 2;
        #log-queries = true;
        #log-servfail = true;
        #log-replies = true;

        # Mic92 empfehlung (copy-paste)
        prefetch = "yes";
        prefetch-key = true;
        qname-minimisation = true;
        # Too many broken dnssec setups even at big companies such as amazon.
        # Breaks my email setup. Better rely on tls for security.
        val-permissive-mode = "yes";

        access-control = [ "10.0.0.0/8 allow" ];
        interface = [ "0.0.0.0" ];

        #domain-insecure = ''"${toplevelDomain}."'';
        #domain-insecure = ''"${toplevelDomain}"'';
        #local-zone = ''"${toplevelDomain}." transparent'';
        #local-zone = ''"${toplevelDomain}" transparent'';

        local-zone = ''"${toplevelDomain}." nodefault'';
        domain-insecure = ''"${toplevelDomain}."'';

        # cluster zone
        # todo : wildcard does not work we need knot for that
        #local-zone = [ ''"${toplevelDomain}" static'' ];
        #local-data = map
        #  ({ name, private_ipv4, ... }: ''"${name}.${toplevelDomain} IN A ${private_ipv4}"'')
        #  machines;

      };

      # forward all unkown to google
      #forward-zone = [{
      #  name = ''"${toplevelDomain}."'';
      #  #forward-addr = "127.0.0.1@53";
      #  forward-addr = "10.0.0.2@53";
      #  forward-first = true;
      #  forward-no-cache = true;
      #}];

      stub-zone = {
        name = "${toplevelDomain}.";
        #stub-addr = "127.0.0.1";
        stub-addr = "10.0.0.2@52";
      };

    };
  };
}
