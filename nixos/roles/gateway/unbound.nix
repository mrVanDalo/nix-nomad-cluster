{ pkgs, lib, dns, system, machines, toplevelDomain, ... }:
with lib;
{

  # not needed for sshuttle --dns at the moment
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  services.unbound = {
    enable = true;
    settings = {
      server = {

        port = 53;

        use-syslog = true;
        verbosity = 3;
        log-queries = true;
        log-servfail = true;
        log-replies = true;

        # Mic92 recommends (copy-paste)
        prefetch = "yes";
        prefetch-key = true;
        qname-minimisation = true;
        # Too many broken dnssec setups even at big companies such as amazon.
        # Breaks my email setup. Better rely on tls for security.
        val-permissive-mode = "yes";

        # todo : make this part configurable from the machine
        access-control = [ "10.0.0.0/8 allow" ];
        interface = [ "0.0.0.0" ];

        local-zone = ''"${toplevelDomain}." nodefault'';
        domain-insecure = ''"${toplevelDomain}."'';

      };

      stub-zone = {
        name = "${toplevelDomain}.";
        stub-addr = "10.0.0.2@52";
      };

    };
  };
}
