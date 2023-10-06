{ config, pkgs, lib, ... }:
with lib;
with types;
{
  options.components.network.routing = {
    enable = mkOption {
      type = bool;
      default = config.components.network.enable;
    };
  };

  config = mkIf config.components.network.routing.enable {

    networking.nameservers = [
      "8.8.8.8"
      "1.1.1.1"
    ];

    networking.defaultGateway = "10.0.0.1";

  };
}
