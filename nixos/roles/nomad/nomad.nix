{ config, machines, machine, lib, pkgs, toplevelDomain, ... }:
let
  otherNomadMachines = builtins.filter ({ role, id, ... }: role == "nomad" && id != machine.id) machines;
  nomadMachines = builtins.filter ({ role, id, ... }: role == "nomad") machines;
  consulMachines = builtins.filter ({ role, id, ... }: role == "consul") machines;
  vaultMachines = builtins.filter ({ role, id, ... }: role == "vault") machines;
in
{

  networking.firewall.allowedTCPPorts = [ 4646 4647 4648 80 ];

  services.nginx = {
    enable = true;
    virtualHosts = {
      ${config.networking.hostName} = {
        default = true;
        locations."/" = {
          proxyPass = "http://localhost:4646";
        };
      };
      "*.apps.${toplevelDomain}" = {
        default = false;
        locations."/" = {
          proxyWebsockets = true;
          recommendedProxySettings = true;
          proxyPass = "http://localhost:8080";
        };
      };
    };
  };

  services.nomad = {
    enable = true;
    enableDocker = true;

    extraPackages = [
      pkgs.consul
    ];

    # clear `/var/lib/private/nomad` if upgrade fails
    package = pkgs.nomad;
    #package = pkgs.unstable.nomad;
    #package = pkgs.unstable.nomad_1_6;

    # makes nomad run as root user
    dropPrivileges = false;

    settings = {
      #log_level = "DEBUG";

      client = {
        enabled = true;
        cni_path = "${pkgs.cni-plugins}/bin";
      };

      server = {
        enabled = true;
        bootstrap_expect = 3;
        rejoin_after_leave = true;
      };

      # use consule to form cluster
      # even the servers find each other over consul
      consul = {
        # The address to the Consul agent.
        address = "127.0.0.1:8500";

        # The service name to register the server and client with Consul.
        server_service_name = "nomad";
        client_service_name = "nomad-client";

        # Enables automatically registering the services.
        auto_advertise = true;

        # Enabling the server and client to bootstrap using Consul.
        server_auto_join = true;
        client_auto_join = true;
      };

      ui = {
        enabled = true;
        consul.ui_url = "http://${(builtins.head consulMachines).private_ipv4}/ui";
        vault.ui_url = "http://${(builtins.head vaultMachines).private_ipv4}/ui";
      };
    };
  };

  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-ip6tables" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-arptables" = 1;
  };

  # local consul to talk to everyone
  services.consul = {
    enable = true;
    #package = pkgs.unstable.consul;

    extraConfig = {
      server = false;
      retry_join = lib.flatten (map ({ private_ipv4, ... }: private_ipv4) consulMachines);
      retry_max = 3;
      retry_interval = "10s";
      ports.grpc = 8502;
      connect.enabled = true;
      client_addr = "127.0.0.1"; # to make sure only localhost nomad can see this consul
      bind_addr = machine.private_ipv4;
    };
  };
}
