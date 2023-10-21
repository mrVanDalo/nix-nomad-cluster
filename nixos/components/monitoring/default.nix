{ config, pkgs, lib, ... }:
with lib;
with types;
{
  options.components.monitoring = {
    enable = mkOption {
      type = bool;
      default = true;
    };
  };

  imports = [
    ./telegraf.nix
    ./netdata.nix
    ./promtail.nix
  ];

  config = mkIf config.components.monitoring.enable { };
}
