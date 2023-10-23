{ lib, ... }:
{


  networking.nat = {
    enable = true;
    # todo : make dynamic
    internalIPs = [ "10.0.0.0/20" ];
  };

  services.telegraf.extraConfig.inputs.netstat = { };



}
