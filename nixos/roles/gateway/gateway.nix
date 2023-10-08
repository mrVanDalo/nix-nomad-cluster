{ lib, ... }:
{
  # gateway
  components.network.hetzner.enable = false;
  networking.nat = {
    enable = true;
    # todo : make dynamic
    internalIPs = [ "10.0.0.0/20" ];
  };

  services.telegraf.extraConfig.inputs.netstat = { };


  # make sure fireall is working
  networking.firewall.enable = lib.mkForce false;

}
