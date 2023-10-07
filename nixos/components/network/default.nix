{ config, pkgs, lib, ... }:
with lib;
with types;
{
  options.components.network = {
    enable = mkOption {
      type = bool;
      default = true;
    };
  };

  imports = [
    ./hetzner.nix
    ./ssh.nix
  ];

  config = mkIf config.components.network.enable { };
}
