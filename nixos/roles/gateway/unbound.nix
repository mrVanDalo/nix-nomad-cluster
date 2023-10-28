{ pkgs, lib, dns, system, machine, machines, toplevelDomain, ... }:
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

        access-control = [ "${machine.cidr} allow" ];
        interface = [ "0.0.0.0" ];

        local-zone = ''"${toplevelDomain}." nodefault'';
        domain-insecure = ''"${toplevelDomain}."'';

      };

      stub-zone = {
        name = "${toplevelDomain}.";
        # todo : find out if this works
        #stub-addr = "${private_ipv4}@52";
        stub-addr = "127.0.0.1@52";
      };

    };
  };
}
