{ lib, machine, ... }:
{
  networking.nat = {
    enable = true;
    internalIPs = [ machine.cidr ];
  };

  services.telegraf.extraConfig.inputs.netstat = { };



}
